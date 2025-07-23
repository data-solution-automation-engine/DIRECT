# ==============================================================================
# DIRECT Framework Create Container Script 2.1.0
# https://github.com/data-solution-automation-engine/DIRECT
# ------------------------------------------------------------------------------
# Creates a definition for, and spins up, a SQL Server container locally
# in Podman including:
# - Direct Framework DACPAC
# - Testing Framework DACPAC (for regression tests)
#
# This is a full journey from start to finish for getting a
# local database environment for development and tests up and running
# ------------------------------------------------------------------------------
# ==============================================================================

# ==============================================================================
# START - Define script behavior and config - change or refine as needed below.
# ------------------------------------------------------------------------------

# Changes are only expected within this block, everything else is automated and
# controlled by the definitions below.

# autoPurge: If true, the script will force remove existing container/database
$AutoPurge = $true

# autoDeploy: If true, the script will automatically deploy Testing Framework
# and Direct Framework DACPACs to the container
$AutoDeploy = $true

# sqlVersion: The numeric generation/version of SQL Server to use
# Only certain versions are supported/tested (e.g., 2019, 2022).
# This must match an available image name.
# Direct Framework is currently mainly tested against SQL Server 2022.
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

# sqlPassword: the sa user password for the SQL Server
# This must match the default password policy for the active SQL Server version
$sqlPassword = "Awesome!Passw0rd"

# portMapping: Define the port mapping for the SQL Server container
# This maps the SQL Server port in the container to the host port
$portMapping = "${sqlServerPort}:1433"

# localAddress: a valid address to the exposed container:
# localhost, 127.0.0.1 (v4), or ::1 (v6) etc
# a host might map "localhost" to ::1 (IPv6) by default
# which doesn't automatically work in Podman,
# so this defines the v4 loopback ip address as the default
$localAddress = "127.0.0.1"

# Details for deployment of the Testing Framework DacPac
$testingFrameworkDatabaseName = "Testing_Framework"
$testingFrameworkDacpacFileName = "Reference_Dacpacs/Testing_Framework.dacpac"

# Details for deployment of the Direct Framework DacPac
$directFrameworkDatabaseName = "Direct_Framework"
$directFrameworkVersion = "next" # "current"/"next"
$directFrameworkDacpacFileName = "Releases.Direct_Framework/$directFrameworkVersion/db/Direct_Framework.dacpac"

# Define valid connection strings for SQL Server

# The connection string for the system database "master"
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

# ------------------------------------------------------------------------------
# END - Define script behavior and config - change or refine as needed above.
# ==============================================================================


# Set the working directory to the folder containing this script
Set-Location -Path $PSScriptRoot

# Make sure we run in modern pwsh
if (
  ($PSVersionTable.PSVersion.Major -lt 7) -or
  ($PSVersionTable.PSVersion.Major -eq 7 -and $PSVersionTable.PSVersion.Minor -lt 5)
) {
  Write-Error "Exiting: this script expects PowerShell 7.5 or higher."
  Write-Host "Run 'winget install Microsoft.Powershell --source winget'."
  Write-Host "or download the latest version of PowerShell from https://aka.ms/powershell"
  Exit 1
}

# ==============================================================================
# Helpers and Utilities
# ------------------------------------------------------------------------------

<#
.SYNOPSIS
  Executes a script block with retry logic.
.DESCRIPTION
  Runs a script block up to a maximum number of attempts, waiting between attempts, and returns $true if successful.
.PARAMETER ScriptBlock
  The script block to execute. Should return $true on success, $false or throw on failure.
.PARAMETER MaxAttempts
  Maximum number of attempts (default: 10).
.PARAMETER NapLength
  Seconds to wait between attempts (default: 5).
.EXAMPLE
  Invoke-WithRetry -ScriptBlock { Test-Connection ... } -MaxAttempts 5 -NapLength 2
.NOTES
  Returns $true if the script block succeeds, otherwise $false.
