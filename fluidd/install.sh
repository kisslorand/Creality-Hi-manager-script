#!/bin/sh
set -e

# Ensure proper PATH (for Entware)
if [ -f /etc/profile.d/entware.sh ]; then
    . /etc/profile.d/entware.sh
fi
export PATH=/opt/bin:/opt/sbin:/bin:/sbin:/usr/bin:/usr/sbin

SCRIPT_DIR=$(readlink -f "$(dirname "$0")")
FLUIDD_DIR=/mnt/UDISK/fluidd
MOONRAKER_CONF_DIR=/mnt/UDISK/printer_data/config

# Check that moonraker is already installed
if [ ! -f "${MOONRAKER_CONF_DIR}/moonraker.conf" ]; then
    echo "E: you must have installed/updated moonraker first!"
    exit 1
fi

# Must have Entware installed
if [ ! -x /opt/bin/opkg ]; then
    echo "E: Entware not found! Please install Entware before running this script."
    exit 1
fi

# Ensure unzip is available
if ! type unzip >/dev/null 2>&1; then
    echo "I: installing unzip..."
    /opt/bin/opkg update
    /opt/bin/opkg install unzip
fi

# Ensure curl is available
if ! type curl >/dev/null 2>&1; then
    echo "I: installing curl..."
    /opt/bin/opkg update
    /opt/bin/opkg install curl
fi

# Clean old fluidd directory
rm -rf "${FLUIDD_DIR}"
mkdir -p "${FLUIDD_DIR}"
cd "${FLUIDD_DIR}"

# Download and extract fluidd
echo "I: downloading fluidd..."
curl -s -L -o fluidd.zip https://github.com/fluidd-core/fluidd/releases/latest/download/fluidd.zip
unzip fluidd.zip
rm -f fluidd.zip

# Update nginx configuration to reflect new location
sed -i "s|/usr/share/fluidd|${FLUIDD_DIR}|g" /etc/nginx/nginx.conf

# Optional: change nginx port to 80 (uncomment if desired)
# sed -i 's|listen 4408 default_server|listen 80 default_server|g' /etc/nginx/nginx.conf

# Restart nginx
/etc/init.d/nginx restart || echo "W: nginx restart failed, check logs."

# Register fluidd with moonraker's update manager if missing
if ! grep -q "\[update_manager fluidd\]" "${MOONRAKER_CONF_DIR}/moonraker.conf"; then
    cat <<-EOF >> "${MOONRAKER_CONF_DIR}/moonraker.conf"

    [update_manager fluidd]
    type: web
    channel: beta
    repo: fluidd-core/fluidd
    path: /mnt/UDISK/fluidd
EOF
fi

# Restart moonraker to apply changes
/etc/init.d/moonraker restart || echo "W: moonraker restart failed, check logs."

echo "I: Fluidd installation completed successfully."
