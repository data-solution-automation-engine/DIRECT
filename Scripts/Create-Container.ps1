<# =============================================================================
DIRECT Framework Create-Container Script 2.1.0
https://github.com/data-solution-automation-engine/DIRECT
--------------------------------------------------------------------------------

Creates a definition for, and spins up, a SQL Server container locally
in Podman including:

- Direct Framework DACPAC
- Testing Framework DACPAC (for regression tests)

This is a full journey from start to finish for getting a
local database environment for development and tests up and running

Prerequisites:
- Podman must be installed and running, with direct access to the Podman CLI
- The Podman service must be up and running and working
- The script expects PowerShell 7.5 or higher
- The script expects to run from its repo folder,
  or with cwd set to repo root
- For dacpac deployment, the script expects the dacpac for current/next
  versions of the DIRECT Framework to be built and be available
- For dacpac deployment, the script expects the Testing Framework dacpac
  to be available
- local dotnet tools must be restored/installed and available
- Modern sqlcmd must be installed and available in the PATH

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
$versionFile = '.direct-version'
if (Test-Path $versionFile) {
    $FrameworkVersion = Get-Content $versionFile | Select-Object -First 1
    $FrameworkVersion = $FrameworkVersion.Trim()
}
if ([string]::IsNullOrWhiteSpace($FrameworkVersion)) {
    Write-Error "DIRECT Framework Version not found."
    $FrameworkVersion = "0.0.0"
}

# AutoPurge: If true, the script will force remove existing container/database
$AutoPurge = $true

# AutoSqlAgentScripts: If true, the script will include SQL that is dependent
# on SQL Agent being available, which excludes Azure instances (on-premise or
# managed-instance only)
$AutoSqlAgentScripts = $true

# AutoDeploy: If true, the script will automatically deploy Testing Framework
# and Direct Framework DACPACs to the container
$AutoDeploy = $true

# sqlVersion: The numeric generation/version of SQL Server to use
# This must match an available image name.
# Direct Framework is currently mainly tested against SQL Server 2022
# but is expected to work across all currently supported versions, including
# non-on-premises versions like Azure SQL Database and Fabric SQL.
# Once SQL Server 2025 is in full preview, DIRECT will be updated to that version.
# More information:
# https://learn.microsoft.com/en-us/sql/linux/quickstart-install-connect-docker
# https://mcr.microsoft.com/artifact/mar/mssql/server/about
$sqlVersion = "2022"

# imageVersion: container image version to use
$imageVersion = "$sqlVersion-latest"

# containerName: name of the container to create locally in Podman
$containerName = "direct-dev-$sqlVersion"

# imageBase: identifying Microsoft's registry for SQL Server images
# This is the base address to Microsoft's container images for SQL Server
$imageBase = "mcr.microsoft.com/mssql/server"

# imageName: Full container image name to pull
$imageName = "${imageBase}:${imageVersion}"

# sqlServerPort: The port to use for connections from your host
# to the SQL Server instance in the container
# Change this if something is already using this port on the host
$sqlServerPort = 1433

# sqlPassword: the 'sa' user password for the SQL Server
# This must match the default password policy for the active SQL Server version
$sqlPassword = "Awesome!Passw0rd"

# portMapping: Define the port mapping for the SQL Server container
# This maps the SQL Server port in the container to the host port
$portMapping = "${sqlServerPort}:1433"

# localAddress: a valid address to the exposed container:
# localhost, 127.0.0.1 (v4), or ::1 (v6) etc
# a host might map "localhost" to ::1 (IPv6) by default
# which doesn't automatically work in Podman,
# so this defines and uses the v4 loopback ip as the default
$localAddress = "127.0.0.1"

# Details for deployment of the Testing Framework DacPac
$testingFrameworkDatabaseName = "Testing_Framework"
$testingFrameworkDacpacFileName = "Reference_Dacpacs/Testing_Framework.dacpac"

