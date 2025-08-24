#!/bin/sh

CUSTOM_MARKER="# Custom motor control configuration"
SCRIPT_DIR=$(dirname "$0")
ACTUAL_CONFIG_FILE=/mnt/UDISK/printer_data/config/motor_control.cfg
ORIGINAL_CONFIG_FILE=${ACTUAL_CONFIG_FILE}.original
CUSTOM_CONFIG_FILE=$SCRIPT_DIR/motor_control.cfg

if grep -q "$CUSTOM_MARKER" "$ACTUAL_CONFIG_FILE"; then
    echo "Motor control configuration has already been replaced."
    read -p "Do you want to restore the original configuration? (y/n) " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [ -f "$ORIGINAL_CONFIG_FILE" ]; then
            mv "$ORIGINAL_CONFIG_FILE" "$ACTUAL_CONFIG_FILE"
            echo "Original motor control configuration restored."
        else
            echo "Error: Original configuration file not found."
            exit 1
        fi
    else
        echo "No changes made."
    fi
else
    if [ -f "$CUSTOM_CONFIG_FILE" ]; then
        echo "WARNING: The motor control configuration file for the"
        echo "X & Y axes is about to be replaced with a custom one."
        echo "Please note that using this file may cause unexpected behavior"
        echo "of your printer. Proceed with caution and at your own risk."
        read -p "Are you sure you want to continue? (y/n) " -n 1 -r
        echo

        if [[ $REPLY =~ ^[Yy]$ ]]; then
            # Rename the current file
            mv "$ACTUAL_CONFIG_FILE" "$ORIGINAL_CONFIG_FILE"

            # Create new actual file: first copy header from original until [motor_control]
            awk '/^\[motor_control\]/ {exit} {print}' "$ORIGINAL_CONFIG_FILE" > "$ACTUAL_CONFIG_FILE"

            # Append the entire custom config after the header
            cat "$CUSTOM_CONFIG_FILE" >> "$ACTUAL_CONFIG_FILE"

            echo "Motor control configuration updated."
        else
            echo "Update cancelled."
        fi
    else
        echo "Error: Custom motor control configuration file not found in $SCRIPT_DIR."
        exit 1
    fi
fi
exit 0
