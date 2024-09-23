################################################################################################################################################################
# DATABASE PROJECT PRE-BUILD PWSH SCRIPT
################################################################################################################################################################

param([string]$path)

Write-Host "The pwsh path param is: '$path'"
Set-Location $path
Write-Host "The pwsh working directory/location is:"
Get-Location | Write-Host

Write-Host "*** PWSH/ps1 - Pre-Build Event: process starting..." -ForegroundColor Green

################################################################################################################################################################
# Build the reference project so that the reference dacpacs are restored

# Change active folder to the reference project
Set-Location "$path\..\..\Reference_Databases"

Get-Location | Write-Host

# Run the dotnet build command to restore the reference dacpacs
dotnet build

# return to the original folder for further processing as needed...
Set-Location -

################################################################################################################################################################
# Add tasks and steps here as needed

# OPTIONAL run pre-dacpac deployment script using sqlcmd
# Use this to validate pre-dacpac deployment scripts from inside the project build process

# script assumes using the new go version
# https://github.com/microsoft/go-sqlcmd
# https://learn.microsoft.com/en-au/sql/tools/sqlcmd/sqlcmd-utility
# Install through:
#  - winget install sqlcmd

if($false)
{
    Write-Host "Running integrated pre-dacpac deployment script testing execution..."

    # Change active folder to the reference project
    Set-Location "$path\..\DeploymentScripts\1-PreDacpacDeployment"

    # Target server and Database *NOT* parameterised here...
    Get-Location | Write-Host
    sqlcmd -S . -d DIRECT_Framework -E -Q "SELECT @@VERSION;"
    sqlcmd -S . -d DIRECT_Framework -E -i PreDacpacDeployment.sql

    # return to the original folder for further processing as needed...
    Set-Location -
}
else
{
    Write-Host "Skipping integrated pre-dacpac deployment script testing execution..."
}

################################################################################################################################################################
Write-Host "*** PWSH/ps1 - Pre-Build Event: process completed..." -ForegroundColor Green

