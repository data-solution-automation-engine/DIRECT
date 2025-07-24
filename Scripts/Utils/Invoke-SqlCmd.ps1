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
