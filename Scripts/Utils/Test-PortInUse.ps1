<#
.SYNOPSIS
  Checks if a TCP port is in use on the local machine.
.DESCRIPTION
  Determines if the specified port is currently in use,
  using platform-appropriate methods.
.PARAMETER Port
  The port number to check.
.EXAMPLE
  if (Test-PortInUse -Port 1433) { Write-Host "Port in use!" }
.NOTES
  Returns $true if the port is in use, otherwise $false.
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
