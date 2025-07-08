################################################################################################################################################################
# DATABASE PROJECT POST-BUILD PWSH SCRIPT
################################################################################################################################################################

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

  # placeholder...
  Write-Host "*** - Post-dacpac deployment script placeholder..." -ForegroundColor Blue

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