#>
function Invoke-WithRetry {
  param(
    [Parameter(Mandatory = $true)][ScriptBlock]$ScriptBlock,
    [int]$MaxAttempts = 10,
    [int]$NapLength = 5
  )
  $attempt = 1
  while ($attempt -le $MaxAttempts) {
    try {
      if (& $ScriptBlock) {
        return $true
      }
    }
    catch {
      # Ignore, will retry
    }
    if ($attempt -lt $MaxAttempts) {
      Start-Sleep -Seconds $NapLength
    }
    $attempt++
  }
  return $false
}

<#
.SYNOPSIS
  Checks for the existence and usability of a dotnet tool (local or global).
.DESCRIPTION
  Checks if the specified dotnet tool is installed locally or globally, attempts to restore if missing, and returns a hashtable with tool existence and command string.
.PARAMETER ToolName
  The name of the dotnet tool to check (e.g., 'sqlpackage').
.EXAMPLE
  $tool = Test-Tool -ToolName "sqlpackage"
.NOTES
  Returns a hashtable: @{ Exists = $true/$false; Command = "..." }
#>
function Test-Tool {
  param(
    [Parameter(Mandatory = $true)][string]$ToolName
  )

  $toolExists = $false
  $toolCommand = ""

  # check for local or global tool
  $localTools = dotnet tool list --local
  if ($localTools -match $ToolName) {
    Write-Host "Local tool '$ToolName' is installed. Testing version:"
    # Try running the tool to verify it's functional
    $localToolVersion = dotnet tool run $ToolName -version
    if ($LASTEXITCODE -eq 0) {
      $toolExists = $true
      $toolCommand = "dotnet tool run $ToolName"

      Write-Host "'$ToolName' is ready to use." -ForegroundColor Green
      Write-Host "Tool version: $localToolVersion"
    }
    else {
      Write-Warning "Local version of '$ToolName' failed to run."
    }
  }
  if (-not $toolExists) {
    Write-Host "Local tool '$ToolName' is not available. Attempting restore..."
    # Restore the local dotnet tools as defined in `.config/dotnet-tools.json`
    try {
      dotnet tool restore
      Write-Host "Local dotnet tools restored." -ForegroundColor Green
      dotnet tool run $ToolName -version
      if ($LASTEXITCODE -eq 0) {
        $toolExists = $true
        $toolCommand = "dotnet tool run $ToolName"
        Write-Host "'$ToolName' is ready to use." -ForegroundColor Green
      }
      else {
        Write-Warning "Local version of '$ToolName' still failed to run."
      }

    }
    catch {
      Write-Error "Failed to restore local tools:`n$_"
    }
  }

  if (-not $toolExists) {
    Write-Warning "Local tool discovery of '$ToolName' failed. Going global..."

    # Check for global installation of tool
    $globalTools = dotnet tool list --global
    if ($globalTools -match $ToolName) {
      Write-Host "Global tool '$ToolName' is installed. Testing version."
      # Try running the tool to verify it's functional
      $globalToolVersion = & $ToolName -version
      if ($LASTEXITCODE -eq 0) {
        Write-Host "Global '$ToolName' is ready to use." -ForegroundColor Green
        Write-Host "version: $globalToolVersion"
        $toolExists = $true
        $toolCommand = $ToolName
      }
      else {
        Write-Warning "Global '$ToolName' failed to run."
      }
    }
  }

  if (-not $toolExists) {
    Write-Error "Tool '$toolName' could not be found. Please install/repair, validate and resolve any issues."
    return @{
      Exists  = $toolExists
      Command = ""
    }
  }

  return @{
    Exists  = $toolExists
    Command = $toolCommand
  }
}

<#
.SYNOPSIS
  Writes a separator line to the host.
.DESCRIPTION
  Outputs a line of repeated separator characters in a specified color, useful for visual separation in script output.
.PARAMETER Separator
  The character to repeat (default: '=').
.PARAMETER Length
  The number of times to repeat the separator (default: 80).
.PARAMETER Color
  The color to use for the line (default: 'Cyan').
.EXAMPLE
  Write-SeparatorLine -Separator '-' -Length 60 -Color 'Yellow'
