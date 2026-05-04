#!/bin/bash

# Migration 0003: Install barchy CLI and fix PATH
# This ensures the 'barchy' command is available even if boot.sh wasn't rerun.

echo "Running migration: Installing barchy CLI..."

# Define source and destination
REPO_DIR="$(dirname "$(readlink -f "$0")")/.."
BARCHY_SRC="$REPO_DIR/bin/barchy"
LOCAL_BIN="$HOME/.local/bin"
TARGET_BIN="$LOCAL_BIN/barchy"

# Create local bin if it doesn't exist
mkdir -p "$LOCAL_BIN"

# Install the binary
if [ -f "$BARCHY_SRC" ]; then
    cp "$BARCHY_SRC" "$TARGET_BIN"
    chmod +x "$TARGET_BIN"
    echo "Barchy CLI copied to $TARGET_BIN"
else
    echo "Error: Could not find barchy source at $BARCHY_SRC"
    exit 1
fi

# Ensure ~/.local/bin is in PATH for future sessions
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo "Adding ~/.local/bin to PATH in .bashrc..."
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
    echo "Please run 'source ~/.bashrc' or restart your terminal."
fi

echo "Migration 0003 complete."
