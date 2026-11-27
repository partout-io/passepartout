# SPDX-FileCopyrightText: 2026 Davide De Rosa
#
# SPDX-License-Identifier: GPL-3.0

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$scriptPath = Join-Path $PSScriptRoot '../scripts/run-app.ps1'
$parseErrors = $null
$ast = [Management.Automation.Language.Parser]::ParseFile($scriptPath, [ref]$null, [ref]$parseErrors)
if ($parseErrors.Count) { throw $parseErrors[0] }
# Load only pure registration helpers, never the build/install/launch entry point.
foreach ($name in @('TestRegistrationReceipt', 'GetNextDevelopmentVersion', 'TestAppContainerManifest')) {
    $definition = $ast.Find({
        param($node)
        $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $name
    }, $true)
    . ([scriptblock]::Create($definition.Extent.Text))
}
function AssertEqual($Actual, $Expected) {
    if ($Actual -ne $Expected) { throw "Expected '$Expected', got '$Actual'." }
}
function AssertRejected([scriptblock]$Operation) {
    $rejected = $false
    try { & $Operation | Out-Null } catch { $rejected = $true }
    if (-not $rejected) { throw 'Expected rejection.' }
}
$temporary = Join-Path ([IO.Path]::GetTempPath()) ('passepartout-registration-' + [guid]::NewGuid())
[void][IO.Directory]::CreateDirectory($temporary)
$receiptPath = Join-Path $temporary 'receipt.json'
$manifestPath = Join-Path $temporary 'manifest.xml'
try {
    $template = Get-Content -LiteralPath (Join-Path $PSScriptRoot '../windows/AppxManifest.xml.in') -Raw
    $applicationId = '@PASSEPARTOUT_APPLICATION_ID_XML@'
    AssertEqual (TestAppContainerManifest ([xml]$template) $applicationId) $true
    AssertEqual (TestAppContainerManifest ([xml]$template.Replace('appContainer', 'mediumIL')) $applicationId) $false
    AssertEqual (TestAppContainerManifest ([xml]$template.Replace('packagedClassicApp', 'win32App')) $applicationId) $false
    AssertEqual (TestAppContainerManifest ([xml]$template.Replace('<Capabilities>',
        '<Capabilities><rescap:Capability Name="runFullTrust" />')) $applicationId) $false
    AssertEqual (TestAppContainerManifest ([xml]$template.Replace('<Properties>',
        '<Properties><uap10:AllowExternalContent>true</uap10:AllowExternalContent>')) $applicationId) $false
    AssertEqual (TestAppContainerManifest ([xml]$template) 'Missing') $false
    [xml]$package = $template
    foreach ($capability in @('internetClientServer', 'privateNetworkClientServer', 'networkingVpnProvider')) {
        AssertEqual ([bool]$package.SelectSingleNode("//*[local-name()='Capability' and @Name='$capability']")) $true
    }
    AssertEqual ([bool]$package.SelectSingleNode("//*[local-name()='Task' and @Type='vpnClient']")) $true

    AssertEqual (GetNextDevelopmentVersion '0.1.0.0' @('0.1.0.0')) '0.1.0.1'
    AssertEqual (GetNextDevelopmentVersion '0.1.0.0' @('0.1.0.8', '0.2.0.0')) '0.2.0.1'
    AssertEqual (GetNextDevelopmentVersion '0.1.0.0' @('1.0.0.0')) '1.0.0.1'
    AssertEqual (GetNextDevelopmentVersion '3.12.9.0' @()) '3.12.9.1'
    AssertEqual (GetNextDevelopmentVersion '3.12.9.0' @('3.12.9.8')) '3.12.9.9'
    AssertEqual (GetNextDevelopmentVersion '3.13.0.0' @('3.12.9.8')) '3.13.0.1'
    AssertRejected { GetNextDevelopmentVersion '3.12.9.65535' @() }
    AssertRejected { GetNextDevelopmentVersion '0.1.0.65535' @() }

    [IO.File]::WriteAllText($manifestPath, '<Path>passepartout-vpnchannel.dll</Path>')
    $oldHash = (Get-FileHash $manifestPath -Algorithm SHA256).Hash
    AssertEqual (TestRegistrationReceipt $receiptPath $oldHash $temporary) $false
    $receipt = @{ ManifestHash = $oldHash; InstallDirectory = $temporary } | ConvertTo-Json
    [IO.File]::WriteAllText($receiptPath, $receipt)
    AssertEqual (TestRegistrationReceipt $receiptPath $oldHash $temporary) $true
    AssertEqual (TestRegistrationReceipt $receiptPath $oldHash 'different-install') $false

    # A same-version DLL rename must invalidate reuse even if the manifest on
    # disk has already been overwritten and Windows still reports Status=Ok.
    [IO.File]::WriteAllText($manifestPath, '<Path>passepartout-vpnplugin.dll</Path>')
    $newHash = (Get-FileHash $manifestPath -Algorithm SHA256).Hash
    AssertEqual (TestRegistrationReceipt $receiptPath $newHash $temporary) $false
    [IO.File]::WriteAllText($receiptPath, '{}')
    AssertEqual (TestRegistrationReceipt $receiptPath $newHash $temporary) $false
    [IO.File]::WriteAllText($receiptPath, 'invalid json')
    AssertEqual (TestRegistrationReceipt $receiptPath $newHash $temporary) $false
    Write-Output 'Development registration tests passed.'
} finally {
    # Only these known fixture files were created by this test.
    foreach ($path in @($receiptPath, $manifestPath)) {
        if (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path }
    }
    [IO.Directory]::Delete($temporary)
}
