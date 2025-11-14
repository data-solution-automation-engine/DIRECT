Push-Location

# Set cwd to the script location, the RepoRoot/Testing directory.
Set-Location $PSScriptRoot

# Set paths and locations for inputs and outputs
$wrapperPath = Join-Path $PSScriptRoot "Templates/test-wrapper.sql"
$testDirectory = Join-Path $PSScriptRoot "Tests"
$outputDirectory = Join-Path $PSScriptRoot "Compiled_Tests"

# Ensure output directory exists
if (!(Test-Path $outputDirectory)) {
  New-Item -ItemType Directory -Path $outputDirectory | Out-Null
}

# Ensure wrapper file exists
if (!(Test-Path $wrapperPath)) {
    Write-Error "Wrapper template file '$wrapperPath' not found. Exiting."
    Exit 1
}

# Load wrapper content
$wrapperTemplate = Get-Content $wrapperPath -Raw

# Process each test SQL file in the tests directory
Get-ChildItem -Path $testDirectory -Filter "*.sql" |
ForEach-Object {
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

Write-Host "Compiled tests written to '$outputDirectory'." -ForegroundColor Green

Pop-Location
