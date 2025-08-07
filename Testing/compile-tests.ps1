# Set paths
$wrapperPath = "test-wrapper.sql"
$testDirectory = Get-Location
$outputDirectory = Join-Path $testDirectory "compiled-tests"

# Ensure output directory exists
if (!(Test-Path $outputDirectory)) {
  New-Item -ItemType Directory -Path $outputDirectory | Out-Null
}

# Load wrapper content
$wrapperTemplate = Get-Content $wrapperPath -Raw

# Process each test SQL file
Get-ChildItem -Path $testDirectory -Filter "*.sql" | Where-Object { $_.Name -ne "test-wrapper.sql" } | ForEach-Object {
  $testFile = $_
  $testName = [System.IO.Path]::GetFileNameWithoutExtension($testFile.Name)

  # Prepare <<TEST-NAME>> - wrap in single quotes
  $testNameQuoted = "'" + $testName + "'"

  # Read and escape test SQL code
  $testCodeRaw = Get-Content $testFile.FullName -Raw

  # Escape single quotes inside SQL string
  $testCodeEscaped = $testCodeRaw -replace "'", "''"

  # Wrap entire SQL in single quotes
  $testCodeQuoted = "'" + $testCodeEscaped + "'"

  # Replace placeholders in the wrapper
  $compiledContent = $wrapperTemplate `
    -replace "<<TEST-NAME>>", $testNameQuoted `
    -replace "<<TEST-CODE>>", $testCodeQuoted

  # Write compiled test
  $outputPath = Join-Path $outputDirectory "$testName.sql"
  Set-Content -Path $outputPath -Value $compiledContent -Encoding UTF8
}

# Output completion message
Write-Host "Compiled tests written to '$outputDirectory'"
