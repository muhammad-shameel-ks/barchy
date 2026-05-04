# Barchy: Agent Instructions

## Overview
Barchy is an opinionated Hyprland setup for Arch Linux, designed to feel like a custom OS. It follows a bootstrap -> configuration -> migration lifecycle.

## Core Architecture
- **`boot.sh`**: The "Preflight" entrypoint. Must be run to setup mirrors, create a non-root user (if needed), install `paru`, and sync configs.
- **`meta/packages.txt`**: The source of truth for mandatory system packages.
- **`configs/`**: Source templates. The `boot.sh` script **symlinks** these to `~/.config/`. Direct edits in the repo are live if symlinked.
- **`migrations/`**: Sequential shell scripts (`NNNN_name.sh`) for evolving the system.
- **`bin/barchy`**: The primary CLI for the user/agent to interact with the system state.

## Developer Workflows

### System Updates
- Use `barchy update` to run pending migrations.
- State is tracked in `~/.local/state/barchy/version`.

### Adding Features
1.  **Packages**: Add to `meta/packages.txt`.
2.  **Configuration**: Add files to `configs/<app>/`.
3.  **Logic**: If a specific setup step is needed (e.g., enabling a service), create a new script in `migrations/`.
4.  **Verification**: Run `./boot.sh` to ensure symlinks and packages are synced.

### Git Conventions
- **Commits**: Use semantic prefixes (e.g., `feat:`, `fix:`, `refactor:`).
- **Pushing**: Always ensure `boot.sh` is executable (`chmod +x`) before pushing.

## Critical Gotchas
- **Root**: Never run `makepkg` or `paru` as root. `boot.sh` handles user creation if it detects it's running as root.
- **Symlinks**: `boot.sh` will back up existing `~/.config` directories to `.bak` before symlinking.
- **Keybindings**: Main Hyprland binds are in `configs/hypr/hyprland.conf`. 
    - `SUPER + W`: Close window
    - `SUPER + RETURN`: Terminal
    - `SUPER + SHIFT + F`: Nautilus
