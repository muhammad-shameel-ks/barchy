#!/bin/bash

# Migration 0002: Check if running as root and prompt for user creation
# This is useful for "bare Arch" installs where only root exists.

if [ "$EUID" -eq 0 ]; then
    echo "Running as root. It is highly recommended to create a non-privileged user for Hyprland."
    
    read -p "Would you like to create a new user now? (y/N): " create_user
    if [[ "$create_user" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        read -p "Enter username: " new_username
        
        if id "$new_username" &>/dev/null; then
            echo "User $new_username already exists."
        else
            useradd -m -G wheel,video,audio "$new_username"
            echo "Please set a password for $new_username:"
            passwd "$new_username"
            
            # Ensure wheel group has sudo access
            if ! grep -q "^%wheel ALL=(ALL:ALL) ALL" /etc/sudoers; then
                echo "Enabling sudo for wheel group..."
                echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers
            fi
            
            echo "User $new_username created and added to wheel, video, and audio groups."
            echo "You should log in as $new_username to continue the Barchy setup."
        fi
    fi
else
    echo "Not running as root. Skipping user creation check."
fi
