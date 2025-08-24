#!/bin/sh

# Define file paths for telemetry files
readonly WEB_SERVER_FILE=/usr/bin/web-server
readonly WEBRTC_FILE=/usr/bin/webrtc
readonly MONITOR_FILE=/usr/bin/Monitor

# Function to check the status of telemetry files
check_telemetry_status() {
  # Check if all three files are disabled
  if [ -f "${WEB_SERVER_FILE}.disabled" ] && [ -f "${WEBRTC_FILE}.disabled" ] && [ -f "${MONITOR_FILE}.disabled" ] &&
       [ ! -f "${WEB_SERVER_FILE}" ] && [ ! -f "${WEBRTC_FILE}" ] && [ ! -f "${MONITOR_FILE}" ]; then
    echo "disabled"
  # Check if all three files are enabled
  elif [ -f "${WEB_SERVER_FILE}" ] && [ -f "${WEBRTC_FILE}" ] && [ -f "${MONITOR_FILE}" ] &&
     [ ! -f "${WEB_SERVER_FILE}.disabled" ] && [ ! -f "${WEBRTC_FILE}.disabled" ] && [ ! -f "${MONITOR_FILE}.disabled" ]; then
    echo "enabled"
  # If neither of the above conditions is true, return an error code
  else
    echo "mixed"  # Indicates mixed state
  fi
}

# Function to display a warning message before disabling telemetry
disable_warning() {
  echo "Warning: Disabling telemetry will prevent the printer"
  echo "         from working with Creality Print and Creality Cloud."
}

# Function to enable telemetry
enable_telemetry() {
  # Rename disabled files to enable telemetry
  mv "${WEB_SERVER_FILE}.disabled" "${WEB_SERVER_FILE}" 2>/dev/null
  mv "${WEBRTC_FILE}.disabled" "${WEBRTC_FILE}" 2>/dev/null
  mv "${MONITOR_FILE}.disabled" "${MONITOR_FILE}" 2>/dev/null

  echo "Telemetry enabled."
}

# Function to disable telemetry
disable_telemetry() {
  # Rename enabled files to disable telemetry
  mv "${WEB_SERVER_FILE}" "${WEB_SERVER_FILE}.disabled" 2>/dev/null
  mv "${WEBRTC_FILE}" "${WEBRTC_FILE}.disabled" 2>/dev/null
  mv "${MONITOR_FILE}" "${MONITOR_FILE}.disabled" 2>/dev/null

  # Kill any running telemetry processes
  killall -q Monitor
  killall -q web-server
  killall -q webrtc

  echo "Telemetry disabled."
}

# Check the status of telemetry files
TELEMETRY_STATUS=$(check_telemetry_status)

# Check if the check_telemetry_status function returned an unexpected value
if [ $? -ne 0 ] && [ $? -ne 1 ] && [ $? -ne 2 ]; then
  echo "Error: Unexpected return value from check_telemetry_status function."
  exit 1
fi

# Handle different telemetry states
if [ "$TELEMETRY_STATUS" == "disabled" ]; then
  # All three files are disabled
  echo "Telemetry is currently disabled."
  read -n 1 -p "Do you want to enable telemetry? (y/n): "
  echo

  case $REPLY in
    [Yy]*)
      enable_telemetry
      ;;
    *)
      echo "Exiting. No changes made."
      exit 0
      ;;
  esac
elif [ "$TELEMETRY_STATUS" == "enabled" ]; then
  # All three files are enabled
  echo "Telemetry is currently enabled."
  disable_warning
  read -n 1 -p "Do you want to disable telemetry? (y/n): "
  echo

  case $REPLY in
    [Yy]*)
      disable_telemetry
      ;;
    *)
      echo "Exiting. No changes made."
      exit 0
      ;;
  esac
else
  # Not all three files are in the same state
  echo "Telemetry files are in an mixed state (some disabled, some enabled)."
  disable_warning
  read -n 1 -p "Do you want to enable or disable all telemetry files? (e/d): "
  echo

  case $REPLY in
    [Ee]*)
      enable_telemetry
      ;;
    [Dd]*)
      disable_telemetry
      ;;
    *)
      echo "Invalid choice. Exiting."
      exit 0
      ;;
  esac
fi

# Remind the user that telemetry changes will take effect only after a reboot
echo "Remember, telemetry changes will take effect only after a reboot."
