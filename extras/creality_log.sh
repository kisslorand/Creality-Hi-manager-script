#!/bin/sh

CONFIG_FILE="/mnt/UDISK/creality/userdata/log/log_config.json"

# Get current logging state
VALUE=$(grep -o '"log_route":[0-9]*' "$CONFIG_FILE" | cut -d':' -f2-)

# Present current state to user
if [ "$VALUE" = "1" ]; then
  echo "Logging to file is currently enabled."
else
  echo "Logging to file is currently disabled."
fi

# Ask user if they want to toggle it
read -p "Do you want to toggle the logging state? (y/n) " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
  # Toggle logging state
  if [ "$VALUE" = "1" ]; then
    sed -i 's/"log_route":.*/"log_route":0/' "$CONFIG_FILE"
    echo "Logging to file disabled."
  else
    sed -i 's/"log_route":.*/"log_route":1/' "$CONFIG_FILE"
    echo "Logging to file enabled."
  fi
else
  echo "No toggle occurred."
  exit 0
fi

echo "Please restart the printer for changes to take effect."
