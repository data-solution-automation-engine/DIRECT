<# =============================================================================
Script:         DIRECT Framework Create-Container Script
Documentation:  https://github.com/data-solution-automation-engine/DIRECT
Version:        DIRECT Framework 2.1.0
--------------------------------------------------------------------------------

Creates a definition for, and spins up, a SQL Server linux container locally
in Podman including:

- Direct Framework DACPAC
- Testing Framework DACPAC (for regression tests)

This is a full journey from start to finish for getting a
local database environment for development and tests up and running

Prerequisites:
- Podman must be installed and running, script needs direct access to the
  Podman CLI
- The Podman service must be up, and running, and working
- The script expects PowerShell 7.5 or higher
- The script expects to run from its repo folder, with cwd set to repo root
- For dacpac deployment, the script expects the dacpac for current/next
  versions of the DIRECT Framework to be built and be available
- For dacpac deployment, the script expects the Testing Framework dacpac
  to be available
- Local dotnet tools must be restored/installed and available
- Relevant PowerShell modules must be installed and available
- Modern sqlcmd must be installed and available in the PATH

Disclaimer:
- This script creates the container with the parameter: `ACCEPT_EULA=Y`
  By running this script, you accept the EULA for SQL Server
  as defined in the container image.
- Released as part of the DIRECT Framework project,
  see documentation link above for more information.
--------------------------------------------------------------------------------
============================================================================= #>

# Set cwd to the repo root folder.
Set-Location -Path (Split-Path $PSScriptRoot -Parent)

<# =============================================================================
START - Define script behavior and config - change or refine as needed below.
Changes are only expected within this block, everything else is automated and
controlled by these definitions.
----------------------------------------------------------------------------- #>

# FrameworkVersion: The version of the DIRECT Framework used
$VersionFile = '.direct-version'
if (Test-Path $VersionFile) {
  $FrameworkVersion = Get-Content $VersionFile | Select-Object -First 1
  $FrameworkVersion = $FrameworkVersion.Trim()
}
if ([string]::IsNullOrWhiteSpace($FrameworkVersion)) {
  Write-Error "DIRECT Framework Version not found."
  $FrameworkVersion = "0.0.0"
}

# AutoPurge: If true, the script will force remove existing container/database
$AutoPurge = $true

# AutoSqlAgentScripts: If true, the script will include SQL that is dependent
# on SQL Agent being available, which excludes Azure instances (on-premises or
# managed-instance only)
$AutoSqlAgentScripts = $true

# AutoTestingFrameworkScripts: If true, the script will run SQL for
# testing framework tests.
$AutoTestingFrameworkScripts = $true

# AutoDeploy: If true, the script will automatically deploy Testing Framework
# and Direct Framework DACPACs to the container
$AutoDeploy = $true

<# SqlVersion: The numeric generation/version of SQL Server to use
This must match an available image name.
Direct Framework is currently mainly tested against SQL Server 2022,
but is expected to work across all currently mainstream supported versions,
including non-on-premises versions like Azure SQL Database and Fabric SQL.
Once SQL Server 2025 is in rc-state, DIRECT testing will be updated to match.
More information:
https://learn.microsoft.com/en-us/sql/linux/quickstart-install-connect-docker
https://mcr.microsoft.com/artifact/mar/mssql/server/about
#>
$SqlVersion = "2022"

# imageVersion: container image version to use
$ImageVersion = "$SqlVersion-latest"

# containerName: name of the container to create locally in Podman
$ContainerName = "direct-dev-$SqlVersion"

# imageBase: identifying Microsoft's registry for SQL Server images
# This is the base address to Microsoft's container images for SQL Server
$ImageBase = "mcr.microsoft.com/mssql/server"

# ImageName: Full container image name to pull
$ImageName = "${ImageBase}:${ImageVersion}"

# SqlServerPort: The port to use for connections from your host
# to the SQL Server instance in the container
# Change this if something is already using this port on the host
$SqlServerPort = 1433

# SqlPassword: the 'sa' user password for the SQL Server
# This must satisfy the password policy for the defined SQL Server version
$SqlPassword = "Awesome!Passw0rd"

