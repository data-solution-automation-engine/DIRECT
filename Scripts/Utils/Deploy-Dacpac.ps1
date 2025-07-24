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
    $tool = Test-DotnetTool -ToolName "sqlpackage"
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
