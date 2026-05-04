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

# Cleanup broken shims or paru-bin from previous attempts
if [ -L /usr/lib/libalpm.so.15 ]; then
    echo -e "${YELLOW}Removing incompatible library shim...${NC}"
    sudo rm /usr/lib/libalpm.so.15
fi
if command -v paru &> /dev/null && ! paru --version &> /dev/null; then
    echo -e "${YELLOW}Detected broken paru installation. Removing it...${NC}"
    sudo pacman -Rns --noconfirm paru-bin || sudo pacman -Rns --noconfirm paru || true
fi

echo -e "${BLUE}Updating system mirrors and packages...${NC}"
sudo pacman -Syu --noconfirm

# 2. User Creation (Mandatory for non-root apps like Hyprland/Paru)
if [ "$EUID" -eq 0 ]; then
    echo -e "${YELLOW}Running as root. It is highly recommended to create a non-privileged user.${NC}"
    read -p "Would you like to create a new user now? (y/N): " create_user
    if [[ "$create_user" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        read -p "Enter username: " new_username
        if id "$new_username" &>/dev/null; then
            echo -e "${YELLOW}User $new_username already exists.${NC}"
        else
            useradd -m -G wheel,video,audio "$new_username"
            echo -e "${BLUE}Please set a password for $new_username:${NC}"
            passwd "$new_username"
            
            # Ensure wheel group has sudo access
            if ! grep -q "^%wheel ALL=(ALL:ALL) ALL" /etc/sudoers; then
                echo -e "${BLUE}Enabling sudo for wheel group...${NC}"
                echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers
            fi
            echo -e "${GREEN}User $new_username created. Please log in as this user to continue.${NC}"
            echo -e "${YELLOW}Commands: exit, then log in, then run this script again.${NC}"
            exit 0
        fi
    fi
fi

# 3. Check for AUR Helper (Preferring yay-bin for performance on weak machines)
if ! command -v yay &> /dev/null && ! command -v paru &> /dev/null; then
    echo -e "${YELLOW}No AUR helper found. Installing yay-bin (Pre-compiled)...${NC}"
    sudo pacman -S --needed base-devel git
    TEMP_DIR=$(mktemp -d)
    git clone https://aur.archlinux.org/yay-bin.git "$TEMP_DIR"
    
    if [ "$EUID" -eq 0 ]; then
        echo -e "${RED}Error: Cannot build as root. Please run this script as a normal user.${NC}"
        rm -rf "$TEMP_DIR"
        exit 1
    fi

    cd "$TEMP_DIR"
    makepkg -si --noconfirm
    cd -
    rm -rf "$TEMP_DIR"
fi

# Define helper command
if command -v yay &> /dev/null; then
    HELPER="yay"
elif command -v paru &> /dev/null; then
    HELPER="paru"
else
    echo -e "${RED}Error: Failed to install an AUR helper.${NC}"
    exit 1
fi

# 4. Install Packages
echo -e "${BLUE}Installing required packages using $HELPER...${NC}"
PACKAGES_FILE="$(dirname "$(readlink -f "$0")")/meta/packages.txt"
if [ -f "$PACKAGES_FILE" ]; then
    # Filter out the helper name from the package list to avoid self-conflict
    grep -vE "^(paru|paru-bin|yay|yay-bin)$" "$PACKAGES_FILE" | $HELPER -S --needed --noconfirm -
else
    echo -e "${RED}Error: packages.txt not found at $PACKAGES_FILE${NC}"
    exit 1
fi

# 5. Setup Configs (Symlinking)
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

# 6. Initialize State
echo -e "${BLUE}Initializing system state...${NC}"
STATE_DIR="$HOME/.local/state/barchy"
mkdir -p "$STATE_DIR"
if [ ! -f "$STATE_DIR/version" ]; then
    echo "0" > "$STATE_DIR/version"
fi

echo -e "${GREEN}Bootstrap complete! Welcome to Barchy.${NC}"
echo -e "${YELLOW}Please restart your session or run 'hyprland' to start.${NC}"