# PortMapping: Define the port mapping for the SQL Server container
# This maps the SQL Server port in the container to the host port
$PortMapping = "${SqlServerPort}:1433"

<# LocalAddress: a valid address/hostname to the exposed container:
localhost, 127.0.0.1 (v4), or ::1 (v6) etc
some hosts might map "localhost" to ::1 (IPv6) by default
which doesn't always automatically work in Podman,
so this script defines and uses the v4 loopback ip as the default #>
$LocalAddress = "127.0.0.1"

# Details for deployment of the Testing Framework DacPac
$TestingFrameworkDatabaseName = "Testing_Framework"
$testingFrameworkDacpacFileName = "Reference_Dacpacs/Testing_Framework.dacpac"

# Details for deployment of the Direct Framework DacPac
$DirectFrameworkDatabaseName = "Direct_Framework"
$DirectFrameworkMoniker = "next" # "current"/"next"
$DirectFrameworkDacpacFileName = "Releases.Direct_Framework/$DirectFrameworkMoniker/db/Direct_Framework.dacpac"

# Define valid connection strings for SQL Server

# The connection string to the system database "master"
$MasterConnectionString =
"Server=$LocalAddress,${SqlServerPort};Initial Catalog=master;User Id=sa;Password=${SqlPassword};TrustServerCertificate=true;"

# The connection string to the Testing Framework database
$TestingConnectionString =
"Server=$LocalAddress,${SqlServerPort};Initial Catalog=${TestingFrameworkDatabaseName};User Id=sa;Password=${SqlPassword};TrustServerCertificate=true;"

# The connection string to the Direct Framework database
$DirectConnectionString =
"Server=$LocalAddress,${SqlServerPort};Initial Catalog=${DirectFrameworkDatabaseName};User Id=sa;Password=${SqlPassword};TrustServerCertificate=true;"

# Nap controls, increase or decrease as needed for the current host
$MaxAttempts = 10
$NapLength = 5 # seconds

<# -----------------------------------------------------------------------------
END - Define script behavior and config - change or refine as needed above.
============================================================================= #>

# Initialize global variables for feedback messages
$SuccessMessages = @()
$ErrorMessages = @()

# SETUP - Make sure we run in modern pwsh
if (
  ($PSVersionTable.PSVersion.Major -lt 7) -or
  ($PSVersionTable.PSVersion.Major -eq 7 -and $PSVersionTable.PSVersion.Minor -lt 5)
) {
  Write-Warn "Not running a required Powershell version, 7.5+."
  Write-Info "Run 'winget install Microsoft.Powershell --source winget'."
  Write-Info "or download the latest version of PowerShell from https://aka.ms/powershell"
  Write-Error "Exiting: this script expects PowerShell 7.5 or higher."
  Exit 1
}
else {
  $SuccessMessages += "Check: Running PowerShell version: $($PSVersionTable.PSVersion.ToString())"
}

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
CHECK AND VALIDATE THE ENVIRONMENT, CLEAN THE TARGET CONTAINER IF NEEDED
----------------------------------------------------------------------------- #>

Write-Heading "DIRECT Framework Create Container Script $FrameworkVersion`nDeployment Starting"

Write-Info "Container Image Name: $ImageName"
Write-Info "Master Connection String: $MasterConnectionString"

# Prerequisites:
# - Podman must be installed and running, with direct access to the Podman CLI
# - The Podman service must be up and running and working

# Check Podman, install if not available
if (-not (Get-Command podman -ErrorAction SilentlyContinue)) {
  Write-Warn "Podman is not installed. Please allow install of Podman"
  try {
    # Run the winget installations for Podman
    Start-Process "winget install RedHat.Podman" -Wait
    Start-Process "winget install RedHat.Podman-Desktop" -Wait
    Write-Result "Podman installation seems complete."
    Write-Info "Please complete and validate Podman configuration and restart the script." -ForegroundColor Blue
  }
  catch {
    Write-Error "Installation Failure:`n$_"
    Write-Error "Failed to install Podman. Please install it manually."
    Write-Info "More information on installing Podman: https://podman.io/getting-started/installation"
    Write-Info "If you have installed Podman, please ensure it is running and accessible."
  }
  Write-Error "Exiting: Please install/configure Podman and restart the script."
  exit 1
}
else {
  $PodmanVersion = podman --version
  Write-Result "Podman seems to be installed and available."
  Write-Host "Podman version: $PodmanVersion"
  $SuccessMessages += "Check: Podman installed and running: $PodmanVersion"
}

