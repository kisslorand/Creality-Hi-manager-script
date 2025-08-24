#!/bin/sh

SERVICE_NAME="adbd"

# Check if service is enabled
if /etc/init.d/$SERVICE_NAME enabled; then
  echo "The $SERVICE_NAME service is currently enabled."
else
  echo "The $SERVICE_NAME service is currently disabled."
fi

# Ask user if they want to toggle it
read -p "Do you want to toggle the $SERVICE_NAME service? (y/n) " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
  if /etc/init.d/$SERVICE_NAME enabled; then
    /etc/init.d/$SERVICE_NAME disable
    echo "The $SERVICE_NAME service has been disabled."
  else
    /etc/init.d/$SERVICE_NAME enable
    echo "The $SERVICE_NAME service has been enabled."
  fi
else
  echo "No toggle occurred."
fi
