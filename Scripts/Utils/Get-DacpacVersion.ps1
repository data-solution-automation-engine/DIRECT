<#
.SYNOPSIS
    Extracts the version from a DACPAC file.

.DESCRIPTION
    Unzips the DACPAC file, reads the model.xml, and returns the version property
    if present. The DACPAC is extracted to a temporary directory which is cleaned
    up after processing.

.PARAMETER DacpacPath
    The path to the DACPAC file to extract version information from.

.EXAMPLE
    $version = Get-DacpacVersion -DacpacPath "./db/Direct_Framework.dacpac"

.EXAMPLE
    Get-ChildItem -Filter *.dacpac | ForEach-Object { Get-DacpacVersion -DacpacPath $_.FullName }

.OUTPUTS
    System.String - The version string from the DACPAC, or $null if not found.

.NOTES
    File Name      : Get-DacpacVersion.ps1
    Prerequisite   : PowerShell 5.1 or later
    License        : LGPL-3.0 (GNU Lesser General Public License v3.0)

.LINK
    https://github.com/data-solution-automation-engine/DIRECT

.LINK
    https://github.com/data-solution-automation-engine/DIRECT/blob/main/COPYING.txt

.COMPONENT
    DIRECT Framework - Data Integration Runtime Execution Control Tools

.FUNCTIONALITY
    DACPAC version extraction and analysis.
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
