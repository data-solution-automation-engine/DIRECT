# RunTestsWithReports.ps1
# Comprehensive test runner with reports and coverage

param(
    [string]$OutputPath = "TestResults",
    [switch]$OpenReports,
    [switch]$SkipCoverage
)

# Ensure output directory exists
if (!(Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

Write-Host "Running tests with comprehensive reporting..." -ForegroundColor Green
Write-Host "Output directory: $OutputPath" -ForegroundColor Cyan

# Build the command
$testCommand = @(
    "dotnet", "test"
    "--configuration", "Debug"
    "--settings", "test.runsettings"
    "--logger", "trx;LogFileName=$OutputPath/TestResults.trx"
    "--logger", "console;verbosity=detailed"
)

if (!$SkipCoverage) {
    $testCommand += @(
        "--collect", "XPlat Code Coverage"
        "--results-directory", $OutputPath
    )
}

# Run the tests
Write-Host "Executing: $($testCommand -join ' ')" -ForegroundColor Yellow
& $testCommand[0] $testCommand[1..($testCommand.Length-1)]

$testExitCode = $LASTEXITCODE

# Process coverage results if available
if (!$SkipCoverage) {
    $coverageFiles = Get-ChildItem -Path $OutputPath -Recurse -Filter "coverage.cobertura.xml" -ErrorAction SilentlyContinue

    if ($coverageFiles) {
        Write-Host "Coverage files found:" -ForegroundColor Green
        foreach ($file in $coverageFiles) {
            Write-Host "  $($file.FullName)" -ForegroundColor Cyan
        }

        # Install reportgenerator if not available
        if (!(Get-Command "reportgenerator" -ErrorAction SilentlyContinue)) {
            Write-Host "Installing ReportGenerator tool..." -ForegroundColor Yellow
            dotnet tool install -g dotnet-reportgenerator-globaltool
        }

        # Generate HTML coverage report
        $latestCoverage = $coverageFiles | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        Write-Host "Generating HTML coverage report..." -ForegroundColor Green

        reportgenerator `
            -reports:"$($latestCoverage.FullName)" `
            -targetdir:"$OutputPath/CoverageReport" `
            -reporttypes:"Html;Badges;TextSummary" `
            -title:"Direct Framework Integration Tests"

        Write-Host "Coverage report generated at: $OutputPath/CoverageReport/index.html" -ForegroundColor Green
    }
}

# Display results summary
Write-Host "`n=== TEST RESULTS SUMMARY ===" -ForegroundColor Magenta

$trxFile = "$OutputPath/TestResults.trx"
if (Test-Path $trxFile) {
    Write-Host "TRX Report: $trxFile" -ForegroundColor Green
}

if (!$SkipCoverage -and (Test-Path "$OutputPath/CoverageReport/index.html")) {
    Write-Host "Coverage Report: $OutputPath/CoverageReport/index.html" -ForegroundColor Green
}

# Display coverage summary if available
$summaryFile = "$OutputPath/CoverageReport/Summary.txt"
if (Test-Path $summaryFile) {
    Write-Host "`nCoverage Summary:" -ForegroundColor Yellow
    Get-Content $summaryFile | Write-Host
}

# Open reports if requested
if ($OpenReports) {
    if (Test-Path "$OutputPath/CoverageReport/index.html") {
        Start-Process "$OutputPath/CoverageReport/index.html"
    }
}

Write-Host "`nTest execution completed with exit code: $testExitCode" -ForegroundColor $(if ($testExitCode -eq 0) { "Green" } else { "Red" })

exit $testExitCode