# Check if a Podman machine is running
$MachineStatus = podman machine list | Select-String "Running"

if (-not $MachineStatus) {
  Write-Warn "Podman machine is not running. Starting it now..."

  try {
    podman machine start
  }
  catch {
    Write-Error "Exiting: Failed to start Podman machine:`n$_"
    Exit 1
  }

  # Wait for the machine to start
  $MachineStarted = Invoke-WithRetry -ScriptBlock {
    $MachineStatus = podman machine list | Select-String "Running"
    if ($MachineStatus) {
      Write-Result "Podman machine is now running."
      return $true
    }
    else {
      $CurrentAttempt = $script:attempt ?? 1
      Write-Warn "Wait period ${CurrentAttempt}/${MaxAttempts}: Waiting for Podman machine to start..."
      return $false
    }
  } -MaxAttempts $MaxAttempts -NapLength $NapLength

  if (-not $MachineStarted) {
    Write-Error "Exiting: Failed to find a running Podman machine. Please review."
    Exit 1
  }
}
$SuccessMessages += "Check: Podman machine running"

# With a machine running, check if the container (by name) already exists.
# This script creates the container, so if it already exists we must remove it.
$ExistingContainer = podman ps -a --filter "name=$ContainerName" --format "{{.Names}}"

if ($ExistingContainer -and -not $AutoPurge) {
  # check if we should remove the existing container
  Write-Warn "Container '$ContainerName' already exists."
  $Remove = Read-Host "Do you want to remove the existing container? (y/n)"
}

if (-not $ExistingContainer) {
  # No existing container: just continue, nothing to remove.
  Write-Info "No existing container named '$ContainerName' found. Continuing..."
}
elseif ($AutoPurge -or ($Remove -ieq 'y')) {
  # Container exists *and* we are allowed to remove it
  Write-Warn "Removing existing container '$ContainerName'"

  $rmOutput = podman rm -f $ContainerName 2>&1
  if ($LASTEXITCODE -ne 0) {
    Write-Error "Exiting: Failed to remove container '$ContainerName'.`nPodman output:`n$rmOutput"
    Exit 1
  }

  Write-Result "Container '$ContainerName' removed."
}
else {
  # Container exists, but we are not removing it
  Write-Warn "Container '$ContainerName' already exists."
  Write-Info "Please remove it, or configure a different name to use."
  Write-Error "Exiting: container exists, please remove it before running script."
  Exit 1
}


<# =============================================================================
CREATE THE SQL SERVER CONTAINER IN PODMAN
----------------------------------------------------------------------------- #>

try {
  $ContainerId = podman run -d --name $ContainerName `
    -e "ACCEPT_EULA=Y" `
    -e "MSSQL_SA_PASSWORD=$SqlPassword" `
    -e "MSSQL_AGENT_ENABLED=true" `
    -p 0.0.0.0:$PortMapping $ImageName

  # check if the container was created successfully
  if ($LASTEXITCODE -ne 0 -or $ContainerId -match "Error|failed|unable") {
    Write-Error "Exiting: Podman container creation failed:`n$containerId"
    Exit 1
  }
  else {
    Write-Result "Container '$ContainerName' created successfully"
    Write-Result "Container id: '$ContainerId'"
    $SuccessMessages += "Task: Container '$ContainerName' created with id:"
    $SuccessMessages += "      '$ContainerId'"
  }
}
catch {
  Write-Error "Exiting: Failed to create container '$ContainerName':`n$_"
  Exit 1
}

# Wait for the container to start/up
$ContainerUp = Invoke-WithRetry -ScriptBlock {
  $ContainerStatus = podman ps --filter "name=$ContainerName" --format "{{.Status}}"

  if ($ContainerStatus) {
    Write-Result "Container '$ContainerName' is running."
    return $true
  }
  else {
    $CurrentAttempt = $script:attempt ?? 1
    Write-Info "Wait period ${CurrentAttempt}/${MaxAttempts}: Waiting for container..."
    return $false
  }
} -MaxAttempts $MaxAttempts -NapLength $NapLength

