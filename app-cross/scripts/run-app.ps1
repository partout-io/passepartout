[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('arm64', 'x64')][string]$Architecture,
    [Parameter(Mandatory)][ValidateSet('Debug', 'Release')][string]$Configuration,
    [switch]$Demo,
    [switch]$WaitForDebugger,
    [switch]$PrepareOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ($env:OS -ne 'Windows_NT') { throw 'Use run-app.sh on macOS.' }
$source = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$build = Join-Path $source "out/build/windows-$Architecture"
$install = Join-Path $source "out/install/windows-$Architecture"
$buildManifest = Join-Path $build 'AppxManifest.xml'
$installedManifest = Join-Path $install 'AppxManifest.xml'
$registrationReceipt = Join-Path $build 'development-registration.json'

function TestRegistrationReceipt {
    param([string]$ReceiptPath, [string]$ManifestHash, [string]$InstallDirectory)
    try {
        $receipt = Get-Content -LiteralPath $ReceiptPath -Raw -ErrorAction Stop | ConvertFrom-Json
        return $receipt.ManifestHash -eq $ManifestHash -and $receipt.InstallDirectory -eq $InstallDirectory
    } catch {
        return $false
    }
}

function GetNextDevelopmentVersion {
    param([version]$Current, [version[]]$RegisteredVersions)
    $latest = $Current
    foreach ($version in $RegisteredVersions) {
        if ($version -gt $latest) { $latest = $version }
    }
    if ($latest.Major -ne 0 -or $latest.Revision -ge 65535) {
        throw 'Choose a newer 0.* development package version in the CMake cache.'
    }
    return "0.$($latest.Minor).$($latest.Build).$($latest.Revision + 1)"
}

function AssertFrontendClosed {
    if (Get-Process -Name $processName -ErrorAction SilentlyContinue) {
        throw 'Quit the frontend before installing.'
    }
}
function InvokeCMake {
    param([string[]]$Arguments)
    & cmake @Arguments
    if ($LASTEXITCODE -ne 0) { throw "CMake failed with exit code $LASTEXITCODE." }
}
function TestAppContainerManifest {
    param([xml]$Manifest, [string]$ApplicationId)
    $namespace = 'http://schemas.microsoft.com/appx/manifest/uap/windows10/10'
    $frontend = $Manifest.Package.Applications.Application | Where-Object { $_.Id -eq $ApplicationId }
    return $frontend -and $frontend.GetAttribute('TrustLevel', $namespace) -eq 'appContainer' -and
        $frontend.GetAttribute('RuntimeBehavior', $namespace) -eq 'packagedClassicApp' -and
        -not $Manifest.SelectSingleNode("//*[local-name()='Capability' and @Name='runFullTrust']") -and
        -not $Manifest.SelectSingleNode("//*[local-name()='AllowExternalContent']")
}
function TestAppContainerPackage {
    param([string]$PackageFullName)
    return TestAppContainerManifest (Get-AppxPackageManifest -Package $PackageFullName -ErrorAction Stop) $applicationId
}

