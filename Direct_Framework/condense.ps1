function Invoke-Consolidation {
    param (
        [string[]]$RootFolders = @("functions", "tables", "schemas", "views", "stored_procedures"),
        [hashtable]$CommentMap = @{
            ".sql" = "--"
            ".py"  = "#"
            ".cs"  = "//"
        },
        [string]$RootPath = (Get-Location).Path,
        [string]$OutputFolder = "consolidated-output"
    )

    # Ensure output directory exists
    if (-not (Test-Path $OutputFolder)) {
        New-Item -ItemType Directory -Path $OutputFolder | Out-Null
    }

    foreach ($folder in $RootFolders) {
        $fullPath = Join-Path $RootPath $folder
        if (-not (Test-Path $fullPath)) {
            Write-Warning "Folder '$folder' does not exist. Skipping."
            continue
        }

        # Group by file extension
        $filesByExt = Get-ChildItem -Path $fullPath -Recurse -File |
            Group-Object { $_.Extension.ToLower() }

        foreach ($group in $filesByExt) {
            $ext = $group.Name
            if (-not $CommentMap.ContainsKey($ext)) {
                Write-Verbose "Skipping unsupported extension: $ext"
                continue
            }

            $commentPrefix = $CommentMap[$ext]
            $extLabel = $ext.TrimStart('.')
            $outputFileName = "${folder}-${extLabel}-output${ext}"
            $outputPath = Join-Path $OutputFolder $outputFileName

            # Clear existing file
            if (Test-Path $outputPath) { Remove-Item $outputPath -Force }

            foreach ($file in $group.Group) {
                $relativePath = $file.FullName.Substring($RootPath.Length).TrimStart("\", "/")
                $header = "$commentPrefix $relativePath"
                Add-Content -Path $outputPath -Value $header
                Add-Content -Path $outputPath -Value ($file | Get-Content -Raw)
                Add-Content -Path $outputPath -Value ""
            }

            Write-Host "Created: $outputFileName"
        }
    }
}

# Run automatically only if the script is called directly (not dot-sourced)
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Invoke-Consolidation
}

# Example code for running within this script:
# Note that the folder here is relative to the cwd of the terminal, not the script location.
<#
Invoke-Consolidation -RootFolders @("BuildTools", "DeploymentScripts", "Functions", "Tables", "Schemas", "Views", "Stored Procedures") -OutputFolder "consolidated-output" -CommentMap @{".sql"="--"}
#>

# Example usage from another script file:
<#
 . .\Consolidate-Files.ps1
 Invoke-Consolidation -RootFolders @("tables") -OutputFolder "tmp"
#>

# Example usage from PowerShell console:
<#
.\Consolidate-Files.ps1 -OutputFile "minified.sql" -RootFolders @("tables", "views") -CommentMap @{".sql"="--"}
#>
