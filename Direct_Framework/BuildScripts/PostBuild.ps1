################################################################################################################################################################
# DATABASE PROJECT POST-BUILD PWSH SCRIPT
################################################################################################################################################################

param(
    [string]$Configuration = "Debug"
)

try {
  Write-Host ("`n" + ('*' * 80)) -ForegroundColor Green
  Write-Host "*** PWSH - Post-Build Event: process starting..." -ForegroundColor Green
  Write-Host (('*' * 80) + "`n") -ForegroundColor Green

  ################################################################################################################################################################
  # Add tasks and steps here as needed
  # These are executed after the build of the database project completes
  # This could include testing, validation, output compares
  # More useful for local development,
  # for ci/cd scenarios it might be more convenient to run these tasks/steps as separate parts of the pipeline

  # Copy the project outputs to the next release directory
  # This allows the test projects to test the next/local version
  # without relying on a direct connection to, or a build of, this project
  # Also assumes the project is built with the latest changes before tests
  Write-Host "*** - Copy output to next release directory..." -ForegroundColor Cyan
  $sourcePath = "$PSScriptRoot\..\bin\$Configuration"
  $destinationPath = "$PSScriptRoot\..\..\Releases.Direct_Framework\next\db"

  if (Test-Path -Path $sourcePath) {
    # Make sure target directory exists
    New-Item -ItemType Directory -Path $destinationPath -Force | Out-Null
    # and is empty
    Get-ChildItem -Path $destinationPath -Recurse -Force | Remove-Item -Recurse -Force
    # Copy the built output to the current db release directory
    Copy-Item -Path "$sourcePath\*" -Destination $destinationPath -Recurse -Force
    Write-Host "*** - Output copied to: $destinationPath" -ForegroundColor Green
  } else {
    Write-Host "*** - Source path does not exist: $sourcePath" -ForegroundColor Red
  }

  ################################################################################################################################################################
  Write-Host ("`n" + ('*' * 80)) -ForegroundColor Green
  Write-Host "*** PWSH - Post-Build Event: process completed..." -ForegroundColor Green
  Write-Host (('*' * 80) + "`n") -ForegroundColor Green

}
catch {
  Write-Host ("`n" + ('*' * 80)) -ForegroundColor Red
  Write-Host "*** PWSH - Post-Build Event: process failed with error:`n$($_.Exception.Message)" -ForegroundColor Red
  Write-Host (('*' * 80) + "`n") -ForegroundColor Red
  exit 1
}