if (-not $ContainerUp) {
  Write-Error "Exiting: Failed to start the container. Please review."
  Exit 1
}
$SuccessMessages += "Check: Container is up and running."

# Example command, display the container logs
# Write-Host "Container '$containerName' logs start:" -ForegroundColor Cyan
# podman logs $containerName
# Write-Host "Container '$containerName' logs end" -ForegroundColor Cyan

# Display the SQL Server connection information
Write-Info "You can connect to SQL Server using the following connection string:"
Write-Info "$MasterConnectionString"

# Reminder to change the sa use password as needed if needed
Write-Warn "Change the sa user password as needed to meet security requirements."

<# =============================================================================
WAIT UNTIL THE SQL SERVER INSTANCE INSIDE THE CONTAINER IS UP AND READY TO GO
----------------------------------------------------------------------------- #>

Write-Info "Waiting for server to start, running SQL Server connection tests..."
$SqlServerStarted = Invoke-WithRetry -ScriptBlock {
  try {
    $SqlConnection = New-Object System.Data.SqlClient.SqlConnection($MasterConnectionString)
    $SqlConnection.Open()
    Write-Result "SQL Server connection test successful."
    $SqlConnection.Close()
    return $true
  }
  catch {
    Write-Result "SQL Server connection test failed. Retrying in $NapLength seconds..."
    return $false
  }
} -MaxAttempts $MaxAttempts -NapLength $NapLength

if (-not $SqlServerStarted) {
  Write-Error "Exiting: SQL Server connection test failed after $MaxAttempts attempts."
  Exit 1
}

Write-Success "Container and SQL Server is up and running.`nReady for deployment or usage."
$SuccessMessages += "Check: SQL Server service is running."

<# =============================================================================
DEPLOY TESTING FRAMEWORK DACPAC
----------------------------------------------------------------------------- #>

