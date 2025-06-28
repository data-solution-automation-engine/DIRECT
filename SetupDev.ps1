# restore local dotnet tools
# This restores the tools defined in `.config/dotnet-tools.json`

dotnet tool restore

# check for apps
$apps = @(
    'dotnet-sqltest',
    'dotnet-dacpac',
    'dotnet-dacfx',
    'dotnet-dacpac-compare',
    'dotnet-dacpac-merge'
)

foreach ($app in $apps) {
    if (-not (Get-Command $app -ErrorAction SilentlyContinue)) {
        Write-Host "App '$app' is not installed. Please install it using 'dotnet tool install -g $app'."
    } else {
        Write-Host "App '$app' is installed."
    }
}

# run update for all local tools
dotnet tool update --all

# run update on dotnet dependencies (NuGets)
dotnet outdated
