param(
    [string] $Direction,
    [string] $Protocol
)

$ErrorActionPreference = "Stop"

if ($Direction -notin @("up", "down") -or $Protocol -notin @("udp", "tcp")) {
    Write-Error "Usage: $($MyInvocation.MyCommand.Name) up|down udp|tcp"
    exit 1
}

# The protocol selects the VPN server, not the iperf3 transport.
$serverAddress = switch ($Protocol) {
    "udp" { "10.12.0.1" }
    "tcp" { "10.13.0.1" }
}

$iperfArguments = @("-c", $serverAddress, "-P", "8", "-t", "600")
if ($Direction -eq "down") {
    $iperfArguments += "-R"
}

& iperf3 @iperfArguments
exit $LASTEXITCODE
