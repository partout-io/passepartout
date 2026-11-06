# Build/package locally; never install certificates, enable Developer Mode, or publish.
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$BuildDirectory,
    [Parameter(Mandatory)][string]$OutputPath,
    [ValidateSet("Debug", "Release", "RelWithDebInfo")][string]$Configuration = "Release",
    [string]$CertificateThumbprint,
    [string]$TimestampUrl = "http://timestamp.digicert.com"
)
# Constants
$manifestName = 'AppxManifest.xml'
$stagingPrefix = 'passepartout-package-'
$digestAlgorithm = 'SHA256'
$requiredFilesName = 'package-files.txt'

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$build = (Resolve-Path -LiteralPath $BuildDirectory).Path
$output = [IO.Path]::GetFullPath($OutputPath)
$makeappx = (Get-Command makeappx.exe -ErrorAction Stop).Source
$stage = Join-Path ([IO.Path]::GetTempPath()) ($stagingPrefix + [guid]::NewGuid())
try {
    New-Item -ItemType Directory -Path $stage | Out-Null
    cmake --build $build --config $Configuration
    if ($LASTEXITCODE -ne 0) { throw "Build failed." }
    cmake --install $build --config $Configuration --prefix $stage
    if ($LASTEXITCODE -ne 0) { throw "Staging failed." }
    $requiredFiles = Get-Content -LiteralPath (Join-Path (Join-Path $build $Configuration) $requiredFilesName)
    foreach ($required in $requiredFiles) {
        if (-not (Test-Path -LiteralPath (Join-Path $stage $required))) {
            throw "Missing package input: $required. Configure with BUILD_APP=ON."
        }
    }
    [xml]$manifest = Get-Content -Raw -LiteralPath (Join-Path $stage $manifestName)
    if ($CertificateThumbprint) {
        $certificate = Get-Item -LiteralPath ("Cert:\CurrentUser\My\" + $CertificateThumbprint)
        if ($certificate.Subject -ne $manifest.Package.Identity.Publisher) {
            throw "The certificate subject must match PASSEPARTOUT_PACKAGE_PUBLISHER."
        }
        $signtool = (Get-Command signtool.exe -ErrorAction Stop).Source
    }
    New-Item -ItemType Directory -Force -Path ([IO.Path]::GetDirectoryName($output)) | Out-Null
    & $makeappx pack /d $stage /p $output /o
    if ($LASTEXITCODE -ne 0) { throw "MSIX validation/packaging failed." }
    if ($CertificateThumbprint) {
        & $signtool sign /sha1 $CertificateThumbprint /fd $digestAlgorithm /tr $TimestampUrl /td $digestAlgorithm $output
        if ($LASTEXITCODE -ne 0) { throw "Package signing failed." }
        & $signtool verify /pa $output
        if ($LASTEXITCODE -ne 0) { throw "Signature verification failed." }
    } else {
        Write-Warning "Unsigned prototype: sign with a trusted certificate before installation or distribution."
    }
    Write-Output $output
} finally {
    if (Test-Path -LiteralPath $stage) { Remove-Item -LiteralPath $stage -Recurse -Force }
}
