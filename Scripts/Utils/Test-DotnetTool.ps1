<#
.SYNOPSIS
    Checks for the existence and usability of a dotnet tool (local or global).

.DESCRIPTION
    Checks if the specified dotnet tool is installed locally or globally, attempts
    to restore from dotnet-tools.json if missing, and returns a hashtable with tool
    existence status and the command string to invoke it.

.PARAMETER ToolName
    The name of the dotnet tool to check (e.g., 'sqlpackage').

.EXAMPLE
    $tool = Test-DotnetTool -ToolName "sqlpackage"
    if ($tool.Exists) { & $tool.Command --version }

.EXAMPLE
    $result = Test-DotnetTool -ToolName "dotnet-ef"

.OUTPUTS
    System.Collections.Hashtable - Returns @{ Exists = $true/$false; Command = "..." }

.NOTES
    File Name      : Test-DotnetTool.ps1
    Prerequisite   : PowerShell 5.1 or later, .NET SDK
    License        : LGPL-3.0 (GNU Lesser General Public License v3.0)

.LINK
    https://github.com/data-solution-automation-engine/DIRECT

.LINK
    https://github.com/data-solution-automation-engine/DIRECT/blob/main/COPYING.txt

.LINK
    https://learn.microsoft.com/en-us/dotnet/core/tools/dotnet-tool-install

.COMPONENT
    DIRECT Framework - Data Integration Runtime Execution Control Tools

.FUNCTIONALITY
    Dotnet tool discovery and validation.
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