# Details for deployment of the Direct Framework DacPac
$directFrameworkDatabaseName = "Direct_Framework"
$directFrameworkMoniker = "next" # "current"/"next"
$directFrameworkDacpacFileName = "Releases.Direct_Framework/$directFrameworkMoniker/db/Direct_Framework.dacpac"

# Define valid connection strings for SQL Server

# The connection string to the system database "master"
$masterConnectionString =
  "Server=$localAddress,${sqlServerPort};Initial Catalog=master;User Id=sa;Password=${sqlPassword};TrustServerCertificate=true;"

# The connection string to the Testing Framework database
$testingConnectionString =
  "Server=$localAddress,${sqlServerPort};Initial Catalog=${testingFrameworkDatabaseName};User Id=sa;Password=${sqlPassword};TrustServerCertificate=true;"

# The connection string to the Direct Framework database
$directConnectionString =
  "Server=$localAddress,${sqlServerPort};Initial Catalog=${directFrameworkDatabaseName};User Id=sa;Password=${sqlPassword};TrustServerCertificate=true;"

# Nap controls, increase or decrease as needed for the current host
$maxAttempts = 10
$napLength = 5 # seconds

<# -----------------------------------------------------------------------------
END - Define script behavior and config - change or refine as needed above.
============================================================================= #>

# SETUP - Make sure we run in modern pwsh
if (
  ($PSVersionTable.PSVersion.Major -lt 7) -or
  ($PSVersionTable.PSVersion.Major -eq 7 -and $PSVersionTable.PSVersion.Minor -lt 5)
) {
  Write-Error "Exiting: this script expects PowerShell 7.5 or higher."
  Write-Host "Run 'winget install Microsoft.Powershell --source winget'."
  Write-Host "or download the latest version of PowerShell from https://aka.ms/powershell"
  Exit 1
}

<# =============================================================================
FOLD IN HELPERS AND UTILITIES
Load required utility functions and helpers from the Utils folder
----------------------------------------------------------------------------- #>

. "Scripts/Utils/Deploy-Dacpac.ps1"
. "Scripts/Utils/Get-DacpacVersion.ps1"
. "Scripts/Utils/Invoke-SqlCmd.ps1"
. "Scripts/Utils/Invoke-WithRetry.ps1"
. "Scripts/Utils/Test-DotnetTool.ps1"
. "Scripts/Utils/Test-PortInUse.ps1"
. "Scripts/Utils/Write-Utils.ps1"

<# =============================================================================
CHECK AND VALIDATE THE ENVIRONMENT, CLEAN THE TARGET CONTAINER IF NEEDED
----------------------------------------------------------------------------- #>

Write-Heading -Heading "DIRECT Framework Create Container Script $FrameworkVersion`nDeployment Starting"

Write-Host "Container Image Name: $imageName" -ForegroundColor Cyan
Write-Host "Master Connection String: $masterConnectionString" -ForegroundColor Cyan

# Prerequisites:
# - Podman must be installed and running, with direct access to the Podman CLI
# - The Podman service must be up and running and working

# Check Podman, install if not available
if (-not (Get-Command podman -ErrorAction SilentlyContinue)) {
  Write-Warning "Podman is not installed. Please allow install of Podman"
  try {
    # Run the winget installations for Podman
    Start-Process "winget install RedHat.Podman" -Wait
    Start-Process "winget install RedHat.Podman-Desktop" -Wait
    Write-Host "Podman installation seems complete." -ForegroundColor Green
    Write-Host "Please complete and validate Podman configuration and restart the script." -ForegroundColor Blue
  }
  catch {
    Write-Error "Installation Failure:`n$_"

    Write-Error "Failed to install Podman. Please install it manually."
    Write-Host "More information on installing Podman: https://podman.io/getting-started/installation"
    Write-Host "If you have installed Podman, please ensure it is running and accessible."
  }
  Write-Error "Exiting: Please configure Podman and restart the script."
  exit 1
}
else {
  Write-Host "Podman seems to be installed and available." -ForegroundColor Green
}

