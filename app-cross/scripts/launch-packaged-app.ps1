# SPDX-FileCopyrightText: 2026 Davide De Rosa
#
# SPDX-License-Identifier: GPL-3.0

# Activate an already registered frontend. Never build, install, register, or
# stop a host here: those operations must be explicit development steps.
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$InstallDirectory,
    [switch]$Demo
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$directory = (Resolve-Path -LiteralPath $InstallDirectory).Path
[xml]$manifest = Get-Content -LiteralPath (Join-Path $directory 'AppxManifest.xml')
$identity = $manifest.Package.Identity
$packages = @(Get-AppxPackage -Name $identity.Name | Where-Object {
    $_.Publisher -eq $identity.Publisher -and $_.InstallLocation -eq $directory
})
if ($packages.Count -ne 1) { throw 'Register this development package before launching it.' }
$applications = @($manifest.Package.Applications.Application | Where-Object {
    $_.GetAttribute('EntryPoint') -eq 'Windows.FullTrustApplication'
})
if ($applications.Count -ne 1) { throw 'Expected exactly one full-trust frontend in the manifest.' }
$appId = $packages[0].PackageFamilyName + '!' + $applications[0].Id

if (-not ('Passepartout.Development.PackageLauncher' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
namespace Passepartout.Development {
    [ComImport, Guid("2E941141-7F97-4756-BA1D-9DECDE894A3D"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    interface IApplicationActivationManager {
        [PreserveSig]
        int ActivateApplication([MarshalAs(UnmanagedType.LPWStr)] string appId,
            [MarshalAs(UnmanagedType.LPWStr)] string arguments, uint options, out uint processId);
    }
    public static class PackageLauncher {
        public static uint Activate(string appId, string arguments) {
            var type = Type.GetTypeFromCLSID(new Guid("45BA127D-10A8-46EA-8AB7-56EA9078943C"));
            var manager = (IApplicationActivationManager)Activator.CreateInstance(type);
            try {
                uint processId;
                Marshal.ThrowExceptionForHR(manager.ActivateApplication(appId, arguments, 2, out processId));
                return processId;
            } finally {
                Marshal.ReleaseComObject(manager);
            }
        }
    }
}
'@
}
$arguments = if ($Demo) { '--demo' } else { '' }
$launchedProcessId = [Passepartout.Development.PackageLauncher]::Activate($appId, $arguments)
[pscustomobject]@{ ProcessId = $launchedProcessId; AppUserModelId = $appId; Demo = [bool]$Demo }
