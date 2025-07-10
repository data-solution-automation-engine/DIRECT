# Create a definition for, and spin up, a SQL Server container locally in Podman

# Some definitions, change or refine as needed:

# sqlVersion: The numeric generation/version of SQL Server to use
$sqlVersion = "2025"
# imageVersion: container image version to use
$imageVersion = "$sqlVersion-latest"
# containerName: name of the container to create locally in Podman
$containerName = "direct-dev-$sqlVersion"
# imageBase: identifying Microsoft's registry for SQL Server images
# This is the base address to the official Microsoft container images for SQL Server
$imageBase = "mcr.microsoft.com/mssql/server"
# imageName: Full container image name to pull
$imageName = "${imageBase}:${imageVersion}"
# sqlServerPort: The port to use for connections from your host
# to the SQL Server instance in the container
# Change this if you are running a local SQL Server instance
# Or run a whole flock of instances
# The port needs to go in the connection string
# if it is not the default port 1433
$sqlServerPort = 1433
# sqlPassword: the SA password for the SQL Server
# This must match the default password policy for the SQL Server version
$sqlPassword = "Awesome!Passw0rd"
# portMapping: Define the port mapping for the SQL Server container
# This maps the SQL Server port in the container to the host port
$portMapping = "${sqlServerPort}:1433"
# localAddress: a valid address to the exposed container:
# localhost, 127.0.0.1 (v4), or ::1 (v6) etc
# Windows 11 might map localhost to ::1 (IPv6) by default
# which does't automatically work in Podman,
# so we use the v4 loopback ip address as default
$localAddress = "127.0.0.1"
# connectionString: define the complete connection string for SQL Server
$connectionString = "Server=$localAddress,${sqlServerPort};Database=master;User Id=sa;Password=${sqlPassword};"

Write-Host "Image Name: $imageName" -ForegroundColor Cyan
Write-Host "Connection String: $connectionString" -ForegroundColor Cyan

# Prerequisites:
# - Podman must be installed and running
# - The Podman service must be running

# Install Podman if not already installed
if (-not (Get-Command podman -ErrorAction SilentlyContinue)) {
    Write-Host "Podman is not installed. Please allow install of Podman"
    try {
    # Run the winget installations for Podman
    Start-Process "winget install RedHat.Podman" -Wait
    Start-Process "winget install RedHat.Podman-Desktop" -Wait
    Write-Host "Podman installation seems complete." -ForegroundColor Green
    Write-Host "Please complete and validate Podman configuration and restart the script." -ForegroundColor Blue
    } catch {
        Write-Host "Failed to install Podman. Please install it manually."
        exit 1
    }
    exit 1
} else {
    Write-Host "Podman is already installed." -ForegroundColor Green
}

# Check if the container already exists
$existingContainer = podman ps -a --filter "name=$containerName" --format "{{.Names}}"
if ($existingContainer) {
    Write-Host "Container '$containerName' already exists." -ForegroundColor Red
    $remove = Read-Host "Do you want to remove the existing container? (y/n)"
    if ($remove -eq 'y' -or $remove -eq 'Y') {
        try {
            podman rm -f $containerName
            Write-Host "Container '$containerName' removed." -ForegroundColor Yellow
        } catch {
            Write-Host "Failed to remove container '$containerName': $_" -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "Please remove the container manually before creating a new one." -ForegroundColor Red
        exit 1
    }
}
# Create the container with the specified environment variables and port mapping
try {
  podman run -d --name $containerName -e "ACCEPT_EULA=Y" -e "MSSQL_SA_PASSWORD=$sqlPassword" -p 0.0.0.0:$portMapping $imageName
  Write-Host "Container '$containerName' created successfully." -ForegroundColor Green
} catch {
  Write-Host "Failed to create container '$containerName': $_" -ForegroundColor Red
  exit 1
}
# Check if the container is running
$containerStatus = podman ps --filter "name=$containerName" --format "{{.Status}}"
if ($containerStatus -match "Up") {
    Write-Host "Container '$containerName' is running." -ForegroundColor Green
} else {
    Write-Host "Container '$containerName' is not running." -ForegroundColor Red
}
# Display the container status
Write-Host "Container '$containerName' status: $containerStatus" -ForegroundColor Yellow
# Display the container logs
Write-Host "Container '$containerName' logs start:" -ForegroundColor Cyan
podman logs $containerName
Write-Host "Container '$containerName' logs end" -ForegroundColor Cyan
# Display the SQL Server connection information
Write-Host "You can connect to SQL Server using the following connection string:" -ForegroundColor Blue
Write-Host "$connectionString" -ForegroundColor Blue
# Reminder to change the SA password as needed
Write-Host "Please remember to change the SA password after your first login as needed for security reasons." -ForegroundColor Yellow

# Run Connection Test to SQL instance
$maxAttempts = 10
$attempt = 1
$success = $false
Write-Host "Starting SQL Server connection tests..." -ForegroundColor Cyan
while ($attempt -le $maxAttempts -and -not $success) {
    try {
        $sqlConnection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
        $sqlConnection.Open()
        Write-Host "SQL Server connection test successful on attempt $attempt." -ForegroundColor Green
        $sqlConnection.Close()
        $success = $true
    } catch {
        Write-Host "Attempt ${attempt}: SQL Server connection test failed. Retrying in 5 seconds..." -ForegroundColor Yellow
        # The actual connection will take a while to try this, so an iteration will take more than 5 seconds...
        Start-Sleep -Seconds 5
        $attempt++
    }
}
if (-not $success) {
    Write-Host "SQL Server connection test failed after $maxAttempts attempts." -ForegroundColor Red
}

# Path to the .dacpac file
$dacpacPath = "testing/Testing_Framework.dacpac"

# Check if the dacpac file exists
if (-not (Test-Path $dacpacPath)) {
    Write-Host "DACPAC file not found at $dacpacPath" -ForegroundColor Red
    exit 1
}

# Deploy the DACPAC to the container's SQL Server
$connectionStringTestingFramework = "Server=$localAddress,${sqlServerPort};Database=Testing_Framework;User Id=sa;Password=$sqlPassword;TrustServerCertificate=true;"
$deployCmd = "& `"SqlPackage`" /Action:Publish /SourceFile:`"$dacpacPath`" /TargetConnectionString:`"$connectionStringTestingFramework`" /p:BlockOnPossibleDataLoss=false"

# Print it out for debugging
Write-Host "The testing framework deployment is using the following command:" -ForegroundColor Blue
Write-Host $deployCmd -ForegroundColor Blue

Write-Host "Starting DACPAC deployment..." -ForegroundColor Cyan
Invoke-Expression $deployCmd
if ($LASTEXITCODE -eq 0) {
    Write-Host "DACPAC deployed successfully." -ForegroundColor Green
} else {
    Write-Host "DACPAC deployment failed." -ForegroundColor Red
    exit 1
}
