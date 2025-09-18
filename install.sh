#!/usr/bin/env sh
set -eu

REPO_BASE_DEFAULT="https://raw.githubusercontent.com/meal/claude-code-contained/main"
BASE_URL="${BASE_URL:-$REPO_BASE_DEFAULT}"
INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/bin}"
BINARIES="claude code"

error() {
  printf '%s\n' "[claude-code] Error: $1" >&2
  exit 1
}

command -v curl >/dev/null 2>&1 || error "curl is required"
command -v install >/dev/null 2>&1 || error "install (coreutils) is required"

TMP_DIR="$(mktemp -d)"
cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT INT HUP TERM

printf '[claude-code] Installing into %s\n' "$INSTALL_DIR"
install -d "$INSTALL_DIR"

for name in $BINARIES; do
  url="$BASE_URL/bin/$name"
  dest="$TMP_DIR/$name"
  printf '[claude-code] Fetching %s\n' "$url"
  curl -fsSL "$url" -o "$dest" || error "failed to download $url"
  install -m 0755 "$dest" "$INSTALL_DIR/$name"
  printf '[claude-code] Installed %s\n' "$INSTALL_DIR/$name"
done

echo '[claude-code] Done. Ensure the install directory is on your PATH.'
