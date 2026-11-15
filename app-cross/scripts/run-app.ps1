[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('arm64', 'x64')][string]$Architecture,
    [Parameter(Mandatory)][ValidateSet('Debug', 'Release')][string]$Configuration,
    [switch]$Demo,
    [switch]$WaitForDebugger,
    [switch]$PrepareOnly
)

# Constants
$manifestName = 'AppxManifest.xml'
$manifestNamespace = 'http://schemas.microsoft.com/appx/manifest/uap/windows10/10'
$developmentVersionPrefix = '0.'
$vswhereRelativePath = 'Microsoft Visual Studio/Installer/vswhere.exe'
$visualStudioComponent = 'Microsoft.VisualStudio.Component.VC.Tools.x86.x64'
$developerShellRelativePath = 'Common7/Tools/Microsoft.VisualStudio.DevShell.dll'
$stopPluginRelativePath = 'tunnel/windows/stop-plugin.ps1'

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ($env:OS -ne 'Windows_NT') { throw 'Use run-app.sh on macOS.' }
$source = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$build = Join-Path $source "out/build/windows-$Architecture"
$install = Join-Path $source "out/install/windows-$Architecture"
$registrationReceipt = Join-Path $build 'development-registration.json'

function TestRegistrationReceipt {
    param([string]$ReceiptPath, [string]$ManifestHash, [string]$InstallDirectory)
    if (-not (Test-Path -LiteralPath $ReceiptPath)) { return $false }
    try {
        $receipt = Get-Content -LiteralPath $ReceiptPath -Raw | ConvertFrom-Json
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

$vswhere = Join-Path ${env:ProgramFiles(x86)} $vswhereRelativePath
$visualStudio = & $vswhere -latest -products '*' -requires $visualStudioComponent -property installationPath
if (-not $visualStudio) { throw 'Visual Studio C++ build tools were not found.' }
Import-Module (Join-Path $visualStudio $developerShellRelativePath)
$hostArchitecture = if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64') { 'arm64' } else { 'x64' }
Enter-VsDevShell -VsInstallPath $visualStudio -SkipAutomaticLocation -DevCmdArguments "-arch=$Architecture -host_arch=$hostArchitecture"
Push-Location $source
try {
    $debuggerWait = if ($WaitForDebugger -and $Configuration -eq 'Debug') { 'ON' } else { 'OFF' }
    InvokeCMake -Arguments @('--preset', "windows-$Architecture", "-DCMAKE_INSTALL_PREFIX=$install",
        "-DPASSEPARTOUT_WAIT_FOR_DEBUGGER=$debuggerWait")
    [xml]$manifest = Get-Content -LiteralPath (Join-Path $build $manifestName) -Raw
    $identity = $manifest.Package.Identity
    $frontend = $manifest.Package.Applications.Application | Where-Object { $_.GetAttribute('RuntimeBehavior', $manifestNamespace) -eq 'packagedClassicApp' }
    $applicationId = $frontend.Id
    if (-not (TestAppContainerManifest $manifest $applicationId)) {
        throw 'The frontend manifest must declare packagedClassicApp/AppContainer without full trust or external content.'
    }
    $executableName = $frontend.Executable
    $processName = [IO.Path]::GetFileNameWithoutExtension($executableName)
    AssertFrontendClosed
    if (-not $identity.Version.StartsWith($developmentVersionPrefix)) { throw 'Development packages must use a 0.* version.' }
    $registered = @(Get-AppxPackage -Name $identity.Name | Where-Object { $_.Publisher -eq $identity.Publisher })
    if (@($registered | Where-Object { -not $_.IsDevelopmentMode }).Count) {
        throw 'Refusing to replace a production package with a development registration.'
    }
    # Get-AppxPackageManifest reads the replaced file, not proof that Windows
    # refreshed its activation catalog. A renamed plugin needs a new registration.
    $manifestHash = (Get-FileHash -LiteralPath (Join-Path $build $manifestName) -Algorithm SHA256).Hash
    $registrationCurrent = TestRegistrationReceipt -ReceiptPath $registrationReceipt `
        -ManifestHash $manifestHash -InstallDirectory $install
    if ($registered.Count -and -not $registrationCurrent) {
        $version = GetNextDevelopmentVersion -Current ([version]$identity.Version) `
            -RegisteredVersions @($registered | ForEach-Object { [version]$_.Version })
        InvokeCMake -Arguments @('--preset', "windows-$Architecture", "-DPASSEPARTOUT_PACKAGE_VERSION=$version")
        [xml]$manifest = Get-Content -LiteralPath (Join-Path $build $manifestName) -Raw
        $identity = $manifest.Package.Identity
        $manifestHash = (Get-FileHash -LiteralPath (Join-Path $build $manifestName) -Algorithm SHA256).Hash
    }
    # Changed manifests above get a new version. Do not overwrite an unrelated
    # same-version layout when a receipt survived an out-of-band registration.
    foreach ($package in $registered | Where-Object { $_.Version.ToString() -eq $identity.Version }) {
        if ($package.Architecture.ToString() -ne $Architecture -or $package.InstallLocation -ne $install -or
            ((Test-Path -LiteralPath (Join-Path $package.InstallLocation $manifestName)) -and
                -not (TestAppContainerPackage -PackageFullName $package.PackageFullName))) {
            throw 'The existing package uses this version with a different layout. Choose a newer 0.* development package version in the CMake cache.'
        }
    }
    # Release loaded DLLs before rebuilding, not only before installation.
    # Include a host launched directly from this configuration's build output.
    $stopPlugin = Join-Path $source $stopPluginRelativePath
    & $stopPlugin -InstallDirectory $install
    & $stopPlugin -InstallDirectory (Join-Path $build $Configuration)
    InvokeCMake -Arguments @('--build', '--preset', "windows-$Architecture-$($Configuration.ToLowerInvariant())")
    AssertFrontendClosed
    # The shared install hook stops only the host in this install directory
    # before replacing its dependencies, including for F5 preparation.
    InvokeCMake -Arguments @('--install', $build, '--config', $Configuration, '--prefix', $install)
    # Installation restores a missing development manifest before we inspect it.
    $matches = @($registered | Where-Object {
        $registrationCurrent -and $_.Version.ToString() -eq $identity.Version -and
        $_.Architecture.ToString() -eq $Architecture -and $_.InstallLocation -eq $install -and
        $_.Status -eq 'Ok' -and (TestAppContainerPackage -PackageFullName $_.PackageFullName)
    })
    if ($matches.Count -ne 1) {
        AssertFrontendClosed
        & $stopPlugin -InstallDirectory $install
        if (@($registered | Where-Object { $_.Version.ToString() -eq $identity.Version }).Count) {
            throw 'The existing development registration is not healthy. Inspect its package status before retrying.'
        }
        Add-AppxPackage -Register (Join-Path $install $manifestName) -ForceUpdateFromAnyVersion
    }
    $package = Get-AppxPackage -Name $identity.Name | Where-Object { $_.Publisher -eq $identity.Publisher }
    if (-not $package -or -not (TestAppContainerPackage -PackageFullName $package.PackageFullName)) {
        throw 'The registered package does not have the expected AppContainer manifest.'
    }
    $receipt = @{ ManifestHash = $manifestHash; InstallDirectory = $install } | ConvertTo-Json
    [IO.File]::WriteAllText($registrationReceipt, $receipt.Replace("`r`n", "`n") + "`n",
        [Text.UTF8Encoding]::new($false))
    if ($PrepareOnly) { return }
    . (Join-Path $PSScriptRoot 'windows-activation.ps1')
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
