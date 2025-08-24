#!/bin/sh

NGINX_CONF="/etc/nginx/nginx.conf"   # adjust if needed

if ! grep -q "listen 80;" "$NGINX_CONF"; then
  echo "Adding port 80 to Nginx configuration..."
  sed -i "/listen [0-9]\+ default_server/a \        listen 80;" "$NGINX_CONF"
  echo "Restarting Nginx..."
  /etc/init.d/nginx restart
  echo "Nginx is now listening on both ports 80 and 4408."
else
  echo "Port 80 is already added to Nginx configuration. No changes made."
fi
