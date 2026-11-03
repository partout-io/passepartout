# SPDX-FileCopyrightText: 2026 Davide De Rosa
#
# SPDX-License-Identifier: GPL-3.0

[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('arm64', 'x64')][string]$Architecture,
    [Parameter(Mandatory)][ValidateSet('Debug', 'Release')][string]$Configuration,
    [switch]$Demo
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ($env:OS -ne 'Windows_NT') { throw 'Use run-app.sh on macOS.' }
$source = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$build = Join-Path $source "out/build/windows-$Architecture"
$install = Join-Path $source "out/install/windows-$Architecture"

function StartPackagedApp {
    param([string]$InstallDirectory, [switch]$Demo)
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
}

function AssertProcessesClosed {
    if (Get-Process -Name passepartout,passepartout-tunnel -ErrorAction SilentlyContinue) {
        throw 'Quit the frontend before installing. The VPN host must also be idle and closed; this workflow never stops it.'
    }
}
function InvokeCMake {
    param([string[]]$Arguments)
    & cmake @Arguments
    if ($LASTEXITCODE -ne 0) { throw "CMake failed with exit code $LASTEXITCODE." }
}

AssertProcessesClosed
$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio/Installer/vswhere.exe'
$visualStudio = & $vswhere -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
if (-not $visualStudio) { throw 'Visual Studio C++ build tools were not found.' }
Import-Module (Join-Path $visualStudio 'Common7/Tools/Microsoft.VisualStudio.DevShell.dll')
$hostArchitecture = if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64') { 'arm64' } else { 'x64' }
Enter-VsDevShell -VsInstallPath $visualStudio -SkipAutomaticLocation -DevCmdArguments "-arch=$Architecture -host_arch=$hostArchitecture"
Push-Location $source
try {
    InvokeCMake -Arguments @('--preset', "windows-$Architecture", "-DCMAKE_INSTALL_PREFIX=$install")
    InvokeCMake -Arguments @('--build', '--preset', "windows-$Architecture-$($Configuration.ToLowerInvariant())")
    AssertProcessesClosed
    [xml]$manifest = Get-Content -LiteralPath (Join-Path $build 'tunnel/AppxManifest.xml') -Raw
    $identity = $manifest.Package.Identity
    if (-not $identity.Version.StartsWith('0.')) { throw 'Development packages must use a 0.* version.' }
    $registered = @(Get-AppxPackage -Name $identity.Name | Where-Object { $_.Publisher -eq $identity.Publisher })
    if (@($registered | Where-Object { -not $_.IsDevelopmentMode }).Count) {
        throw 'Refusing to replace a production package with a development registration.'
    }
    # The install-time guard also checks for a host appearing after preflight.
    InvokeCMake -Arguments @("-DCMAKE_INSTALL_PREFIX=$install", "-DCMAKE_INSTALL_CONFIG_NAME=$Configuration",
        '-DPASSEPARTOUT_INSTALL_NO_STOP_HOST=ON', '-P', (Join-Path $build 'cmake_install.cmake'))
    $matches = @($registered | Where-Object {
        $_.Version.ToString() -eq $identity.Version -and
        $_.Architecture.ToString() -eq $Architecture -and $_.InstallLocation -eq $install -and $_.Status -eq 'Ok'
    })
    if ($matches.Count -ne 1) {
        AssertProcessesClosed
        Add-AppxPackage -Register (Join-Path $install 'AppxManifest.xml') -ForceUpdateFromAnyVersion
    }
    $result = StartPackagedApp -InstallDirectory $install -Demo:$Demo
    $process = Get-Process -Id $result.ProcessId -ErrorAction Stop
    if ($process.HasExited) { throw 'The activated frontend exited.' }
    $result
} finally {
    Pop-Location
}
