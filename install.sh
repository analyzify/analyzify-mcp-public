#!/bin/sh
set -e

REPO="analyzify/analyzify-mcp-public"
BINARY="analyzify-mcp"
# A folder the user owns, so the connector can update itself (no sudo). Another
# folder only when asked: ANALYZIFY_MCP_INSTALL_DIR=/usr/local/bin (that one uses sudo).
INSTALL_DIR="${ANALYZIFY_MCP_INSTALL_DIR:-$HOME/.local/bin}"

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
trap 'rm -rf "$tmpdir"' EXIT
curl -fsSL "$URL" -o "$tmpdir/$ASSET" || { echo "Error: could not download $URL" && exit 1; }
tar xzf "$tmpdir/$ASSET" -C "$tmpdir"
chmod 755 "$tmpdir/$BINARY"

# ~ for the messages
case "$INSTALL_DIR" in
  "$HOME"/*) SHOW_DIR="~${INSTALL_DIR#"$HOME"}" ;;
  *) SHOW_DIR="$INSTALL_DIR" ;;
esac

echo "Installing to ${SHOW_DIR}/${BINARY}..."
SUDO=""
mkdir -p "$INSTALL_DIR" 2>/dev/null || true
if [ ! -d "$INSTALL_DIR" ] || [ ! -w "$INSTALL_DIR" ]; then
  echo "${SHOW_DIR} is not writable by you: using sudo (the connector cannot update itself there)."
  SUDO="sudo"
  $SUDO mkdir -p "$INSTALL_DIR"
fi
# copy next to the target, then rename over it: a running copy is never overwritten in place
$SUDO cp "$tmpdir/$BINARY" "$INSTALL_DIR/.${BINARY}.new.$$"
$SUDO mv -f "$INSTALL_DIR/.${BINARY}.new.$$" "$INSTALL_DIR/$BINARY"

echo "Done: ${BINARY} ${TAG} is in ${SHOW_DIR}."

case ":$PATH:" in
  *":$INSTALL_DIR:"*) ;;
  *)
    case "$(basename "${SHELL:-sh}")" in
      zsh) RC="~/.zshrc" ;;
      bash) if [ "$OS" = "darwin" ]; then RC="~/.bash_profile"; else RC="~/.bashrc"; fi ;;
      *) RC="~/.profile" ;;
    esac
    echo "${SHOW_DIR} is not on your PATH. To run ${BINARY} by name, add it: echo 'export PATH=\"${INSTALL_DIR}:\$PATH\"' >> ${RC}"
    ;;
esac

OLD="/usr/local/bin/${BINARY}"
if [ "$INSTALL_DIR" != "/usr/local/bin" ] && [ -e "$OLD" ]; then
  echo ""
  echo "An older copy is in ${OLD}: run setup once more so Claude uses the new copy; you can then remove the old one with sudo rm ${OLD}"
fi

echo ""
echo "Next, connect your store (it asks for your Analyzify API key):"
echo "  Claude Desktop: ${SHOW_DIR}/${BINARY} setup"
echo "  Claude Code:    ${SHOW_DIR}/${BINARY} setup --claude-code"