# Check if the Podman machine is running
$machineStatus = podman machine list | Select-String "Running"

if (-not $machineStatus) {
  Write-Host "Podman machine is not running. Starting it now..." -ForegroundColor Yellow

  try {
    podman machine start
  }
  catch {
    Write-Error "Exiting: Failed to start Podman machine:`n$_"
    Exit 1
  }

  # Wait for the machine to start
  $machineStarted = Invoke-WithRetry -ScriptBlock {
    $machineStatus = podman machine list | Select-String "Running"
    if ($machineStatus) {
      Write-Host "Podman machine is now running." -ForegroundColor Green
      return $true
    }
    else {
      $currentAttempt = $script:attempt ?? 1
      Write-Host "Wait period ${currentAttempt}/${maxAttempts}: Waiting for Podman machine to start..." -ForegroundColor Yellow
      return $false
    }
  } -MaxAttempts $maxAttempts -NapLength $napLength

  if (-not $machineStarted) {
    Write-Error "Exiting: Failed to find a running Podman machine. Please review."
    Exit 1
  }
}

# Check if the container already exists
$existingContainer = podman ps -a --filter "name=$containerName" --format "{{.Names}}"
if ($existingContainer) {
  if ($AutoPurge) {
      Write-Host "Container '$containerName' already exists. Removing it..." -ForegroundColor Yellow
      try {
        podman rm -f $containerName
        Write-Host "Container '$containerName' removed." -ForegroundColor Green
      }
      catch {
        Write-Error "Exiting: Failed to remove container '$containerName':`n$_"
        Exit 1
      }
    }
    else {
      Write-Host "Container '$containerName' already exists." -ForegroundColor Red
      $remove = Read-Host "Do you want to remove the existing container? (y/n)"
      if ($remove -ieq 'y') {
        try {
          podman rm -f $containerName
          Write-Host "Container '$containerName' removed." -ForegroundColor Yellow
        }
        catch {
          Write-Error "Exiting: Failed to remove container '$containerName':`n$_"
          Exit 1
        }
      }
      else {
        Write-Error "Exiting: Please remove the container manually before running script."
        Exit 1
      }
    }
}

<# =============================================================================
CREATE SQL SERVER CONTAINER IN PODMAN
----------------------------------------------------------------------------- #>

try {
  podman run -d --name $containerName `
    -e "ACCEPT_EULA=Y" `
    -e "MSSQL_SA_PASSWORD=$sqlPassword" `
    -e "MSSQL_AGENT_ENABLED=true" `
    -p 0.0.0.0:$portMapping $imageName

  Write-Success "Container '$containerName' created successfully."
}
catch {
  Write-Error "Exiting: Failed to create container '$containerName':`n$_"
  Exit 1
}

# Check if the container is running
$containerStatus = podman ps --filter "name=$containerName" --format "{{.Status}}"
if ($containerStatus -match "Up") {
  Write-Host "Container '$containerName' is running." -ForegroundColor Green
}
else {
  Write-Host "Container '$containerName' is not running." -ForegroundColor Red
}

# Display the container status
Write-Host "Container '$containerName' status: $containerStatus" -ForegroundColor Yellow

# Example command, display the container logs
# Write-Host "Container '$containerName' logs start:" -ForegroundColor Cyan
# podman logs $containerName
# Write-Host "Container '$containerName' logs end" -ForegroundColor Cyan

# Display the SQL Server connection information
Write-Host "You can connect to SQL Server using the following connection string:" -ForegroundColor Blue
Write-Host "$masterConnectionString" -ForegroundColor Blue

# Reminder to change the sa use password as needed if needed
Write-Host "Change the sa user password as needed to meet security requirements." -ForegroundColor Yellow

<# =============================================================================
WAIT UNTIL THE SQL SERVER IS UP AND READY TO GO
----------------------------------------------------------------------------- #>

