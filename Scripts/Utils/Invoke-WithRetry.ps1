<#
.SYNOPSIS
  Executes a script block with retry logic.
.DESCRIPTION
  Runs a script block up to a maximum number of attempts, waiting between attempts, and returns $true if successful.
.PARAMETER ScriptBlock
  The script block to execute. Should return $true on success, $false or throw on failure.
.PARAMETER MaxAttempts
  Maximum number of attempts (default: 10).
.PARAMETER NapLength
  Seconds to wait between attempts (default: 5).
.EXAMPLE
  Invoke-WithRetry -ScriptBlock { Test-Connection ... } -MaxAttempts 5 -NapLength 2
.NOTES
  Returns $true if the script block succeeds, otherwise $false.
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
