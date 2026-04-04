# Analyzify MCP installer for Windows
$ErrorActionPreference = "Stop"

$REPO = "analyzify/analyzify-mcp-public"
$BINARY = "analyzify-mcp"

$ARCH = if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") { "arm64" } else { "amd64" }

# Get latest release tag
$releases = Invoke-RestMethod -Uri "https://api.github.com/repos/$REPO/releases"
$TAG = ($releases | Where-Object { $_.tag_name -match "^v\d" } | Select-Object -First 1).tag_name

if (-not $TAG) {
    Write-Error "No release found"
    exit 1
}

$ASSET = "${BINARY}_windows_${ARCH}.zip"
$URL = "https://github.com/$REPO/releases/download/$TAG/$ASSET"

Write-Host "Downloading $BINARY $TAG for windows/$ARCH..."

$tmpDir = New-Item -ItemType Directory -Path (Join-Path $env:TEMP "analyzify-mcp-install")
$zipPath = Join-Path $tmpDir "$ASSET"

Invoke-WebRequest -Uri $URL -OutFile $zipPath
Expand-Archive -Path $zipPath -DestinationPath $tmpDir -Force

# Install to user's local AppData bin (no admin required)
$installDir = Join-Path $env:LOCALAPPDATA "analyzify-mcp"
New-Item -ItemType Directory -Path $installDir -Force | Out-Null
Move-Item -Path (Join-Path $tmpDir "$BINARY.exe") -Destination (Join-Path $installDir "$BINARY.exe") -Force

# Add to PATH if not already there
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*$installDir*") {
    [Environment]::SetEnvironmentVariable("Path", "$userPath;$installDir", "User")
    Write-Host "Added $installDir to your PATH."
}

# Clean up
Remove-Item -Recurse -Force $tmpDir

Write-Host "Done! Restart your terminal, then run '$BINARY version' to verify."
Write-Host ""
Write-Host "To configure Claude Desktop, run:"
Write-Host "  $BINARY setup"
