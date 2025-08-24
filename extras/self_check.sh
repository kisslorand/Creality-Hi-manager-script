#!/bin/sh

# Set the system config file variable
CONFIG_FILE="/mnt/UDISK/creality/userdata/config/system_config.json"

# Check if the value is already 0
if grep -q '"self_test_sw":0' "$CONFIG_FILE"; then
  echo "Startup self-check process is already disabled, no changes made."
else
  # Replace the value with 0
  sed -i 's/"self_test_sw":1/"self_test_sw":0/' "$CONFIG_FILE"
  echo "Startup self-check process disabled."
fi
