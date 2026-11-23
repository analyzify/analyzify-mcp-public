# Analyzify MCP installer for Windows
$ErrorActionPreference = "Stop"
# Windows PowerShell 5.1 on older setups does not offer TLS 1.2 by default; GitHub needs it
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

$REPO = "analyzify/analyzify-mcp-public"
$BINARY = "analyzify-mcp"

$ARCH = if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") { "arm64" } else { "amd64" }

# The newest stable connector release: a tag vX.Y.Z that is neither a draft nor a
# prerelease. A new release is a prerelease until it has been checked, and skill
# releases (skill-v*) are not the connector.
$releases = Invoke-RestMethod -Uri "https://api.github.com/repos/$REPO/releases?per_page=100"
$TAG = ($releases | Where-Object { -not $_.draft -and -not $_.prerelease -and $_.tag_name -match '^v\d+\.\d+\.\d+$' } | Select-Object -First 1).tag_name

if (-not $TAG) {
    Write-Error "No stable release found"
    exit 1
}

$ASSET = "${BINARY}_windows_${ARCH}.zip"
$URL = "https://github.com/$REPO/releases/download/$TAG/$ASSET"

Write-Host "Downloading $BINARY $TAG for windows/$ARCH..."

$tmpDir = New-Item -ItemType Directory -Path (Join-Path $env:TEMP "analyzify-mcp-install") -Force
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