#>
function Write-SeparatorLine {
  param(
    [string]$Separator = "=",
    [int]$Length = 80,
    [string]$Color = "Cyan"
  )
  Write-Host ($Separator * $Length) -ForegroundColor $Color
}

<#
.SYNOPSIS
  Writes a formatted heading to the host.
.DESCRIPTION
  Outputs a heading surrounded by separator lines for emphasis.
.PARAMETER Heading
  The heading text to display.
.PARAMETER Color
  The color to use for the heading and lines (default: 'Cyan').
.EXAMPLE
  Write-Heading -Heading "Deployment Started" -Color 'Magenta'
#>
function Write-Heading {
  param(
    [string]$Heading = "",
    [string]$Color = "Magenta"
  )
  Write-Host "`n"
  Write-SeparatorLine -Separator "=" -Length 80 -Color $Color
  Write-Host $Heading -ForegroundColor $Color
  Write-SeparatorLine -Separator "=" -Length 80 -Color $Color
  Write-Host ""
}

<#
.SYNOPSIS
  Writes a bold green success message to the host.
.DESCRIPTION
  Outputs a success message in bold green text,
  useful for indicating successful operations.
.PARAMETER Message
  The message to display (default: "Success").
.EXAMPLE
  Write-Success -Message "Deployment completed successfully."
.NOTES
  Uses ANSI escape codes for formatting. Write-Host and -ForegroundColor
  doesn't do bold prints at the moment
#>
function Write-Success {
  param(
    [string]$Message = "Success"
  )
  # Green + bold ansi codes to output
  # Note: uses output and ansi to support bold
  Write-Output "`e[32m`e[1m$Message`e[0m"
}

<#
.SYNOPSIS
  Extracts the version from a DACPAC file.
.DESCRIPTION
  Unzips the DACPAC file, reads the model.xml, and returns the version property if present.
.PARAMETER DacpacPath
  The path to the DACPAC file, relative to the script file location.
.EXAMPLE
  $version = Get-DacpacVersion -DacpacPath "./db/Direct_Framework.dacpac"
.NOTES
  Returns the version string or $null if not found.
#>
function Get-DacpacVersion {
  param([string]$DacpacPath)

  if (-not (Test-Path $DacpacPath)) {
    Write-Error "DACPAC file not found: $DacpacPath"
    return $null
  }

  $tempDir = [System.IO.Path]::GetTempPath() + [System.IO.Path]::GetRandomFileName()
  New-Item -ItemType Directory -Path $tempDir | Out-Null
  try {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($DacpacPath, $tempDir)
    $modelXml = Join-Path $tempDir 'model.xml'
    if (Test-Path $modelXml) {
      $xml = [xml](Get-Content $modelXml)
      $versionNode = $xml.Model.Property | Where-Object { $_.Name -eq 'Version' }
      if ($versionNode) {
        return $versionNode.Value
      }
    }
    return $null
  }
  finally {
    Remove-Item -Recurse -Force $tempDir
  }
}

<#
.SYNOPSIS
  Checks if a TCP port is in use on the local machine.
.DESCRIPTION
  Determines if the specified port is currently in use,
  using platform-appropriate methods.
.PARAMETER Port
  The port number to check.
.EXAMPLE
  if (Test-PortInUse -Port 1433) { Write-Host "Port in use!" }
.NOTES
  Returns $true if the port is in use, otherwise $false.
#>
function Test-PortInUse {
  param(
    [Parameter(Mandatory = $true)][string]$LocalAddress,
    [Parameter(Mandatory = $true)][int]$LocalPort
  )

  if ($IsWindows) {
    $result = Get-NetTCPConnection -LocalAddress $LocalAddress -LocalPort $LocalPort -ErrorAction SilentlyContinue
    return $null -ne $result
  }
  else {
    $result = netstat -tuln 2>/dev/null | Select-String "[:.]$LocalPort(\s|$|:)"
    return $result.Count -gt 0
  }
}

<#
.SYNOPSIS
  Executes a Sql File on a SQL Server database.
.DESCRIPTION
  Executes SQL file using sqlcmd against a SQL Server instance.
.PARAMETER SqlPath
  The path to the SQL file to deploy.
