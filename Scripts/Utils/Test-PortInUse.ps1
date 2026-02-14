<#
.SYNOPSIS
    Checks if a TCP port is in use on the local machine.

.DESCRIPTION
    Determines if the specified port is currently in use on a given local address,
    using platform-appropriate methods (Get-NetTCPConnection on Windows, netstat
    on other platforms).

.PARAMETER LocalAddress
    The local IP address to check (e.g., '127.0.0.1', '0.0.0.0').

.PARAMETER LocalPort
    The port number to check.

.EXAMPLE
    if (Test-PortInUse -LocalAddress '127.0.0.1' -LocalPort 1433) {
        Write-Host "SQL Server port is in use!"
    }

.EXAMPLE
    Test-PortInUse -LocalAddress '0.0.0.0' -LocalPort 8080

.OUTPUTS
    System.Boolean - Returns $true if the port is in use, otherwise $false.

.NOTES
    File Name      : Test-PortInUse.ps1
    Prerequisite   : PowerShell 5.1 or later
    License        : LGPL-3.0 (GNU Lesser General Public License v3.0)

.LINK
    https://github.com/data-solution-automation-engine/DIRECT

.LINK
    https://github.com/data-solution-automation-engine/DIRECT/blob/main/COPYING.txt

.COMPONENT
    DIRECT Framework - Data Integration Runtime Execution Control Tools

.FUNCTIONALITY
    Network port availability checking and validation.
#>
function Test-PortInUse {
  param(
    [Parameter(Mandatory = $true)][string]$LocalAddress,
    [Parameter(Mandatory = $true)][int]$LocalPort
  )

  if ($IsWindows) {
    $result = Get-NetTCPConnection -LocalAddress $LocalAddress -LocalPort $LocalPort -ErrorAction SilentlyContinue
    return $null -ne $result
  }
  else {
    $result = netstat -tuln 2>/dev/null | Select-String "[:.]$LocalPort(\s|$|:)"
    return $result.Count -gt 0
  }
}

# WIP, doesn't work all that well yet
# Check if the port is available or already in use,
# wait for Podman to release the port if needed
# Start-Sleep -Seconds $napLength
# if (Test-PortInUse -LocalAddress $localAddress -LocalPort $sqlServerPort) {
#   Write-Error "Port '$sqlServerPort' on '$localAddress' is already in use on the host."
#   Write-Error "Exiting: Please define an available local port."
#   exit 1
# }