function InitializeActivation {
    # Direct EXE launch does not supply an AppContainer token.
    if ('Passepartout.Development.Activation' -as [type]) { return }
    Add-Type -TypeDefinition @'
using System;
using System.ComponentModel;
using System.Runtime.InteropServices;
using Microsoft.Win32.SafeHandles;

namespace Passepartout.Development {
    [ComImport, Guid("2e941141-7f97-4756-ba1d-9decde894a3d"),
     InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    interface IApplicationActivationManager {
        void ActivateApplication([MarshalAs(UnmanagedType.LPWStr)] string appId,
            [MarshalAs(UnmanagedType.LPWStr)] string arguments, uint options, out uint processId);
        void ActivateForFile(IntPtr appId, IntPtr items, IntPtr verb, out uint processId);
        void ActivateForProtocol(IntPtr appId, IntPtr items, out uint processId);
    }

    public static class Activation {
        [DllImport("kernel32.dll", SetLastError = true)]
        static extern SafeFileHandle OpenProcess(uint access, bool inherit, uint processId);
        [DllImport("advapi32.dll", SetLastError = true)]
        static extern bool OpenProcessToken(SafeFileHandle process, uint access, out SafeFileHandle token);
        [DllImport("advapi32.dll", SetLastError = true)]
        static extern bool GetTokenInformation(SafeFileHandle token, int informationClass,
            out uint information, uint length, out uint returnedLength);

        public static uint Launch(string appId, string arguments) {
            var manager = (IApplicationActivationManager)Activator.CreateInstance(
                Type.GetTypeFromCLSID(new Guid("45ba127d-10a8-46ea-8ab7-56ea9078943c")));
            try {
                uint processId;
                manager.ActivateApplication(appId, arguments, 0, out processId);
                return processId;
            } finally {
                Marshal.FinalReleaseComObject(manager);
            }
        }

        public static bool IsAppContainer(uint processId) {
            using (var process = OpenProcess(0x1000, false, processId)) {
                if (process.IsInvalid) throw new Win32Exception();
                SafeFileHandle token;
                if (!OpenProcessToken(process, 0x0008, out token)) throw new Win32Exception();
                using (token) {
                    uint value, length;
                    // TOKEN_INFORMATION_CLASS::TokenIsAppContainer = 29.
                    if (!GetTokenInformation(token, 29, out value, 4, out length))
                        throw new Win32Exception();
                    return value != 0;
                }
            }
        }
    }
}
'@
}

$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio/Installer/vswhere.exe'
$visualStudio = & $vswhere -latest -products '*' -requires 'Microsoft.VisualStudio.Component.VC.Tools.x86.x64' -property installationPath
if (-not $visualStudio) { throw 'Visual Studio C++ build tools were not found.' }
Import-Module (Join-Path $visualStudio 'Common7/Tools/Microsoft.VisualStudio.DevShell.dll')
$hostArchitecture = if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64') { 'arm64' } else { 'x64' }
Enter-VsDevShell -VsInstallPath $visualStudio -SkipAutomaticLocation -DevCmdArguments "-arch=$Architecture -host_arch=$hostArchitecture"
Push-Location $source
try {
    $debuggerWait = if ($WaitForDebugger -and $Configuration -eq 'Debug') { 'ON' } else { 'OFF' }
    InvokeCMake -Arguments @('--preset', "windows-$Architecture", "-DCMAKE_INSTALL_PREFIX=$install",
        "-DPASSEPARTOUT_WAIT_FOR_DEBUGGER=$debuggerWait")
    [xml]$manifest = Get-Content -LiteralPath $buildManifest -Raw
    $identity = $manifest.Package.Identity
    $frontend = $manifest.Package.Applications.Application | Where-Object { $_.GetAttribute('RuntimeBehavior', 'http://schemas.microsoft.com/appx/manifest/uap/windows10/10') -eq 'packagedClassicApp' }
    $applicationId = $frontend.Id
    if (-not (TestAppContainerManifest $manifest $applicationId)) {
        throw 'The frontend manifest must declare packagedClassicApp/AppContainer without full trust or external content.'
    }
    $processName = [IO.Path]::GetFileNameWithoutExtension($frontend.Executable)
    AssertFrontendClosed
    if (-not $identity.Version.StartsWith('0.')) { throw 'Development packages must use a 0.* version.' }
    $registered = @(Get-AppxPackage -Name $identity.Name | Where-Object { $_.Publisher -eq $identity.Publisher })
    if (@($registered | Where-Object { -not $_.IsDevelopmentMode }).Count) {
        throw 'Refusing to replace a production package with a development registration.'
    }
    # The receipt proves Windows registered this manifest, even if installation
    # has since overwritten the on-disk copy. Reuse only the exact healthy layout.
    $manifestHash = (Get-FileHash -LiteralPath $buildManifest -Algorithm SHA256).Hash
    $reuse = $registered.Count -eq 1 -and
        (TestRegistrationReceipt $registrationReceipt $manifestHash $install) -and
        $registered[0].Version.ToString() -eq $identity.Version -and
        $registered[0].Architecture.ToString() -eq $Architecture -and
        $registered[0].InstallLocation -eq $install -and $registered[0].Status -eq 'Ok' -and
        (Test-Path -LiteralPath $installedManifest) -and
        (TestAppContainerPackage $registered[0].PackageFullName)
    if ($registered.Count -and -not $reuse) {
        $version = GetNextDevelopmentVersion ([version]$identity.Version) @($registered.Version)
        InvokeCMake -Arguments @('--preset', "windows-$Architecture", "-DPASSEPARTOUT_PACKAGE_VERSION=$version")
        [xml]$manifest = Get-Content -LiteralPath $buildManifest -Raw
        $identity = $manifest.Package.Identity
        $manifestHash = (Get-FileHash -LiteralPath $buildManifest -Algorithm SHA256).Hash
    }
    # Release loaded DLLs before rebuilding, not only before installation.
    # Include a host launched directly from this configuration's build output.
    $stopPlugin = Join-Path $source 'tunnel/windows/stop-plugin.ps1'
    & $stopPlugin -InstallDirectory $install
    & $stopPlugin -InstallDirectory (Join-Path $build $Configuration)
    InvokeCMake -Arguments @('--build', '--preset', "windows-$Architecture-$($Configuration.ToLowerInvariant())")
    AssertFrontendClosed
    # The shared install hook stops only the host in this install directory
    # before replacing its dependencies, including for F5 preparation.
    InvokeCMake -Arguments @('--install', $build, '--config', $Configuration, '--prefix', $install)
    if (-not $reuse) {
        AssertFrontendClosed
        Add-AppxPackage -Register $installedManifest -ForceUpdateFromAnyVersion
    }
    $package = Get-AppxPackage -Name $identity.Name | Where-Object { $_.Publisher -eq $identity.Publisher }
    if (-not $package -or -not (TestAppContainerPackage -PackageFullName $package.PackageFullName)) {
        throw 'The registered package does not have the expected AppContainer manifest.'
    }
    $receipt = @{ ManifestHash = $manifestHash; InstallDirectory = $install } | ConvertTo-Json
    [IO.File]::WriteAllText($registrationReceipt, $receipt.Replace("`r`n", "`n") + "`n",
        [Text.UTF8Encoding]::new($false))
    if ($PrepareOnly) { return }
    InitializeActivation
    $arguments = if ($Demo) { '--demo' } else { '' }
    $processId = [Passepartout.Development.Activation]::Launch(
        "$($package.PackageFamilyName)!$applicationId", $arguments)
    if (-not [Passepartout.Development.Activation]::IsAppContainer($processId)) {
        throw "Frontend $processId is not running in AppContainer."
    }
    [pscustomobject]@{ ProcessId = $processId; AppContainer = $true; Demo = [bool]$Demo }
} finally {
    Pop-Location
}