.PARAMETER ConnectionString
  The connection string for the SQL Server instance.
.EXAMPLE
  Invoke-SqlCmd -SqlPath "./sqlFile.sql" -ConnectionString $cs
.NOTES
  Returns $true if invocation succeeds, otherwise $false.
#>
function Invoke-SqlCmd {
  param(
    [Parameter(Mandatory = $true)][string]$SqlPath,
    [Parameter(Mandatory = $true)][string]$ConnectionString
  )
  try {

    if (-not (Test-Path $SqlPath)) {
      Write-Error "Returning: '$SqlPath' file not found"
      return $false
    }

    if (-Not $ConnectionString) {
      Write-Error "Returning: connection string not provided."
      return $false
    }

    if (-not (Get-Command sqlcmd -ErrorAction SilentlyContinue)) {
      Write-Error "The 'sqlcmd' tool can't be found. It might not be installed or not in your PATH."
      Write-Host "Please install it before running this script."
      Write-Host "Install via: 'winget install sqlcmd' on Windows."
      Write-Host "More information: https://learn.microsoft.com/en-us/sql/tools/sqlcmd/sqlcmd-utility"
      return $false
    }

    # Parse the connection string
    $builder = New-Object System.Data.SqlClient.SqlConnectionStringBuilder($ConnectionString)

    # Map to sqlcmd parameters
    $sqlcmdArgs = @(
      "-S", $builder["Server"]
      "-d", $builder["Initial Catalog"]
      "-U", $builder["User ID"]
      "-P", $builder["Password"]
      "-i", $SqlPath
    )

    # Run the sqlcmd command
    $sqlcmdOutput = & sqlcmd @sqlcmdArgs

    Write-Heading -Heading "process results"
    Write-Host ($sqlcmdOutput -join "`n")  -ForegroundColor Cyan

    if ($LASTEXITCODE -eq 0) {
      Write-Host "Deployed successfully." -ForegroundColor Green
      return $true
    }
    else {
      Write-Error "Deployment failed."
      return $false
    }
  }
  catch {
    Write-Error "An error occurred while executing the SQL file:`n$_"
    return $false
  }
}

<#
.SYNOPSIS
  Deploys a DACPAC to a SQL Server database.
.DESCRIPTION
  Handles connection, optional database drop, and calls sqlpackage to deploy
  the specified DACPAC to the target database.
.PARAMETER DacpacPath
  The path to the DACPAC file to deploy.
.PARAMETER ConnectionString
  The connection string for the SQL Server instance.
.PARAMETER DatabaseName
  The name of the database to deploy to (optional).
.PARAMETER Description
  A description for the deployment (optional).
.PARAMETER AutoDeploy
  If true, skips user prompt and deploys automatically.
.PARAMETER AutoPurge
  If true, drops the database if it exists before deploying.
