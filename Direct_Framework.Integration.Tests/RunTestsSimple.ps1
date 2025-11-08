# RunTestsSimple.ps1
# Simple test runner using Microsoft Testing Platform with code coverage

Write-Host "Running tests with Microsoft Testing Platform and Code Coverage..." -ForegroundColor Green

# set cwd to the script location
Set-Location -Path $PSScriptRoot

# Run tests with coverage using the new Microsoft Testing Platform
dotnet run --project . --configuration Debug -- `
    --results-directory TestResults `
    --report-trx `
    --report-trx-filename TestResults.trx `
    --coverage `
    --coverage-output TestResults/coverage.cobertura.xml `
    --coverage-output-format cobertura

$exitCode = $LASTEXITCODE

Write-Host "`nTest execution completed with exit code: $exitCode" -ForegroundColor $(if ($exitCode -eq 0) { "Green" } else { "Red" })

if (Test-Path "TestResults/coverage.cobertura.xml") {
    Write-Host "Coverage file generated: TestResults/coverage.cobertura.xml" -ForegroundColor Green
    Write-Host "You can use tools like ReportGenerator to create HTML reports from this file." -ForegroundColor Cyan
} else {
    Write-Host "No coverage file found. Check if code coverage is properly configured." -ForegroundColor Yellow
}

exit $exitCode