Write-Host "Waiting for server to start, running SQL Server connection tests..." -ForegroundColor Cyan
$sqlServerStarted = Invoke-WithRetry -ScriptBlock {
  try {
    $sqlConnection = New-Object System.Data.SqlClient.SqlConnection($masterConnectionString)
    $sqlConnection.Open()
    Write-Host "SQL Server connection test successful." -ForegroundColor Green
    $sqlConnection.Close()
    return $true
  }
  catch {
    Write-Host "SQL Server connection test failed. Retrying in $napLength seconds..." -ForegroundColor Yellow
    return $false
  }
} -MaxAttempts $maxAttempts -NapLength $napLength

if (-not $sqlServerStarted) {
  Write-Error "Exiting: SQL Server connection test failed after $maxAttempts attempts."
  Exit 1
}

Write-Success "SQL Server is up and running. Ready for deployment or usage."

<# =============================================================================
DEPLOY TESTING FRAMEWORK DACPAC
----------------------------------------------------------------------------- #>

if ($AutoDeploy) {
  $result = Deploy-Dacpac -DacpacPath $testingFrameworkDacpacFileName `
    -ConnectionString $masterConnectionString `
    -Description "Testing Framework DACPAC" `
    -DatabaseName $testingFrameworkDatabaseName `
    -AutoDeploy $AutoDeploy `
    -AutoPurge $autoPurge

  if (-not $result) {
    Write-Error "Testing Framework DACPAC deployment failed. Please review."
  }
}
else {
  Write-Host "AutoDeploy is off - Skipping Testing Framework deployment."
}

<# =============================================================================
DEPLOY DIRECT FRAMEWORK DACPAC
----------------------------------------------------------------------------- #>

if ($AutoDeploy) {
  $result = Deploy-Dacpac -DacpacPath $directFrameworkDacpacFileName `
    -ConnectionString $masterConnectionString `
    -Description "Direct Framework DACPAC ('${directFrameworkVersion}')" `
    -DatabaseName $directFrameworkDatabaseName `
    -AutoDeploy $AutoDeploy -AutoPurge $autoPurge

  if (-not $result) {
    Write-Error "Direct Framework DACPAC deployment failed. Please review."
  }
}
else {
  Write-Host "AutoDeploy is off - Skipping Direct Framework deployment."
}

<# =============================================================================
POST-DACPAC SCRIPTING
----------------------------------------------------------------------------- #>

if ($AutoSqlAgentScripts) {
  $scriptRoot = Split-Path $PSScriptRoot -Parent

  $sqlScripts = @(
    "Direct_Framework\DeploymentScripts\3-PostDeployment\Queue_Job_Batch.sql",
    "Direct_Framework\DeploymentScripts\3-PostDeployment\Queue_Job_Module.sql"
  )

  foreach ($relativePath in $sqlScripts) {
    $sqlScriptPath = Join-Path $scriptRoot $relativePath

    if (Test-Path $sqlScriptPath) {
      $result = Invoke-SqlCmd -SqlPath $sqlScriptPath -ConnectionString $masterConnectionString

      if ($result) {
        Write-Host "Successfully executed SQL script: $sqlScriptPath"
      }
      else {
        Write-Error "Script execution failed for: $sqlScriptPath"
        break
      }
    }
    else {
      Write-Error "SQL script not found at: $sqlScriptPath"
      break
    }
  }
}
else {
  Write-Host "AutoSqlAgentScripts is off - Skipping Direct Framework post-deployment scripting."
}


<# =============================================================================
END OF TRIP, THANK YOU FOR COMING ALONG
----------------------------------------------------------------------------- #>

Write-Heading "Deployment Summary"
Write-Success "Framework deployment for version '$FrameworkVersion' completed."
Write-Success "Container '$containerName' is deployed and ready for use.`n"

Write-Host "Connection String to master:`n-->  $masterConnectionString`n" -ForegroundColor Cyan
Write-Host "Connection String to Testing Framework:`n-->  $testingConnectionString`n" -ForegroundColor Cyan
Write-Host "Connection String to Direct Framework:`n-->  $directConnectionString`n" -ForegroundColor Cyan
