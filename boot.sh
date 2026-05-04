#!/bin/bash

# --- Barchy Bootstrap Script ---
set -e

# Define colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}Starting Barchy Bootstrap Process...${NC}"

# 1. Preflight Checks
if ! grep -q "Arch Linux" /etc/os-release; then
    echo -e "${RED}Error: Barchy is designed for Arch Linux only.${NC}"
    exit 1
fi

# 2. Check for Paru
if ! command -v paru &> /dev/null; then
    echo -e "${YELLOW}Paru not found. Installing Paru...${NC}"
    sudo pacman -S --needed base-devel git
    TEMP_DIR=$(mktemp -d)
    git clone https://aur.archlinux.org/paru-bin.git "$TEMP_DIR"
    cd "$TEMP_DIR"
    makepkg -si --noconfirm
    cd -
    rm -rf "$TEMP_DIR"
fi

# 3. Install Packages
echo -e "${BLUE}Installing required packages...${NC}"
PACKAGES_FILE="$(dirname "$(readlink -f "$0")")/meta/packages.txt"
if [ -f "$PACKAGES_FILE" ]; then
    paru -S --needed --noconfirm - < "$PACKAGES_FILE"
else
    echo -e "${RED}Error: packages.txt not found at $PACKAGES_FILE${NC}"
    exit 1
fi

# 4. Setup Configs (Symlinking)
echo -e "${BLUE}Setting up configuration symlinks...${NC}"
CONFIG_SRC="$(dirname "$(readlink -f "$0")")/configs"
mkdir -p "$HOME/.config"

for dir in "$CONFIG_SRC"/*; do
    target="$HOME/.config/$(basename "$dir")"
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        echo -e "${YELLOW}Backing up existing config: $target to $target.bak${NC}"
        mv "$target" "$target.bak"
    fi
    echo -e "Linking $(basename "$dir") -> $target"
    ln -sfn "$dir" "$target"
done

# 5. Initialize State
echo -e "${BLUE}Initializing system state...${NC}"
STATE_DIR="$HOME/.local/state/barchy"
mkdir -p "$STATE_DIR"
if [ ! -f "$STATE_DIR/version" ]; then
    echo "0" > "$STATE_DIR/version"
fi

echo -e "${GREEN}Bootstrap complete! Welcome to Barchy.${NC}"
echo -e "${YELLOW}Please restart your session or run 'hyprland' to start.${NC}"
