function Install-SqlServerModule {
  [CmdletBinding()]
  param(
    [switch]$NoAutoUpgrade, # should module upgrade to latest automatically
    [switch]$Interactive    # should module prompt; or just log and continue
  )
  try {
    # # Prefer TLS 1.2 for PSGallery
    # try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}

    # Ensure PSGallery exists and is trusted (avoid "untrusted repo" prompts)
    $repo = Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue
    if (-not $repo) {
      Register-PSRepository -Default -ErrorAction Stop
      $repo = Get-PSRepository -Name PSGallery
    }
    if ($repo.InstallationPolicy -ne 'Trusted') {
      Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -ErrorAction Stop
    }

    # Ensure NuGet provider (avoid interactive bootstrap)
    if (-not (Get-PackageProvider -Name NuGet -ListAvailable -ErrorAction SilentlyContinue)) {
      Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser -ErrorAction Stop
    }

    $installed = Get-Module -ListAvailable -Name SqlServer | Sort-Object Version -Descending | Select-Object -First 1
    $latest = Find-Module -Name SqlServer -Repository PSGallery -ErrorAction Stop

    $needInstall = -not $installed
    $needUpgrade = $installed -and ($installed.Version -lt $latest.Version)

    if ($needInstall -or ($needUpgrade -and $AutoUpgrade)) {
      $targetVersion = $latest.Version
      Install-Module -Name SqlServer -RequiredVersion $targetVersion -Repository PSGallery `
        -Scope CurrentUser -Force -AllowClobber -AcceptLicense -ErrorAction Stop
      $installed = Get-Module -ListAvailable -Name SqlServer | Sort-Object Version -Descending | Select-Object -First 1
    }
    elseif ($needUpgrade -and $NoAutoUpgrade) {
      if (-not $Interactive) {
        Write-Host "SqlServer module $($installed.Version) installed; newer $($latest.Version) available. Skipping upgrade." -ForegroundColor Yellow
      }
      else {
        $ans = Read-Host "Upgrade SqlServer module from $($installed.Version) to $($latest.Version)? (y/n)"
        if ($ans -ieq 'y') {
          Install-Module -Name SqlServer -RequiredVersion $latest.Version -Repository PSGallery `
            -Scope CurrentUser -Force -AllowClobber -AcceptLicense -ErrorAction Stop
          $installed = Get-Module -ListAvailable -Name SqlServer | Sort-Object Version -Descending | Select-Object -First 1
        }
      }
    }

    # Import explicit version to avoid older side-by-side confusion
    Import-Module -Name SqlServer -RequiredVersion $installed.Version -Force -ErrorAction Stop | Out-Null
    return $installed.Version
  }
  catch {
    Write-Error "Failed to ensure SqlServer module is installed:`n$_"
    return $null
  }
}
