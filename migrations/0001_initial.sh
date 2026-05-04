#!/bin/bash
# Migration 0001: Initial setup
# This script is called by 'barchy update' or 'boot.sh'

echo "Running Migration 0001: Initial system tweaks"

# Ensure essential directories exist
mkdir -p "$HOME/Pictures/Wallpapers"
mkdir -p "$HOME/.local/bin"

# Example: Set a default wallpaper if none exists
if [ ! -f "$HOME/Pictures/Wallpapers/default.jpg" ]; then
    echo "Hint: Add a wallpaper to ~/Pictures/Wallpapers/default.jpg"
fi

echo "Migration 0001 complete."
