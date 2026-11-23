#!/bin/sh
set -e

REPO="analyzify/analyzify-mcp-public"
BINARY="analyzify-mcp"
INSTALL_DIR="/usr/local/bin"

OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

case "$ARCH" in
  x86_64|amd64) ARCH="amd64" ;;
  arm64|aarch64) ARCH="arm64" ;;
  *) echo "Unsupported architecture: $ARCH" && exit 1 ;;
esac

case "$OS" in
  linux|darwin) ;;
  *) echo "Unsupported OS: $OS" && exit 1 ;;
esac

# The newest stable connector release: a tag vX.Y.Z that is neither a draft nor a
# prerelease. A new release is a prerelease until it has been checked, and skill
# releases (skill-v*) are not the connector.
RELEASES=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases?per_page=100") || {
  echo "Error: could not read the releases from GitHub (rate limit or network); try again in a few minutes" && exit 1
}
TAG=$(printf '%s\n' "$RELEASES" \
  | grep -oE '"(tag_name|draft|prerelease)": *("[^"]*"|true|false)' \
  | awk -F': *' '
      function flush() {
        if (tag ~ /^v[0-9]+\.[0-9]+\.[0-9]+$/ && draft == "false" && pre == "false") { print tag; found = 1; exit }
      }
      $1 == "\"tag_name\"" { if (tag != "") flush(); tag = $2; gsub(/"/, "", tag); draft = ""; pre = ""; next }
      $1 == "\"draft\"" { draft = $2; next }
      $1 == "\"prerelease\"" { pre = $2; next }
      END { if (!found && tag != "") flush() }')

if [ -z "$TAG" ]; then
  echo "Error: No stable release found" && exit 1
fi

ASSET="${BINARY}_${OS}_${ARCH}.tar.gz"
URL="https://github.com/${REPO}/releases/download/${TAG}/${ASSET}"

echo "Downloading ${BINARY} ${TAG} for ${OS}/${ARCH}..."
tmpdir=$(mktemp -d)
curl -sL "$URL" | tar xz -C "$tmpdir"

echo "Installing to ${INSTALL_DIR}/${BINARY}..."
sudo mv "$tmpdir/$BINARY" "$INSTALL_DIR/$BINARY"
rm -rf "$tmpdir"

echo "Done! Run '${BINARY} version' to verify."
