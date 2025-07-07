# Restore the local dotnet tools as defined in `.config/dotnet-tools.json`
dotnet tool restore

# Check for app availability, to assert if the apps are installed globally
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

# Run an update for all local tools
dotnet tool update --all

# Run update on dotnet dependencies (NuGets)
dotnet outdated