if ($AutoDeploy) {
  $Result = Deploy-Dacpac -DacpacPath $TestingFrameworkDacpacFileName `
    -ConnectionString $MasterConnectionString `
    -Description "Testing Framework DACPAC" `
    -DatabaseName $TestingFrameworkDatabaseName `
    -AutoDeploy $AutoDeploy `
    -AutoPurge $AutoPurge

  if (-not $Result) {
    Write-Error "Testing Framework DACPAC deployment failed. Please review."
    $ErrorMessages += "Task: Testing Framework DACPAC deployment failed."
  }
  else {
    $SuccessMessages += "Task: Testing Framework DACPAC deployment completed."
  }
}
else {
  Write-Info "AutoDeploy is off - Skipping Testing Framework DACPAC deployment."
}

<# =============================================================================
DEPLOY DIRECT FRAMEWORK DACPAC
----------------------------------------------------------------------------- #>

if ($AutoDeploy) {
  $Result = Deploy-Dacpac -DacpacPath $DirectFrameworkDacpacFileName `
    -ConnectionString $MasterConnectionString `
    -Description "DIRECT Framework DACPAC (version: '${DirectFrameworkMoniker}')" `
    -DatabaseName $DirectFrameworkDatabaseName `
    -AutoDeploy $AutoDeploy -AutoPurge $AutoPurge

  if (-not $Result) {
    Write-Error "DIRECT Framework DACPAC deployment failed. Please review."
    $ErrorMessages += "Task: DIRECT Framework DACPAC deployment failed."
  }
  else {
    $SuccessMessages += "Task: DIRECT Framework DACPAC deployment completed."
  }
}
else {
  Write-Info "AutoDeploy is off - Skipping Direct Framework DACPAC deployment."
}

<# =============================================================================
POST-DACPAC SCRIPTING
----------------------------------------------------------------------------- #>

# Scripts that depend on SQL Agent being available
if ($AutoSqlAgentScripts) {
  $SqlScripts = @(
    "Direct_Framework/DeploymentScripts/3-PostDeployment/Queue_Job_Batch.sql",
    "Direct_Framework/DeploymentScripts/3-PostDeployment/Queue_Job_Module.sql"
  )

  foreach ($ScriptFile in $SqlScripts) {
    $Result = Invoke-Sqlcmd -SqlPath $ScriptFile -ConnectionString $MasterConnectionString
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
}
else {
  Write-Info "AutoSqlAgentScripts is off - Skipping Agent scripts deployment."
}

# Testing framework content scripts (tests)
if ($AutoTestingFrameworkScripts) {

  Write-Heading "AutoTestingFrameworkScripts is on - compiling and running tests."

  # Recompile the test scripts
  $CompileScript = Join-Path $PSScriptRoot "../Testing/Compile-Tests.ps1"

  if (Test-Path $CompileScript) {
    Write-Info "Running Compile-Tests.ps1..."
    & $CompileScript
  }
  else {
    Write-Error "Compile-Tests.ps1 not found at '$CompileScript'"
  }

  # Select all test scripts in the testing directory (the output from the previous step)
  $SqlScripts = Get-ChildItem -Path "Testing/Compiled_Tests" -Filter "test*.sql" -File | ForEach-Object {
    $_.FullName
  }

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

  # Run a final check and spool the results to the test output
  $outputDir = "Testing/TestResults"
  if (!(Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
  }

  # Test results query
  $Query = "SELECT [TEST_ID], [TEST_TIMESTAMP], [RESULT] FROM [Testing_Framework].[ut].[TEST_RESULTS];"

  # Output files for test results in different colors
  $JsonOutputPath = Join-Path $outputDir "overview-results.json"
  $MdOutputPath = Join-Path $outputDir "overview-results.md"
  $TxtOutputPath = Join-Path $outputDir "overview-results.txt"

  # Invoke-Sqlcmd -Query $Query -ConnectionString $MasterConnectionString |
  # ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8

  # Ensure SqlServer module is present and up to date (without prompts)
  # TODO: wrap in autodeploy check on the switches
  $moduleVersion = Install-SqlServerModule
  if (-not $moduleVersion) {
    Write-Error "SqlServer module not available."
    # TODO: Skip to next leg if SqlServer module is not available
  }
  Write-Result "SqlServer module ready (version $moduleVersion)."

  # Run direct query on database through SqlServer module
  # Requires: Install-Module SqlServer
  $rows = SqlServer\Invoke-Sqlcmd -ConnectionString $MasterConnectionString -Query $Query

  # $rows | Format-Table -AutoSize

  # Project SQL results to plain pscustomobject objects
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
    Write-Host "Test overview results saved to $JsonOutputPath"
  } else {
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
                  @{ Name='TEST_TIMESTAMP'; Expression = { $_.TEST_TIMESTAMP.ToString('yyyy-MM-dd HH:mm:ss') } },
                  RESULT |
    Format-Table -AutoSize |
    Out-String |
    Set-Content -Path $TxtOutputPath -Encoding UTF8
  <# ========== TXT END ========== #>

  Write-Host "Test results saved to $outputDir" -ForegroundColor Green
}
else {
  Write-Info "AutoTestingFrameworkScripts is off - testing framework scripts deployment."
}

<# =============================================================================
END OF TRIP, THANK YOU FOR COMING ALONG
----------------------------------------------------------------------------- #>

Write-Heading "Deployment Summary"
Write-Result "Framework deployment for version '$FrameworkVersion' completed."
Write-Success "Container '$ContainerName' is deployed and ready for use.`n"

Write-Info "Connection String to master:`n-->  $MasterConnectionString`n"
Write-Info "Connection String to Testing Framework:`n-->  $TestingConnectionString`n"
Write-Info "Connection String to Direct Framework:`n-->  $DirectConnectionString`n"

if ($SuccessMessages.Count -eq 0 -and $ErrorMessages.Count -eq 0) {
  Write-Info "No tasks were executed or all tasks were skipped."
}
if ($SuccessMessages.Count -gt 0) {
  Write-Heading "Successful Tasks"
  foreach ($Message in $SuccessMessages) {
    Write-Success $Message
  }
}
else {
  Write-Info "`nNo successful tasks."
}

if ($ErrorMessages.Count -gt 0) {
  Write-Heading "Failed Tasks"
  foreach ($Message in $ErrorMessages) {
    Write-Error $Message
  }
}
else {
  Write-Info "`nNo failed tasks."
}
