#!/bin/sh
# Menu-based master installer for Creality Hi firmware stack

SCRIPT_DIR="$(dirname "$0")"
PRINTER_MODEL=$(/usr/bin/keybox -r model | sed 's/.*model = //')

if [ "$PRINTER_MODEL" != "F018" ]; then
    echo "The current printer is not a Creality Hi. Exiting..."
    exit 1
fi

show_menu() {
  clear
  echo "=== Creality Hi manager ==="
  echo "+++ Printer model: $PRINTER_MODEL +++"
  echo
  echo " a) Install dependencies"
  echo " b) Install Moonraker"
  echo " c) Install Fluidd"
  echo " d) Add Fluidd access on port 80"
  echo " e) Replace/restore motor_control.cfg"
  echo " f) Toggle logging to file"
  echo " g) Toggle adbd (ADB over network) service"
  echo " h) Toggle Creality telemetry services"
  echo " i) Toggle Stock Creality gcode files"
  echo " j) Disable startup self-check process"
  echo " k) Reboot printer"
  echo " x) Exit"
  echo
}

run_script() {
    DIR="$1"
    SCRIPT_NAME="$2"
    SKIP="$3"

    if [ -x "$SCRIPT_DIR/$DIR/$SCRIPT_NAME" ]; then
        echo ">>> Running $DIR/$SCRIPT_NAME..."
        ( cd "$SCRIPT_DIR/$DIR" && ./$SCRIPT_NAME )

        if [ $? -eq 0 ]; then
            echo ">>> Script finished successfully."
        else
            echo ">>> Script finished with errors."
        fi
    else
        echo "ERROR: $DIR/$SCRIPT_NAME not found or not executable!"
    fi

    if [ "$SKIP" == "" ]; then
        echo "Press any key to continue..."
        read -n 1 -s
    fi
}

while true; do

    show_menu
    read -p "Select an option: " -n 1 -r
    echo

    case "$REPLY" in
        a)
            for dir in entware root; do
                run_script "$dir" "install.sh" "skip"
            done
            ;;
        b) run_script "moonraker" "install.sh";;
        c) run_script "fluidd" "install.sh";;
        d) run_script "extras" "add_port_80.sh";;
        e) run_script "extras" "update_motor_control.sh";;
        f) run_script "extras" "creality_log.sh";;
        g) run_script "extras" "toggle_adbd.sh";;
        h) run_script "extras" "toggle_telemetry.sh";;
        i) run_script "extras" "gcode_files.sh";;
        j) run_script "extras" "self_check.sh";;
        k) echo "Rebooting printer..."; echo; reboot /now; exit 0 ;;
        x) echo "Exiting..."; exit 0 ;;
        *) echo "Invalid option, try again."; sleep 1 ;;
    esac
done
