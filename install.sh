#!/usr/bin/env sh
set -e

REPO="https://github.com/sentrycorelabs/matrix.git"
INSTALL_DIR="$HOME/.matrix"
BIN_LINK="/usr/local/bin/matrix"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

msg() {
    color="$1"
    shift
    printf "${color}${BOLD}[matrix]${NC} %s\n" "$*"
}

fail() {
    msg "$RED" "$1"
    exit 1
}

# ─── Preflight checks ───────────────────────────────────────────

command -v git >/dev/null 2>&1 || fail "git is required but not installed."
command -v docker >/dev/null 2>&1 || fail "docker is required but not installed."
docker info >/dev/null 2>&1 || fail "Docker daemon is not running."

# ─── Install ─────────────────────────────────────────────────────

if [ -d "$INSTALL_DIR" ]; then
    msg "$YELLOW" "Existing installation found at $INSTALL_DIR"
    msg "$CYAN" "Pulling latest changes..."
    git -C "$INSTALL_DIR" pull
else
    msg "$CYAN" "Cloning Matrix to $INSTALL_DIR..."
    git clone "$REPO" "$INSTALL_DIR"
fi

chmod +x "$INSTALL_DIR/matrix"

# ─── Symlink ─────────────────────────────────────────────────────

if [ -L "$BIN_LINK" ] || [ -e "$BIN_LINK" ]; then
    msg "$YELLOW" "$BIN_LINK already exists, updating..."
fi

if [ -w "$(dirname "$BIN_LINK")" ]; then
    ln -sf "$INSTALL_DIR/matrix" "$BIN_LINK"
else
    msg "$CYAN" "Need sudo to symlink into /usr/local/bin"
    sudo ln -sf "$INSTALL_DIR/matrix" "$BIN_LINK"
fi

msg "$GREEN" "Symlinked matrix to $BIN_LINK"

# ─── Build ───────────────────────────────────────────────────────

msg "$CYAN" "Building the Docker image (this may take a few minutes)..."
docker build -t matrix "$INSTALL_DIR"

msg "$GREEN" "Matrix installed successfully!"
echo ""
echo "  Run 'matrix' in any project directory to get started."
echo "  Run 'matrix help' for all commands."
echo ""
