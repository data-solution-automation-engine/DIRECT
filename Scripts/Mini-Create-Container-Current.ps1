<# =============================================================================
Script:         DIRECT Framework Create-Container current version mini Script
Documentation:  https://github.com/data-solution-automation-engine/DIRECT
Version:        DIRECT Framework 2.1.0
--------------------------------------------------------------------------------

Creates a definition for, and spins up, a SQL Server linux container locally
in Podman including:

- Direct Framework DACPAC, current version

This is a mini, for full coverage, see Create-Container.ps1

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

$SqlVersion = "2022"
$ImageVersion = "$SqlVersion-latest"
$ContainerName = "direct-dev-mini-$SqlVersion"
$ImageBase = "mcr.microsoft.com/mssql/server"
$ImageName = "${ImageBase}:${ImageVersion}"
$SqlServerPort = 2321
$SqlPassword = "Awesome!Passw0rd"
$PortMapping = "${SqlServerPort}:1433"
$LocalAddress = "127.0.0.1"

$DirectFrameworkDatabaseName = "Direct_Framework"
$DirectFrameworkMoniker = "current"
$DirectFrameworkDacpacFileName = "Releases.Direct_Framework/$DirectFrameworkMoniker/db/Direct_Framework.dacpac"

# The connection string to the system database "master"
$MasterConnectionString =
"Server=$LocalAddress,${SqlServerPort};Initial Catalog=master;User Id=sa;Password=${SqlPassword};TrustServerCertificate=true;"

# The connection string to the Direct Framework database
$DirectConnectionString =
"Server=$LocalAddress,${SqlServerPort};Initial Catalog=${DirectFrameworkDatabaseName};User Id=sa;Password=${SqlPassword};TrustServerCertificate=true;"

# Nap controls, increase or decrease as needed for the current host
$MaxAttempts = 10
$NapLength = 5 # seconds

<# -----------------------------------------------------------------------------
END - Define script behavior and config - change or refine as needed above.
============================================================================= #>


<# =============================================================================
FOLD IN HELPERS AND UTILITIES
Load required utility functions and helpers from the Utils folder
----------------------------------------------------------------------------- #>

. "Scripts/Utils/ConvertTo-MarkdownTable.ps1"
. "Scripts/Utils/Deploy-Dacpac.ps1"
. "Scripts/Utils/Get-DacpacVersion.ps1"
. "Scripts/Utils/Install-SqlServerModule.ps1"
. "Scripts/Utils/Invoke-Sqlcmd.ps1"
. "Scripts/Utils/Invoke-WithRetry.ps1"
. "Scripts/Utils/Test-DotnetTool.ps1"
. "Scripts/Utils/Test-PortInUse.ps1"
. "Scripts/Utils/Write-Utils.ps1"

<# =============================================================================
CHECK AND VALIDATE THE ENVIRONMENT, CLEAN THE TARGET CONTAINER IF NEEDED
----------------------------------------------------------------------------- #>

Write-Heading "DIRECT Framework Create Container Script $FrameworkVersion`nDeployment Starting"

$ExistingContainer = podman ps -a --filter "name=$ContainerName" --format "{{.Names}}"

if ($ExistingContainer) {
  try {
    podman rm -f $ContainerName
    Write-Result "Container '$ContainerName' removed."
  }
  catch {
    Write-Error "Exiting: Failed to remove container '$ContainerName':`n$_"
    Exit 1
  }
}

<# =============================================================================
CREATE THE SQL SERVER CONTAINER IN PODMAN
----------------------------------------------------------------------------- #>

$ContainerId = podman run -d --name $ContainerName `
  -e "ACCEPT_EULA=Y" `
  -e "MSSQL_SA_PASSWORD=$SqlPassword" `
  -e "MSSQL_AGENT_ENABLED=true" `
  -p 0.0.0.0:$PortMapping $ImageName

# Wait for the container to start/up
Invoke-WithRetry -ScriptBlock {
  $ContainerStatus = podman ps --filter "name=$ContainerName" --format "{{.Status}}"

  if ($ContainerStatus) {
    Write-Result "Container '$ContainerName' is running."
    return $true
  }
  else {
    return $false
  }
} -MaxAttempts $MaxAttempts -NapLength $NapLength

<# =============================================================================
WAIT UNTIL THE SQL SERVER INSTANCE INSIDE THE CONTAINER IS UP AND READY TO GO
----------------------------------------------------------------------------- #>

Invoke-WithRetry -ScriptBlock {
  try {
    $SqlConnection = New-Object System.Data.SqlClient.SqlConnection($MasterConnectionString)
    $SqlConnection.Open()
    Write-Result "SQL Server connection test successful."
    $SqlConnection.Close()
    return $true
  }
  catch {
    return $false
  }
  return $false
} -MaxAttempts $MaxAttempts -NapLength $NapLength

<# =============================================================================
DEPLOY DIRECT FRAMEWORK DACPAC
----------------------------------------------------------------------------- #>

Deploy-Dacpac -DacpacPath $DirectFrameworkDacpacFileName `
  -ConnectionString $MasterConnectionString `
  -Description "DIRECT Framework DACPAC (version: '${DirectFrameworkMoniker}')" `
  -DatabaseName $DirectFrameworkDatabaseName `
  -AutoDeploy $true -AutoPurge $true
