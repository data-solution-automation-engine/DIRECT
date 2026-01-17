<#
.SYNOPSIS
    Executes a script block with retry logic.

.DESCRIPTION
    Runs a script block up to a maximum number of attempts, waiting between attempts,
    and returns $true if successful. Useful for operations that may fail transiently,
    such as network calls or resource availability checks.

.PARAMETER ScriptBlock
    The script block to execute. Should return $true on success, $false or throw
    an exception on failure.

.PARAMETER MaxAttempts
    Maximum number of attempts before giving up. Default is 10.

.PARAMETER NapLength
    Seconds to wait between retry attempts. Default is 5.

.EXAMPLE
    Invoke-WithRetry -ScriptBlock { Test-Connection -ComputerName 'server' -Quiet } -MaxAttempts 5 -NapLength 2

.EXAMPLE
    Invoke-WithRetry -ScriptBlock { Test-NetConnection -ComputerName 'localhost' -Port 1433 } -MaxAttempts 30

.OUTPUTS
    System.Boolean - Returns $true if the script block succeeds, otherwise $false.

.NOTES
    File Name      : Invoke-WithRetry.ps1
    Prerequisite   : PowerShell 5.1 or later
    License        : LGPL-3.0 (GNU Lesser General Public License v3.0)

.LINK
    https://github.com/data-solution-automation-engine/DIRECT

.LINK
    https://github.com/data-solution-automation-engine/DIRECT/blob/main/COPYING.txt

.COMPONENT
    DIRECT Framework - Data Integration Runtime Execution Control Tools

.FUNCTIONALITY
    Resilient execution and retry pattern implementation.
#>
function Invoke-WithRetry {
  param(
    [Parameter(Mandatory = $true)][ScriptBlock]$ScriptBlock,
    [int]$MaxAttempts = 10,
    [int]$NapLength = 5
  )
  $attempt = 1
  while ($attempt -le $MaxAttempts) {
    try {
      if (& $ScriptBlock) {
        return $true
      }
    }
    catch {
      # Ignore, will retry
    }
    if ($attempt -lt $MaxAttempts) {
      Start-Sleep -Seconds $NapLength
    }
    $attempt++
  }
  return $false
}
