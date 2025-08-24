#!/bin/sh
set -e

# This script moves the root user's home directory from /root to /mnt/UDISK/root
# and updates the /etc/passwd file accordingly.

# Check if the root user's home directory is already set to /mnt/UDISK/root
if grep -qE 'root.*UDISK' /etc/passwd; then
    echo "I: root user home directory already set to /mnt/UDISK/root, exiting..."
    exit 0
fi

# Move the root user's home directory to /mnt/UDISK/root
mkdir -p /mnt/UDISK/root
rsync -a --remove-source-files /root/ /mnt/UDISK/root/

# Remove the original home directory
rm -fr /overlay/upper/root/*

# Update the /etc/passwd file
sed -i 's,/root,/mnt/UDISK/root,' /etc/passwd

# Sync the changes to disk
sync

# Log a message and terminate the SSH session to ensure changes take effect
echo "I: you need to log back in for changes to take effect!"
echo "I: logging you out now!"
echo "I: please reconnect to continue"
# terminate the SSH session
pgrep dropbear | grep -v "^$(pgrep -o dropbear)$" | xargs kill -9
