
<#
.SYNOPSIS
  Checks for the existence and usability of a dotnet tool (local or global).
.DESCRIPTION
  Checks if the specified dotnet tool is installed locally or globally, attempts to restore if missing, and returns a hashtable with tool existence and command string.
.PARAMETER ToolName
  The name of the dotnet tool to check (e.g., 'sqlpackage').
.EXAMPLE
  $tool = Test-Tool -ToolName "sqlpackage"
.NOTES
  Returns a hashtable: @{ Exists = $true/$false; Command = "..." }
#>
function Test-DotnetTool {
  param(
    [Parameter(Mandatory = $true)][string]$ToolName
  )

  $toolExists = $false
  $toolCommand = ""

  # check for local or global tool
  $localTools = dotnet tool list --local
  if ($localTools -match $ToolName) {
    Write-Host "Local tool '$ToolName' is installed. Testing version:"
    # Try running the tool to verify it's functional
    $localToolVersion = dotnet tool run $ToolName -version
    if ($LASTEXITCODE -eq 0) {
      $toolExists = $true
      $toolCommand = "dotnet tool run $ToolName"

      Write-Host "'$ToolName' is ready to use." -ForegroundColor Green
      Write-Host "Tool version: $localToolVersion"
    }
    else {
      Write-Warning "Local version of '$ToolName' failed to run."
    }
  }
  if (-not $toolExists) {
    Write-Host "Local tool '$ToolName' is not available. Attempting restore..."
    # Restore the local dotnet tools as defined in `.config/dotnet-tools.json`
    try {
      dotnet tool restore
      Write-Host "Local dotnet tools restored." -ForegroundColor Green
      dotnet tool run $ToolName -version
      if ($LASTEXITCODE -eq 0) {
        $toolExists = $true
        $toolCommand = "dotnet tool run $ToolName"
        Write-Host "'$ToolName' is ready to use." -ForegroundColor Green
      }
      else {
        Write-Warning "Local version of '$ToolName' still failed to run."
      }

    }
    catch {
      Write-Error "Failed to restore local tools:`n$_"
    }
  }

  if (-not $toolExists) {
    Write-Warning "Local tool discovery of '$ToolName' failed. Going global..."

    # Check for global installation of tool
    $globalTools = dotnet tool list --global
    if ($globalTools -match $ToolName) {
      Write-Host "Global tool '$ToolName' is installed. Testing version."
      # Try running the tool to verify it's functional
      $globalToolVersion = & $ToolName -version
      if ($LASTEXITCODE -eq 0) {
        Write-Host "Global '$ToolName' is ready to use." -ForegroundColor Green
        Write-Host "version: $globalToolVersion"
        $toolExists = $true
        $toolCommand = $ToolName
      }
      else {
        Write-Warning "Global '$ToolName' failed to run."
      }
    }
  }

  if (-not $toolExists) {
    Write-Error "Tool '$toolName' could not be found. Please install/repair, validate and resolve any issues."
    return @{
      Exists  = $toolExists
      Command = ""
    }
  }

  return @{
    Exists  = $toolExists
    Command = $toolCommand
  }
}