.EXAMPLE
  Deploy-Dacpac -DacpacPath "./db/Direct_Framework.dacpac" -ConnectionString $cs `
  -DatabaseName "Direct_Framework" -AutoDeploy $true -AutoPurge $true
.NOTES
  Returns $true if deployment succeeds, otherwise $false.
#>
function Deploy-Dacpac {
  param(
    [Parameter(Mandatory = $true)][string]$DacpacPath,
    [Parameter(Mandatory = $true)][string]$ConnectionString,
    [string]$DatabaseName = "",
    [string]$Description = "",
    [boolean]$AutoDeploy = $false,
    [boolean]$AutoPurge = $false
  )
  try {

    if (-not (Test-Path $DacpacPath)) {
      Write-Error "Returning: '$Description' file not found at '$DacpacPath'"
      return $false
    }

    if (-Not $ConnectionString) {
      Write-Error "Returning: connection string not provided."
      return $false
    }

    $builder = New-Object System.Data.SqlClient.SqlConnectionStringBuilder($ConnectionString)

    if ([string]::IsNullOrWhiteSpace($DatabaseName)) {
      $DatabaseName = $builder["Initial Catalog"] -or $builder["Database"]
    }

    if ([string]::IsNullOrWhiteSpace($DatabaseName) -or
      ($DatabaseName -in @("master", "msdb", "tempdb", "model"))) {
      # Don't deploy if a database name is not provided, or is one of the system databases
      Write-Error "Returning: Couldn't find valid database name to use."
      Write-Error "'${DatabaseName}' was provided."
      return $false
    }

    # Check we have a sqlpackage tool to run
    $tool = Test-Tool -ToolName "sqlpackage"
    if (-not ($tool -is [hashtable] -and $tool.ContainsKey("Exists") -and $tool["Exists"])) {
      Write-Error "Returning: Tool 'sqlpackage' could not be found. Please install/repair, validate, and resolve tool access."
      return $false
    }

    $builder["Initial Catalog"] = "master"
    $MasterConnectionString = $builder.ConnectionString

    $builder["Initial Catalog"] = $DatabaseName
    $ConnectionString = $builder.ConnectionString

    $DacpacFileName = [System.IO.Path]::GetFileName($DacpacPath)
    if ([string]::IsNullOrWhiteSpace($Description)) {
      $Description = [System.IO.Path]::GetFileNameWithoutExtension($DacpacPath)
    }

    if (-not $AutoDeploy) {
      $install = Read-Host "Do you want to deploy '$Description'(${$DacpacFileName}) to database '$DatabaseName'? (y/n)"
    }
    else {
      $install = 'y'
    }
    if ($install -ine 'y') {
      Write-Host "Returning: Skipping deployment of '$Description'(${$DacpacFileName}) to database '$DatabaseName'." -ForegroundColor Yellow
      return $false
    }
  }
  catch {
    Write-Error "Returning: Failed to prepare for deployment of '$DacpacFileName' to database '$DatabaseName':`n$_"
    return $false
  }

  try {
    Write-Host "Deploying '$DacpacFileName' to database '$DatabaseName' using connection string:`n$ConnectionString" -ForegroundColor Cyan

    # Check if the target database already exists
    $checkDbQuery = "SELECT COUNT(*) FROM sys.databases WHERE name = '$DatabaseName';"
    $sqlConnection = New-Object System.Data.SqlClient.SqlConnection($MasterConnectionString)
    $sqlConnection.Open()
    $sqlCommand = $sqlConnection.CreateCommand()
    $sqlCommand.CommandText = $checkDbQuery
    $count = $sqlCommand.ExecuteScalar()

    $dbExists = $count -gt 0
    $dropSqlCmd = "ALTER DATABASE [$DatabaseName] SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE [$DatabaseName];"

    if ($dbExists -and -not $AutoPurge) {
      # If the database exists and AutoPurge is false, prompt the user
      Write-Host "Database '$DatabaseName' already exists. Overwrite, deploy to, or skip target?" -ForegroundColor Yellow
      $remove = Read-Host "Do you want to drop (o overwrite), deploy to existing (d) or skip (s)? (o/d/s)"
      if ($remove -ieq 'o') {
        Write-Host "Dropping existing database '$DatabaseName'..." -ForegroundColor Yellow
        $dropDbCmd = $sqlConnection.CreateCommand()
        $dropDbCmd.CommandText = $dropSqlCmd
        $dropDbCmd.ExecuteNonQuery()
        Write-Host "Database '$DatabaseName' dropped." -ForegroundColor Green
      }
      elseif ($remove -ieq 'd') {
        Write-Host "Deploying to existing database '$DatabaseName'..." -ForegroundColor Yellow
      }
      else {
        Write-Host "Skipping deployment to existing database '$DatabaseName'." -ForegroundColor Yellow
        $sqlConnection.Close()
        return $false
      }
    }
    if ($dbExists -and $AutoPurge) {
      # If the database exists and AutoPurge is true, drop it
      Write-Host "Database '$DatabaseName' exists. AutoPurge is on, so dropping it..." -ForegroundColor Yellow
      $dropDbCmd = $sqlConnection.CreateCommand()
      $dropDbCmd.CommandText = $dropSqlCmd
      $dropDbCmd.ExecuteNonQuery()
      Write-Host "Database '$DatabaseName' dropped." -ForegroundColor Green
    }
    $sqlConnection.Close()

    # construct a valid pwsh command expression for sqlpackage
    # which differs between local and global tools
    if ($tool.ContainsKey("Command") -and $tool["Command"]) {
      $parts = $tool["Command"] -split ' '
      $cmd = $parts[0]
      if ($parts.Length -gt 1) {
        $cmdParts = $parts[1..($parts.Length - 1)]
      }
      else {
        $cmdParts = @()
      }
    }
    else {
      Write-Error "Returning: Tool command for 'sqlpackage' not found."
      return $false
    }

    Write-Heading -Heading "Initiating DACPAC deployment."
    Write-Host "Commencing '$Description' deployment of '$DacpacFileName' to database '$DatabaseName'."

    # Call sqlpackage to deploy the DACPAC using the constructed command expression
    $sqlPackageResults = & $cmd @cmdParts `
      "/Action:Publish" `
      "/SourceFile:$DacpacPath" `
      "/TargetConnectionString:$ConnectionString" `
      "/p:BlockOnPossibleDataLoss=false"

    Write-Heading -Heading "SQLPackage process results"
    Write-Host ($sqlPackageResults -join "`n") -ForegroundColor Cyan

    if ($LASTEXITCODE -eq 0) {
      Write-Host "'$Description' deployed successfully." -ForegroundColor Green
      return $true
    }
    else {
      Write-Error "'$Description' deployment failed.`n$_"
      return $false
    }
  }
  catch {
    Write-Error "Checking or dropping database failed '$DatabaseName':`n$_"
    return $false
  }
  finally {
    if ($sqlConnection?.State -eq 'Open') {
      $sqlConnection.Close()
    }
  }
}
# End of preamble setup, functions and helpers
##############################################################################
##############################################################################

