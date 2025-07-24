# WIP, help with setup of local environment and prerequisites.

# Restore the local dotnet tools as defined in `.config/dotnet-tools.json`
# n.b. Local tools are called through the `dotnet run tool` command
# the global alias is for globally installed tools
dotnet tool restore

# Run an update for the tools
dotnet tool update --all

# Run update on dotnet dependencies (NuGets)
dotnet outdated

# Validate that .net 10 is available
if (-not (dotnet --list-sdks | Select-String '10.0')) {
  Write-Host "Error: .NET SDK 10.0 is not installed. Please install it from https://dotnet.microsoft.com/download/dotnet/10.0"
  # exit 1
}

# Validate that Podman is installed
if (-not (Get-Command podman -ErrorAction SilentlyContinue)) {
  Write-Host "Error: Podman is not installed. Please install it from https://podman.io/getting-started/installation"
  # exit 1
}

# Validate that vs code is installed
if (-not (Get-Command code -ErrorAction SilentlyContinue)) {
  Write-Host "Error: Visual Studio Code is not installed. Please install it from https://code.visualstudio.com/"
  # exit 1
}

# Validate vs code extensions that are required for development
$requiredExtensions = @(
  "ms-dotnettools.csharp",
  "ms-vscode.powershell"
)
foreach ($extension in $requiredExtensions) {
  if (-not (code --list-extensions | Select-String $extension)) {
    Write-Host "Error: Visual Studio Code extension '$extension' is not installed. Please install it."
  }
}
