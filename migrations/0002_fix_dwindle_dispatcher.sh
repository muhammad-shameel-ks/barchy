#!/bin/bash

# Migration 0002: Fix invalid dispatcher in Hyprland config
# Fixes: "Invalid dispatcher: dwindle" error

echo "Running migration: Fix Hyprland dispatcher..."

HYPR_CONF="$HOME/.config/hypr/hyprland.conf"

if [ -f "$HYPR_CONF" ]; then
    if grep -q "bind = \$mainMod, P, dwindle" "$HYPR_CONF"; then
        sed -i 's/bind = $mainMod, P, dwindle/bind = $mainMod, P, pseudo/' "$HYPR_CONF"
        echo "Fixed dwindle dispatcher in $HYPR_CONF"
    else
        echo "Config already fixed or not found"
    fi
else
    echo "Hyprland config not found, skipping."
fi

echo "Migration 0002 complete."