################################################################################
# Check and validate the environment, clean the target container if needed
################################################################################

Write-Heading -Heading "DIRECT Framework Create Container Script 2.1.0`nDeployment Starting"

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

# WIP, doesn't work all that well yet
# Check if the port is available or already in use,
# wait for Podman to release the port if needed
# Start-Sleep -Seconds $napLength
# if (Test-PortInUse -LocalAddress $localAddress -LocalPort $sqlServerPort) {
#   Write-Error "Port '$sqlServerPort' on '$localAddress' is already in use on the host."
#   Write-Error "Exiting: Please define an available local port."
#   exit 1
# }

################################################################################
# Create SQL Server container
################################################################################

try {
  podman run -d --name $containerName `
    -e "ACCEPT_EULA=Y" `
    -e "MSSQL_SA_PASSWORD=$sqlPassword" `
    -e "MSSQL_AGENT_ENABLED=true" `
    -p 0.0.0.0:$portMapping $imageName

  Write-Host "Container '$containerName' created successfully." -ForegroundColor Green
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
Write-Host "Container '$containerName' logs start:" -ForegroundColor Cyan
podman logs $containerName
Write-Host "Container '$containerName' logs end" -ForegroundColor Cyan

# Display the SQL Server connection information
Write-Host "You can connect to SQL Server using the following connection string:" -ForegroundColor Blue
Write-Host "$masterConnectionString" -ForegroundColor Blue

# Reminder to change the sa use password as needed if needed
Write-Host "Change the sa user password as needed to meet security requirements." -ForegroundColor Yellow

################################################################################
# WAIT UNTIL THE SQL SERVER IS UP AND READY TO GO
################################################################################

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


################################################################################
# DEPLOY TESTING FRAMEWORK DACPAC
################################################################################

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

################################################################################
# DIRECT FRAMEWORK DACPAC DEPLOYMENT
################################################################################

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

Write-Heading "Deployment Summary"
Write-Success "Container '$containerName' is deployed and ready for use.`n"
Write-Host "Connection String to master:`n-->  $masterConnectionString`n" -ForegroundColor Cyan
Write-Host "Connection String to Testing Framework:`n-->  $testingConnectionString`n" -ForegroundColor Cyan
Write-Host "Connection String to Direct Framework:`n-->  $directConnectionString`n" -ForegroundColor Cyan
