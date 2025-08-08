<#
.SYNOPSIS
  Executes a Sql File on a SQL Server database.
.DESCRIPTION
  Executes SQL file using sqlcmd against a SQL Server instance.
.PARAMETER SqlPath
  The path to the SQL file to deploy.
.PARAMETER ConnectionString
  The connection string for the SQL Server instance.
.PARAMETER ShowResult
  Should the function print the output from the command.
.EXAMPLE
  Invoke-Sqlcmd -SqlPath "./sqlFile.sql" -ConnectionString $cs
.NOTES
  Returns $true if invocation succeeds, otherwise $false.
#>
function Invoke-Sqlcmd {
  param(
    [string]$SqlPath,
    [string]$Query,
    [Parameter(Mandatory = $true)][string]$ConnectionString,
    [bool]$ShowResult = $true,
    [switch]$Silent # true if -Silent is added as flag to call
  )
  try {

    if (-not $SqlPath -and -not $Query) {
      Write-Error "Returning: either -SqlPath or -Query must be provided."
      return $false
    }

    if ($SqlPath -and -not (Test-Path $SqlPath)) {
      Write-Error "Returning: '$SqlPath' file not found"
      return $false
    }

    if (-Not $ConnectionString) {
      Write-Error "Returning: connection string not provided."
      return $false
    }

    if (-not (Get-Command sqlcmd -ErrorAction SilentlyContinue)) {
      Write-Error "The 'sqlcmd' tool can't be found. It might not be installed or not in your PATH."
      Write-Info "Please install it before running this script."
      Write-Info "Install via: 'winget install sqlcmd' on Windows."
      Write-Info "More information: https://learn.microsoft.com/en-us/sql/tools/sqlcmd/sqlcmd-utility"
      return $false
    }

    # Parse the connection string
    $Builder = New-Object System.Data.SqlClient.SqlConnectionStringBuilder($ConnectionString)

    # Validate required properties
    if (-not $Builder["Server"]) {
      Write-Error "Returning: Connection string property 'Server' for the SQL Server address not found."
      return $false
    }
    if (-not $Builder["Initial Catalog"]) {
      Write-Error "Returning: Connection string property 'Initial Catalog' for the Database name not found."
      return $false
    }
    if (-not $Builder["User ID"]) {
      Write-Error "Returning: Connection string property 'User ID' for the login not found."
      return $false
    }
    if (-not $Builder["Password"]) {
      Write-Error "Returning: Connection string property 'Password' for the login not found."
      return $false
    }

    if (-not $Silent) {
      Write-Heading "Invoking SQL script using sqlcmd"
      if ($SqlPath) {
        Write-Info "SQL script file:`n$SqlPath"
      }
      elseif ($Query) {
        Write-Info "Inline SQL query:`n$Query"
      }
    }

    # Map to sqlcmd parameters
    $SqlcmdArgs = @(
      "-S", $Builder["Server"]
      "-d", $Builder["Initial Catalog"]
      "-U", $Builder["User ID"]
      "-P", $Builder["Password"]
    )

    if ($Query) {
      $SqlcmdArgs += @("-Q", $Query)
    }
    else {
      $SqlcmdArgs += @("-i", $SqlPath)
    }

    # Run the sqlcmd command
    $SqlcmdOutput = & sqlcmd @SqlcmdArgs

    if (-not $Silent) {
      Write-Heading -Heading "Sqlcmd process results"

      if ($ShowResult) {
        if ($SqlcmdOutput -and ($SqlcmdOutput | Where-Object { $_.Trim() -ne "" })) {
          Write-Info "Script output:`n"
          Write-Result ($SqlcmdOutput -join "`n")
        }
        else {
          Write-Info "No output was produced by the provided SQL script or sqlcmd."
        }
      }
    }

    if ($LASTEXITCODE -eq 0) {
      if (-not $Silent) {
        Write-Success "`nSQL script executed successfully."
      }
      return $SqlcmdOutput
    }
    else {
      Write-Error "`nSQL script execution failed."
      return $false
    }
  }
  catch {
    Write-Error "An error occurred while executing the SQL script:`n$_"
    return $false
  }
}
