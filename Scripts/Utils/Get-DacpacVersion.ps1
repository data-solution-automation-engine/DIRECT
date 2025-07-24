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
