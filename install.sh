#!/usr/bin/env bash
# Install debtapx from GitHub releases (or raw main as fallback).
#
#   curl -fsSL https://raw.githubusercontent.com/thebadking/debtapx/main/install.sh | bash
#
# Options (env):
#   DEBTAPX_VERSION   Release tag (default: latest)
#   DEBTAPX_BIN_DIR   Install directory (default: ~/.local/bin)
#   DEBTAPX_REPO      owner/repo (default: thebadking/debtapx)
set -euo pipefail

REPO="${DEBTAPX_REPO:-thebadking/debtapx}"
VERSION="${DEBTAPX_VERSION:-latest}"
BIN_DIR="${DEBTAPX_BIN_DIR:-${HOME}/.local/bin}"
PREFIX_SYSTEM="${DEBTAPX_SYSTEM:-}"

info() { echo "==> $*"; }
die()  { echo "error: $*" >&2; exit 1; }

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "missing dependency: $1"
}

need_cmd curl
need_cmd install

if [[ -n "$PREFIX_SYSTEM" ]]; then
  BIN_DIR="/usr/local/bin"
fi

mkdir -p "$BIN_DIR"

api_url() {
  if [[ "$VERSION" == "latest" ]]; then
    printf 'https://api.github.com/repos/%s/releases/latest' "$REPO"
  else
    printf 'https://api.github.com/repos/%s/releases/tags/%s' "$REPO" "$VERSION"
  fi
}

download_release_asset() {
  local dest="$1"
  local json url tag
  json="$(curl -fsSL "$(api_url)")" || return 1
  tag="$(printf '%s' "$json" | sed -n 's/.*"tag_name":[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
  url="$(printf '%s' "$json" | sed -n 's/.*"browser_download_url":[[:space:]]*"\([^"]*debtapx[^"]*\)".*/\1/p' | head -1)"
  if [[ -z "$url" ]]; then
    # Prefer plain debtapx asset; else tarball from tag
    if [[ -n "$tag" ]]; then
      info "No release asset named debtapx; fetching from tag $tag source"
      curl -fsSL "https://raw.githubusercontent.com/${REPO}/${tag}/debtapx" -o "$dest"
      return
    fi
    return 1
  fi
  info "Downloading $url"
  curl -fL --progress-bar "$url" -o "$dest"
  printf '%s\n' "$tag" >"${dest}.version" 2>/dev/null || true
}

download_main() {
  local dest="$1"
  info "Fetching debtapx from main branch"
  curl -fsSL "https://raw.githubusercontent.com/${REPO}/main/debtapx" -o "$dest"
}

TMP="$(mktemp)"
trap 'rm -f "$TMP" "${TMP}.version"' EXIT

warn() { echo "warning: $*" >&2; }

info "Installing debtapx into $BIN_DIR"
if ! download_release_asset "$TMP" 2>/dev/null; then
  warn "release download failed; falling back to main"
  download_main "$TMP"
fi

# Basic sanity: must be a bash script mentioning debtapx
head -1 "$TMP" | grep -q 'bash' || die "downloaded file does not look like a bash script"
grep -q 'debtapx\|debtap' "$TMP" || die "downloaded file does not look like debtapx"

if [[ -n "$PREFIX_SYSTEM" ]]; then
  sudo install -m 0755 "$TMP" "$BIN_DIR/debtapx"
else
  install -m 0755 "$TMP" "$BIN_DIR/debtapx"
fi

# Ensure BIN_DIR is on PATH for this shell hint
case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *)
    echo
    echo "Note: $BIN_DIR is not on your PATH."
    echo "Add this to your shell rc:"
    echo "  export PATH=\"$BIN_DIR:\$PATH\""
    ;;
esac

echo
info "Installed: $BIN_DIR/debtapx"
"$BIN_DIR/debtapx" --help | head -8 || true
echo
echo "Requires: Arch Linux (or derivative), debtap (AUR), pacman, sudo"
echo "  yay -S debtap"
echo
echo "Try: debtapx --help"
echo "     debtapx /path/to/app.deb"
