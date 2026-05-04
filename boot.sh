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

# 3. Check for Paru
if ! command -v paru &> /dev/null || ! paru --version &> /dev/null; then
    echo -e "${YELLOW}Paru not found or broken. Installing paru-bin...${NC}"
    sudo pacman -S --needed base-devel git
    TEMP_DIR=$(mktemp -d)
    git clone https://aur.archlinux.org/paru-bin.git "$TEMP_DIR"
    
    # Check if running as root - makepkg cannot run as root
    if [ "$EUID" -eq 0 ]; then
        echo -e "${RED}Error: Cannot build Paru as root. Please run this script as a normal user with sudo rights.${NC}"
        rm -rf "$TEMP_DIR"
        exit 1
    else
        cd "$TEMP_DIR"
        makepkg -si --noconfirm
        cd -
    fi
    rm -rf "$TEMP_DIR"

    # Post-install check for library mismatch (common in May 2026)
    if ! paru --version &> /dev/null; then
        echo -e "${YELLOW}Detected library mismatch (libalpm). Attempting shim...${NC}"
        CURRENT_ALPM=$(ls /usr/lib/libalpm.so.1[0-9] | tail -n 1)
        if [ -f "$CURRENT_ALPM" ] && [ ! -f /usr/lib/libalpm.so.15 ]; then
            echo -e "${BLUE}Creating temporary shim: /usr/lib/libalpm.so.15 -> $CURRENT_ALPM${NC}"
            sudo ln -sf "$CURRENT_ALPM" /usr/lib/libalpm.so.15
        fi
    fi
fi

# 4. Install Packages
echo -e "${BLUE}Installing required packages...${NC}"
PACKAGES_FILE="$(dirname "$(readlink -f "$0")")/meta/packages.txt"
if [ -f "$PACKAGES_FILE" ]; then
    paru -S --needed --noconfirm - < "$PACKAGES_FILE"
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
