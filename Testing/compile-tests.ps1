# Set cwd to the testing directory.
Set-Location -Path (Join-Path $PSScriptRoot '')

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

  # Prepare <<TEST-NAME>> → wrap in single quotes
  $testNameQuoted = "'" + $testName + "'"

  # Read raw test SQL
  $testCodeRaw = Get-Content $testFile.FullName -Raw

  # Remove the framework DECLARE block
  $testCodeCleaned = [regex]::Replace(
    $testCodeRaw,
    '/\*\s*Required for testing framework\s*\*/\s*DECLARE\s+.*?(?=(\r?\n){2,}|$)',
    '',
    'Singleline,IgnoreCase'
  )

  # Trim excess whitespace
  $testCodeCleaned = $testCodeCleaned.Trim()

  # Escape single quotes for SQL literal
  $testCodeEscaped = $testCodeCleaned -replace "'", "''"

  # Wrap in single quotes
  $testCodeQuoted = "'" + $testCodeEscaped + "'"

  # Replace in wrapper
  $compiledContent = $wrapperTemplate `
    -replace "<<TEST-NAME>>", $testNameQuoted `
    -replace "<<TEST-CODE>>", $testCodeQuoted

  # Write output
  $outputPath = Join-Path $outputDirectory "$testName.sql"
  Set-Content -Path $outputPath -Value $compiledContent -Encoding UTF8
}

Write-Host "Compiled tests written to '$outputDirectory'."
