<# =============================================================================
Script:         DIRECT Framework Run-Tests Script
Documentation:  https://github.com/data-solution-automation-engine/DIRECT
Version:        DIRECT Framework 2.1.0
--------------------------------------------------------------------------------

Runs compiled tests against a local SQL Server instance hosted in a Podman container.

Prerequisites:
- A full test container has been created using the 'Create-Container' script.

Disclaimer:
- This script is provided "as-is" without warranty of any kind.
- Released as part of the DIRECT Framework project,
  see documentation link above for more information.
--------------------------------------------------------------------------------
============================================================================= #>

Push-Location

# Set cwd to the repo root folder.
Set-Location -Path (Split-Path $PSScriptRoot -Parent)

Write-Host (Get-Location)
<# =============================================================================
START - Define script behavior and config - change or refine as needed below.
Changes are only expected within this block, everything else is automated and
controlled by these definitions.
----------------------------------------------------------------------------- #>

$RecompileTests = $true

$SqlServerPort = 1433
$SqlPassword = "Awesome!Passw0rd"
$LocalAddress = "127.0.0.1"

# The connection string to the system database "master"
$MasterConnectionString =
"Server=$LocalAddress,${SqlServerPort};Initial Catalog=master;User Id=sa;
Password=${SqlPassword};TrustServerCertificate=true;"

<# =============================================================================
FOLD IN HELPERS AND UTILITIES
Load required utility functions and helpers from the Utils folder
----------------------------------------------------------------------------- #>

. "Scripts/Utils/Write-Utils.ps1"
. "Scripts/Utils/Invoke-WithRetry.ps1"
. "Scripts/Utils/Test-DotnetTool.ps1"
. "Scripts/Utils/Test-PortInUse.ps1"
. "Scripts/Utils/Deploy-Dacpac.ps1"
. "Scripts/Utils/Get-DacpacVersion.ps1"
. "Scripts/Utils/Invoke-Sqlcmd.ps1"
. "Scripts/Utils/ConvertTo-MarkdownTable.ps1"
. "Scripts/Utils/Install-SqlServerModule.ps1"

<# =============================================================================
RUN TESTS, RECOMPILE IF TOGGLED
----------------------------------------------------------------------------- #>

# Testing framework
Write-Heading "Running tests."
Write-Info "Note, Tests must be compiled before running."

# Recompile the test scripts
if ($RecompileTests -eq $true) {
  Write-Info "Recompiling test scripts..."
  $CompileScript = "Testing/compile-tests.ps1"
  if (Test-Path $CompileScript) {
    Write-Info "Running compile-tests.ps1..."
    & $CompileScript
  }
  else {
    Write-Error "Compile-tests.ps1 not found at '$CompileScript'"
  }
}
Write-Host (Get-Location)
# Select all test scripts in the compiled tests directory
$SqlScripts = Get-ChildItem -Path "Testing/Compiled_Tests" -Filter "test*.sql" -File | ForEach-Object {
  $_.FullName
}
if ($SqlScripts.Count -gt 0) {
  Write-Info "Executing $($SqlScripts.Count) test scripts."

  # Execute each test script

  foreach ($ScriptFile in $SqlScripts) {
    $Result = Invoke-Sqlcmd -SqlPath $ScriptFile -ConnectionString $MasterConnectionString -Silent
    if (-not $Result) {
      Write-Error "Sqlcmd script execution failed for:`n$ScriptFile"
      $ErrorMessages += "Task: Sqlcmd script execution failed for:"
      $ErrorMessages += "      '$ScriptFile'"
    }
    else {
      Write-Result "Sqlcmd script executed successfully:`n$ScriptFile"
      $SuccessMessages += "Task: Sqlcmd script executed successfully:"
      $SuccessMessages += "      '$ScriptFile'"
    }
  }

  # Prep for test results output
  $outputDir = "Testing/TestResults"
  if (!(Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
  }

  # Test results query, get latest result per test
  $Query = "SELECT
    [TEST_ID],
    [TEST_TIMESTAMP],
    [RESULT]
FROM (
    SELECT
        [TEST_ID],
        [TEST_TIMESTAMP],
        [RESULT],
        ROW_NUMBER() OVER (PARTITION BY [TEST_ID] ORDER BY [TEST_TIMESTAMP] DESC) AS rn
    FROM [Testing_Framework].[ut].[TEST_RESULTS]
) AS t
WHERE rn = 1;"

  # Output files for test results in different colors
  $JsonOutputPath = Join-Path $outputDir "overview-results.json"
  $MdOutputPath = Join-Path $outputDir "overview-results.md"
  $TxtOutputPath = Join-Path $outputDir "overview-results.txt"

  # Run direct query on database through SqlServer module
  $rows = SqlServer\Invoke-Sqlcmd -ConnectionString $MasterConnectionString -Query $Query

  # Project SQL results to plain pwsh pscustomobject objects
  $rowsClean =
  $rows |
  Select-Object TEST_ID, TEST_TIMESTAMP, RESULT |
  ForEach-Object {
    [pscustomobject]@{
      TEST_ID        = $_.TEST_ID
      TEST_TIMESTAMP = ([datetime]$_.TEST_TIMESTAMP)  # normalize
      RESULT         = $_.RESULT
    }
  }

  <# ========== JSON START ========== #>
  if ($rowsClean -and $rowsClean.Count -gt 0) {
    $rowsClean | ConvertTo-Json -Depth 5 | Set-Content -Path $JsonOutputPath -Encoding UTF8
  }
  else {
    Set-Content -Path $JsonOutputPath -Value "[]" -Encoding UTF8
    Write-Host "No rows returned; wrote empty JSON array to $JsonOutputPath"
  }
  <# ========== JSON END ========== #>

  <# ========== MD START ========== #>
  $markdown = $rowsClean | ConvertTo-MarkdownTable -Property TEST_ID, TEST_TIMESTAMP, RESULT
  Set-Content -Path $MdOutputPath -Value $markdown -Encoding UTF8
  <# ========== MD END ========== #>

  <# ========== TXT START ========== #>
  $rowsClean |
  Select-Object TEST_ID,
  @{ Name = 'TEST_TIMESTAMP'; Expression = { $_.TEST_TIMESTAMP.ToString('yyyy-MM-dd HH:mm:ss') } },
  RESULT |
  Format-Table -AutoSize |
  Out-String |
  Set-Content -Path $TxtOutputPath -Encoding UTF8
  <# ========== TXT END ========== #>

  Write-Host "Test results saved to $outputDir" -ForegroundColor Green
}
else {
  Write-Error "No compiled test scripts found in 'Compiled_Tests' directory."
}

Pop-Location

<# =============================================================================
END OF TRIP, THANK YOU FOR COMING ALONG
----------------------------------------------------------------------------- #>
