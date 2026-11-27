<#
.SYNOPSIS
Build an unsigned Microsoft Store MSIX without installing or uploading it.
.EXAMPLE
./ci/package.ps1 msix ./dist x64
.EXAMPLE
./ci/package.ps1 msix ./dist x64 -Version 3.12.9.0
.NOTES
Requires Visual Studio C++ tools for the target architecture, Windows SDK,
CMake 4 or newer, Ninja, Zig, and Go. The Store signs the submitted package.
Defaults to the shared Apple release version with a zero Store revision.
Override with a four-part version with a nonzero major and a zero revision.
Reuses the build cache by default. Use -Fresh to reset CMake configuration.
-Jobs overrides build parallelism; otherwise CMAKE_BUILD_PARALLEL_LEVEL or the
build tool default applies.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory, Position = 0)][ValidateSet('msix')][string]$Target,
    [Parameter(Mandatory, Position = 1)][string]$OutputDirectory,
    [Parameter(Mandatory, Position = 2)][ValidateSet('x64', 'arm64')][string]$Architecture,
    [string]$Version,
    [ValidateRange(1, 1024)][int]$Jobs,
    [switch]$Fresh
)

$packageName = 'AlgoritmicoLtd.Passepartout'
$packagePublisher = 'CN=7E22A01C-9C4D-4F14-80A5-F0F62FBCEC09'
$publisherDisplayName = 'Algoritmico Ltd'

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ($env:OS -ne 'Windows_NT') { throw 'Windows packages must be built on Windows.' }
$source = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
if (-not $Version) {
    $config = Get-Content -LiteralPath (Join-Path $source '../app-apple/Passepartout/Config.xcconfig') -Raw
    if ($config -notmatch '(?m)^MARKETING_VERSION\s*=\s*([0-9]+\.[0-9]+\.[0-9]+)\s*$') {
        throw 'Could not read the shared release version.'
    }
    $Version = "$($Matches[1]).0"
}
if ($Version -notmatch '^[0-9]+\.[0-9]+\.[0-9]+\.0$') {
    throw 'The Store version must have four numeric components and a zero revision.'
}
$packageVersion = [version]$Version
if ($packageVersion.Major -lt 1 -or $packageVersion.Major -gt 65535 -or
    $packageVersion.Minor -gt 65535 -or $packageVersion.Build -gt 65535) {
    throw 'Store version components must be at most 65535, with a nonzero major.'
}

function InvokeTool {
    param([string]$Path, [string[]]$Arguments)
    & $Path @Arguments
    if ($LASTEXITCODE -ne 0) { throw "$Path failed with exit code $LASTEXITCODE." }
}

$output = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputDirectory)
$build = Join-Path $source "out/build/package-windows-$Architecture"
# Each invocation stages only its own install output, never stale development files.
$stage = Join-Path $source "out/install/package-windows-$Architecture/$([guid]::NewGuid().ToString('N'))"
# Preserve the selected CMake instead of picking up Visual Studio's bundled copy.
$cmake = (Get-Command cmake -CommandType Application | Select-Object -First 1).Source

$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio/Installer/vswhere.exe'
$visualStudio = & $vswhere -latest -products '*' -requires 'Microsoft.VisualStudio.Component.VC.Tools.x86.x64' -property installationPath
if ($LASTEXITCODE -ne 0 -or -not $visualStudio) { throw 'Visual Studio C++ build tools were not found.' }
Import-Module (Join-Path $visualStudio 'Common7/Tools/Microsoft.VisualStudio.DevShell.dll')
# Read the machine environment, not the emulated PowerShell process environment.
$nativeArchitecture = [Environment]::GetEnvironmentVariable('PROCESSOR_ARCHITECTURE', 'Machine')
$hostArchitecture = if ($nativeArchitecture -eq 'ARM64') { 'arm64' } else { 'x64' }
Enter-VsDevShell -VsInstallPath $visualStudio -SkipAutomaticLocation -DevCmdArguments "-arch=$Architecture -host_arch=$hostArchitecture"
# Update an existing CMake cache that may still point at an emulated host compiler.
$compiler = (Get-Command cl.exe -CommandType Application | Select-Object -First 1).Source
$makeAppx = Join-Path $env:WindowsSdkDir "bin/$($env:WindowsSDKVersion.TrimEnd('\'))/$hostArchitecture/makeappx.exe"
if (-not (Test-Path -LiteralPath $makeAppx)) { throw 'Windows SDK MakeAppx.exe was not found.' }

$configureArguments = @('-S', $source, '--preset', "windows-$Architecture", '-B', $build,
    "-DCMAKE_INSTALL_PREFIX=$stage", "-DPASSEPARTOUT_PACKAGE_VERSION=$packageVersion",
    "-DCMAKE_C_COMPILER=$compiler", "-DCMAKE_CXX_COMPILER=$compiler",
    "-DPASSEPARTOUT_PACKAGE_NAME=$packageName",
    "-DPASSEPARTOUT_PACKAGE_PUBLISHER=$packagePublisher",
    "-DPASSEPARTOUT_PUBLISHER_DISPLAY_NAME=$publisherDisplayName")
if ($Fresh) { $configureArguments = @('--fresh') + $configureArguments }
InvokeTool $cmake $configureArguments
$buildArguments = @('--build', $build, '--config', 'Release')
if ($PSBoundParameters.ContainsKey('Jobs')) { $buildArguments += @('--parallel', "$Jobs") }
InvokeTool $cmake $buildArguments
InvokeTool $cmake @('--install', $build, '--config', 'Release')

New-Item -ItemType Directory -Force -Path $output | Out-Null
$package = Join-Path $output "Passepartout.$Architecture.msix"
InvokeTool $makeAppx @('pack', '/o', '/d', $stage, '/p', $package)
if (-not (Test-Path -LiteralPath $package -PathType Leaf)) {
    throw "Expected package was not produced: $package"
}
Write-Host "Package ready: $package"
