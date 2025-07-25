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

    # Validate required properties
    if (-not $builder["Server"]) {
      Write-Error "Returning: Connection string property 'Server' for the SQL Server address not found."
      return $false
    }
    if (-not $builder["Initial Catalog"]) {
      Write-Error "Returning: Connection string property 'Initial Catalog' for the Database name not found."
      return $false
    }
    if (-not $builder["User ID"]) {
      Write-Error "Returning: Connection string property 'User ID' for the login not found."
      return $false
    }
    if (-not $builder["Password"]) {
      Write-Error "Returning: Connection string property 'Password' for the login not found."
      return $false
    }

    Write-Heading "SqlCmd is executing a SQL script"
    Write-Host "SQL script file:`n$SqlPath"

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

    Write-Heading -Heading "SqlCmd process results"

    if ($sqlcmdOutput -and ($sqlcmdOutput | Where-Object { $_.Trim() -ne "" })) {
      Write-Host ($sqlcmdOutput -join "`n") -ForegroundColor Cyan
    } else {
      Write-Host "No output was produced by the provided SQL script or sqlcmd." -ForegroundColor Yellow
    }

    if ($LASTEXITCODE -eq 0) {
        Write-Success "SQL script executed successfully."
        return $true
    } else {
        Write-Error "SQL script execution failed."
        return $false
    }
  }
  catch {
    Write-Error "An error occurred while executing the SQL script:`n$_"
    return $false
  }
}
