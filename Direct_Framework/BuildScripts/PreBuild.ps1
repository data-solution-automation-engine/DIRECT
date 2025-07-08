################################################################################################################################################################
# DATABASE PROJECT PRE-BUILD PWSH SCRIPT
################################################################################################################################################################

param([string]$path)

try {
  Write-Host ("`n" + ('*' * 80)) -ForegroundColor Green
  Write-Host "*** PWSH - Pre-Build Event: process starting..." -ForegroundColor Green
  Write-Host (('*' * 80) + "`n") -ForegroundColor Green

  ################################################################################################################################################################
  # Add tasks and steps here as needed
  # These are executed before the build of the database project starts
  # This could include testing, validation, migration, setups, build alerts etc.
  # More useful for local development,
  # for ci/cd scenarios it might be more convenient to run these tasks/steps as separate parts of the pipeline

  # OPTIONAL - run pre-dacpac deployment script using sqlcmd
  # Use this to validate pre-dacpac deployment scripts from inside the project build process

  # script assumes using the new go version
  # https://github.com/microsoft/go-sqlcmd
  # https://learn.microsoft.com/en-au/sql/tools/sqlcmd/sqlcmd-utility
  # Install through:
  #  - winget install sqlcmd

  if ($false) {
    Write-Host "*** - Running integrated pre-dacpac deployment script testing execution..."

    # Change active folder to the reference project
    Set-Location "$path\..\DeploymentScripts\1-PreDacpacDeployment"

    # Target server and Database *NOT* parameterised here...
    Get-Location | Write-Host
    sqlcmd -S . -d DIRECT_Framework -E -Q "SELECT @@VERSION;"
    sqlcmd -S . -d DIRECT_Framework -E -i PreDacpacDeployment.sql

    # return to the original folder for further processing as needed...
    Set-Location -
  }
  else {
    Write-Host "*** - Skipping integrated pre-dacpac deployment script testing execution..." -ForegroundColor Blue
  }

  ################################################################################################################################################################
  Write-Host ("`n" + ('*' * 80)) -ForegroundColor Green
  Write-Host "*** PWSH - Pre-Build Event: process completed..." -ForegroundColor Green
  Write-Host (('*' * 80) + "`n") -ForegroundColor Green
}
catch {
  Write-Host ("`n" + ('*' * 80)) -ForegroundColor Red
  Write-Host "*** PWSH - Pre-Build Event: process failed with error:`n$($_.Exception.Message)" -ForegroundColor Red
  Write-Host (('*' * 80) + "`n") -ForegroundColor Red
  exit 1
}
