param(
    [Parameter(Mandatory = $true)]
    [string] $InstallDirectory
)

$ErrorActionPreference = "Stop"
$hostPath = [System.IO.Path]::GetFullPath(
    (Join-Path $InstallDirectory "passepartout-tunnel.exe"))

foreach ($hostProcess in @(Get-Process -Name "passepartout-tunnel" -ErrorAction SilentlyContinue)) {
    try {
        if ($hostProcess.HasExited) { continue }
        $processPath = $hostProcess.Path
        if (-not $processPath) {
            throw "Cannot inspect VPN host $($hostProcess.Id). Run installation with permission to inspect and stop it."
        }
        if (-not [string]::Equals($processPath, $hostPath, [StringComparison]::OrdinalIgnoreCase)) {
            continue
        }
        Write-Host "Stopping VPN host $($hostProcess.Id) before installing $InstallDirectory"
        Stop-Process -InputObject $hostProcess -Force
        if (-not $hostProcess.WaitForExit(10000)) {
            throw "VPN host $($hostProcess.Id) did not exit within 10 seconds."
        }
    } catch {
        # It may have exited between enumeration and termination.
        if (-not $hostProcess.HasExited) { throw }
    } finally {
        $hostProcess.Dispose()
    }
}
