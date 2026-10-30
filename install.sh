#!/usr/bin/env bash
set -euo pipefail

REPO="MOINtwentysix/ThatCoding"
INSTALL_DIR="$HOME/.thatcoding/bin"
APP_NAME="thatcoding"
COMMAND_NAME="tac"

MUTED='\033[0;2m'
GREEN='\033[0;32m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BOLD}Installing ThatCoding (${COMMAND_NAME})...${NC}"

# Detect OS
raw_os=$(uname -s)
case "$raw_os" in
    Darwin*) os="macos" ;;
    Linux*) os="linux" ;;
    MINGW*|MSYS*|CYGWIN*) os="windows" ;;
    *)
        echo -e "${RED}Unsupported OS: $raw_os${NC}"
        exit 1
        ;;
esac

# Detect Architecture
arch=$(uname -m)
case "$arch" in
    x86_64|amd64) arch="x64" ;;
    arm64|aarch64) arch="arm64" ;;
    *)
        echo -e "${RED}Unsupported architecture: $arch${NC}"
        exit 1
        ;;
esac

# macOS Rosetta check
if [ "$os" = "macos" ] && [ "$arch" = "x64" ]; then
    rosetta_flag=$(sysctl -n sysctl.proc_translated 2>/dev/null || echo 0)
    if [ "$rosetta_flag" = "1" ]; then
        arch="arm64"
    fi
fi

echo -e "${MUTED}Detected platform: ${os}-${arch}${NC}"

# Release archive URL
TAG=${VERSION:-latest}
if [ "$TAG" = "latest" ]; then
    BASE_URL="https://github.com/${REPO}/releases/latest/download"
else
    BASE_URL="https://github.com/${REPO}/releases/download/${TAG}"
fi

mkdir -p "$INSTALL_DIR"
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

if [ "$os" = "windows" ]; then
    ARCHIVE_FILE="thatcoding-windows-${arch}.zip"
    URL="${BASE_URL}/${ARCHIVE_FILE}"
    echo -e "${MUTED}Downloading from ${URL}...${NC}"
    if ! curl -fsSL "$URL" -o "$TMP_DIR/$ARCHIVE_FILE"; then
        echo -e "${RED}Failed to download ${URL}${NC}"
        exit 1
    fi
    unzip -oq "$TMP_DIR/$ARCHIVE_FILE" -d "$INSTALL_DIR"
    
    # Create tac.cmd and thatcoding.cmd
    cat > "$INSTALL_DIR/tac.cmd" <<'EOF'
@echo off
"%~dp0thatcoding.exe" %*
exit /b %errorlevel%
EOF
    cat > "$INSTALL_DIR/thatcoding.cmd" <<'EOF'
@echo off
"%~dp0thatcoding.exe" %*
exit /b %errorlevel%
EOF
else
    ARCHIVE_FILE="thatcoding-${os}-${arch}.tar.gz"
    URL="${BASE_URL}/${ARCHIVE_FILE}"
    echo -e "${MUTED}Downloading from ${URL}...${NC}"
    if ! curl -fsSL "$URL" -o "$TMP_DIR/$ARCHIVE_FILE"; then
        echo -e "${RED}Failed to download ${URL}${NC}"
        exit 1
    fi
    tar -xzf "$TMP_DIR/$ARCHIVE_FILE" -C "$INSTALL_DIR"
    chmod +x "$INSTALL_DIR/thatcoding"

    # Create 'tac' symlink/wrapper
    ln -sf "$INSTALL_DIR/thatcoding" "$INSTALL_DIR/tac"
fi

# Add to PATH if needed
add_path() {
    local file="$1"
    local line="export PATH=\"$INSTALL_DIR:\$PATH\""
    if [ -f "$file" ]; then
        if ! grep -q "$INSTALL_DIR" "$file"; then
            echo "" >> "$file"
            echo "# ThatCoding" >> "$file"
            echo "$line" >> "$file"
            echo -e "${MUTED}Added $INSTALL_DIR to $file${NC}"
        fi
    fi
}

current_shell=$(basename "${SHELL:-bash}")
case "$current_shell" in
    zsh)
        add_path "${ZDOTDIR:-$HOME}/.zshrc"
        ;;
    bash)
        add_path "$HOME/.bashrc"
        add_path "$HOME/.bash_profile"
        ;;
    fish)
        if [ -d "$HOME/.config/fish" ]; then
            fish_config="$HOME/.config/fish/config.fish"
            if [ -f "$fish_config" ] && ! grep -q "$INSTALL_DIR" "$fish_config"; then
                echo "fish_add_path $INSTALL_DIR" >> "$fish_config"
            fi
        fi
        ;;
    *)
        add_path "$HOME/.profile"
        ;;
esac

echo ""
echo -e "${GREEN}ThatCoding has been installed successfully!${NC}"
echo ""
echo -e "You can start it with: ${BOLD}${COMMAND_NAME}${NC}"
echo ""
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    echo -e "${MUTED}To use '${COMMAND_NAME}' in this current terminal window, run:${NC}"
    echo -e "  export PATH=\"$INSTALL_DIR:\$PATH\""
    echo ""
fi
