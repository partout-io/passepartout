# SPDX-FileCopyrightText: 2026 Davide De Rosa
#
# SPDX-License-Identifier: GPL-3.0

# Create or update a current-user VPN connection from a local Partout JSON profile.
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [string]$ProfilePath,

    [ValidateNotNullOrEmpty()]
    [string]$Name = "Passepartout Test",

    # Windows requires this field; Partout uses the endpoints in the JSON profile.
    [ValidateNotNullOrEmpty()]
    [string]$ServerAddress = "profile.invalid"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$profileFile = Get-Item -LiteralPath $ProfilePath
if ($profileFile.PSIsContainer -or $profileFile.Length -gt 1MB) {
    throw "The profile must be a JSON file no larger than 1 MiB."
}
try {
    $json = [IO.File]::ReadAllText($profileFile.FullName)
    $profile = ConvertFrom-Json -InputObject $json -ErrorAction Stop
    if (-not $json.TrimStart().StartsWith("{") -or $null -eq $profile -or
        $profile -isnot [System.Management.Automation.PSCustomObject] -or
        $json.Contains([string][char]0)) {
        throw "Invalid profile"
    }
} catch {
    # JSON parser messages may contain credentials. Keep the error content-free.
    throw "The profile must contain a valid JSON object."
}

$configuration = New-Object System.Xml.XmlDocument
$root = $configuration.CreateElement("PartoutProfile")
$root.SetAttribute("version", "1")
$root.InnerText = $json
$null = $configuration.AppendChild($root)
if ($configuration.OuterXml.Length -gt 1MB) {
    throw "The encoded profile exceeds the plugin's 1 MiB limit."
}

$packages = @(Get-AppxPackage -Name "Passepartout.VpnChannel")
if ($packages.Count -ne 1) {
    throw "Register the VPN plugin by launching the installed passepartout-tunnel.exe first."
}
$applicationId = $packages[0].PackageFamilyName
$existing = @(Get-VpnConnection | Where-Object { $_.Name -eq $Name })
if ($existing.Count -gt 0) {
    if ($existing[0].PlugInApplicationID -ne $applicationId) {
        throw "A connection with this name belongs to another VPN provider. Choose another name."
    }
    if ($existing[0].ConnectionStatus -ne "Disconnected") {
        throw "Disconnect the VPN before updating its profile."
    }
    if ($PSCmdlet.ShouldProcess($Name, "Update Partout VPN configuration")) {
        $null = Set-VpnConnection -Name $Name -ThirdPartyVpn -ServerAddress $ServerAddress `
            -CustomConfiguration $configuration
    }
} elseif ($PSCmdlet.ShouldProcess($Name, "Create Partout VPN connection")) {
    $null = Add-VpnConnection -Name $Name -ServerAddress $ServerAddress `
        -PlugInApplicationID $applicationId -CustomConfiguration $configuration
}
