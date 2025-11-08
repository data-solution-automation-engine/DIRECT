# RunTestsWithReports.ps1
# Comprehensive test runner with reports and coverage using Microsoft Testing Platform

param(
    [string]$OutputPath = "TestResults",
    [switch]$OpenReports,
    [switch]$SkipCoverage
)

# Ensure output directory exists
if (!(Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

Write-Host "Running tests with Microsoft Testing Platform..." -ForegroundColor Green
Write-Host "Output directory: $OutputPath" -ForegroundColor Cyan

# Build the command for Microsoft Testing Platform
$testCommand = @(
    "dotnet", "run"
    "--project", "."
    "--configuration", "Debug"
    "--"
    "--results-directory", $OutputPath
    "--report-trx"
    "--report-trx-filename", "TestResults.trx"
)

# Add coverage arguments if not skipped
if (!$SkipCoverage) {
    $testCommand += @(
        "--coverage"
        "--coverage-output", "$OutputPath\coverage.cobertura.xml"
        "--coverage-output-format", "cobertura"
    )
    Write-Host "Code coverage enabled" -ForegroundColor Green
} else {
    Write-Host "Code coverage skipped" -ForegroundColor Yellow
}

# Run the tests
Write-Host "Executing: $($testCommand -join ' ')" -ForegroundColor Yellow
& $testCommand[0] $testCommand[1..($testCommand.Length-1)]

$testExitCode = $LASTEXITCODE

# Process coverage results if available
if (!$SkipCoverage) {
    $coverageFile = "$OutputPath\coverage.cobertura.xml"
    
    if (Test-Path $coverageFile) {
        Write-Host "Coverage file found: $coverageFile" -ForegroundColor Green

        # Install reportgenerator if not available
        if (!(Get-Command "reportgenerator" -ErrorAction SilentlyContinue)) {
            Write-Host "Installing ReportGenerator tool..." -ForegroundColor Yellow
            dotnet tool install -g dotnet-reportgenerator-globaltool
        }

        # Generate HTML coverage report
        Write-Host "Generating HTML coverage report..." -ForegroundColor Green

        reportgenerator `
            -reports:"$coverageFile" `
            -targetdir:"$OutputPath\CoverageReport" `
            -reporttypes:"Html;Badges;TextSummary;JsonSummary" `
            -title:"Direct Framework Integration Tests" `
            -verbosity:"Info"

        Write-Host "Coverage report generated at: $OutputPath\CoverageReport\index.html" -ForegroundColor Green
        
        # Display quick coverage summary
        $summaryFile = "$OutputPath\CoverageReport\Summary.json"
        if (Test-Path $summaryFile) {
            try {
                $summary = Get-Content $summaryFile | ConvertFrom-Json
                $lineRate = [math]::Round($summary.summary.linecoverage, 2)
                $branchRate = [math]::Round($summary.summary.branchcoverage, 2)
                Write-Host "`nQuick Coverage Summary:" -ForegroundColor Cyan
                Write-Host "  Line Coverage: $lineRate%" -ForegroundColor $(if ($lineRate -ge 80) { "Green" } elseif ($lineRate -ge 60) { "Yellow" } else { "Red" })
                Write-Host "  Branch Coverage: $branchRate%" -ForegroundColor $(if ($branchRate -ge 80) { "Green" } elseif ($branchRate -ge 60) { "Yellow" } else { "Red" })
            }
            catch {
                Write-Host "Could not parse coverage summary" -ForegroundColor Yellow
            }
        }
    } else {
        Write-Host "No coverage file found at: $coverageFile" -ForegroundColor Yellow
        Write-Host "Coverage collection may have failed or no code was covered." -ForegroundColor Yellow
    }
}

# Display results summary
Write-Host "`n=== TEST RESULTS SUMMARY ===" -ForegroundColor Magenta

$trxFile = "$OutputPath\TestResults.trx"
if (Test-Path $trxFile) {
    Write-Host "TRX Report: $trxFile" -ForegroundColor Green
} else {
    Write-Host "No TRX file found at: $trxFile" -ForegroundColor Yellow
}

if (!$SkipCoverage -and (Test-Path "$OutputPath\CoverageReport\index.html")) {
    Write-Host "Coverage Report: $OutputPath\CoverageReport\index.html" -ForegroundColor Green
}

# Open reports if requested
if ($OpenReports) {
    if (Test-Path "$OutputPath\CoverageReport\index.html") {
        Write-Host "Opening coverage report..." -ForegroundColor Green
        Start-Process "$OutputPath\CoverageReport\index.html"
    }
    if (Test-Path $trxFile) {
        Write-Host "TRX file available for viewing in Visual Studio" -ForegroundColor Green
    }
}

Write-Host "`nTest execution completed with exit code: $testExitCode" -ForegroundColor $(if ($testExitCode -eq 0) { "Green" } else { "Red" })

# Show usage examples
if ($testExitCode -ne 0) {
    Write-Host "`nUsage Examples:" -ForegroundColor Cyan
    Write-Host "  .\RunTestsWithReports.ps1                    # Run with coverage" -ForegroundColor Gray
    Write-Host "  .\RunTestsWithReports.ps1 -SkipCoverage      # Run without coverage" -ForegroundColor Gray
    Write-Host "  .\RunTestsWithReports.ps1 -OpenReports       # Run and open reports" -ForegroundColor Gray
}

exit $testExitCode
