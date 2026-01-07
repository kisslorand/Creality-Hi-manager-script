#!/bin/sh
# cp_upload_manager.sh
# Manager for cp_upload shim + nginx patch, tied to telemetry state

### CONFIG ###
readonly CP_UPLOAD_SHIM_SRC="/mnt/UDISK/hi-manager/services/cp_upload_shim.py"
readonly CP_UPLOAD_SHIM_DST="/mnt/UDISK/cp_upload_shim.pyc"
readonly CP_UPLOAD_SERVICE_SRC="/mnt/UDISK/hi-manager/services/cp_upload"
readonly CP_UPLOAD_SERVICE_DST="/etc/init.d/cp_upload"
readonly CP_UPLOAD_PATCH="/mnt/UDISK/hi-manager/extras/cp_upload_nginx_patch.sh"
readonly UNSLUNG_DIR="/opt/etc/init.d"
readonly CP_UPLOAD_SYMLINK="$UNSLUNG_DIR/S95cp_upload"

# Telemetry-controlled binaries
readonly TELEMETRY_WEB="/usr/bin/web-server"
readonly TELEMETRY_WEB_OFF="/usr/bin/web-server.disabled"
readonly TELEMETRY_RTC="/usr/bin/webrtc"
readonly TELEMETRY_RTC_OFF="/usr/bin/webrtc.disabled"
readonly TELEMETRY_MON="/usr/bin/Monitor"
readonly TELEMETRY_MON_OFF="/usr/bin/Monitor.disabled"

### HELPERS ###
check_telemetry_status() {
    if [ -f "$TELEMETRY_WEB" ] && [ -f "$TELEMETRY_RTC" ] && [ -f "$TELEMETRY_MON" ]; then
        echo "enabled"
    elif [ -f "$TELEMETRY_WEB_OFF" ] && [ -f "$TELEMETRY_RTC_OFF" ] && [ -f "$TELEMETRY_MON_OFF" ]; then
        echo "disabled"
    else
        echo "mixed"
    fi
}

reload_nginx() {
    if nginx -t >/dev/null 2>&1; then
        nginx -s reload
    else
        echo "⚠️ nginx config invalid, not reloading"
        return 1
    fi
}

### ACTIONS ###
do_enable() {
    state=$(check_telemetry_status)
    if [ "$state" = "enabled" ]; then
        if [ ! -e "$CP_UPLOAD_SYMLINK" ]; then
            ln -s "$CP_UPLOAD_SERVICE_DST" "$CP_UPLOAD_SYMLINK"
            echo "cp_upload enabled (will start on next boot)"
        else
            echo "cp_upload already enabled"
        fi

        # Start service only if not already running
        if ! pgrep -f cp_upload_shim >/dev/null; then
            $CP_UPLOAD_SERVICE_DST start
            echo "cp_upload started"
        else
            echo "cp_upload already running"
        fi

        # Patch nginx right away so effect is immediate
        "$CP_UPLOAD_PATCH" patch && reload_nginx
    else
        echo "❌ Cannot enable cp_upload, telemetry is $state"
    fi
}

do_disable() {
    state=$(check_telemetry_status)
    if [ "$state" = "disabled" ]; then
        if [ -e "$CP_UPLOAD_SYMLINK" ]; then
            # Unpatch nginx right away so effect is immediate
            "$CP_UPLOAD_PATCH" unpatch && reload_nginx

            # Stop service only if running
            if pgrep -f cp_upload_shim >/dev/null; then
                $CP_UPLOAD_SERVICE_DST stop
                echo "cp_upload stopped"
            else
                echo "cp_upload already stopped"
            fi

            rm -f "$CP_UPLOAD_SYMLINK"
            echo "cp_upload disabled (won’t start on boot)"
        else
            echo "cp_upload already disabled"
        fi
    else
        echo "❌ Cannot disable cp_upload, telemetry is $state"
    fi
}

do_install() {
    echo ">>> Installing cp_upload..."

    # Compile shim
    if [ -f "$CP_UPLOAD_SHIM_SRC" ]; then
        python3 -m compileall -b "$CP_UPLOAD_SHIM_SRC"
        if [ -f "${CP_UPLOAD_SHIM_SRC}c" ]; then
            cp -f "${CP_UPLOAD_SHIM_SRC}c" "$CP_UPLOAD_SHIM_DST"
        else
            echo "? Shim compile failed: ${CP_UPLOAD_SHIM_SRC}c not found"
            exit 1
        fi
        chmod 755 /mnt/UDISK/cp_upload_shim.pyc
        echo "Shim compiled to $CP_UPLOAD_SHIM_DST"
    else
        echo "❌ Shim source not found: $CP_UPLOAD_SHIM_SRC"
        exit 1
    fi

    # Install service
    if [ -f "$CP_UPLOAD_SERVICE_SRC" ]; then
        cp -f "$CP_UPLOAD_SERVICE_SRC" "$CP_UPLOAD_SERVICE_DST"
        chmod +x "$CP_UPLOAD_SERVICE_DST"
        echo "Service installed to $CP_UPLOAD_SERVICE_DST"
    else
        echo "❌ Service script not found: $CP_UPLOAD_SERVICE_SRC"
        exit 1
    fi

    # Act depending on telemetry
    state=$(check_telemetry_status)
    case "$state" in
        enabled)
            echo "Telemetry is ON → enabling cp_upload"
            do_enable
            ;;
        disabled)
            echo "Telemetry is OFF → leaving cp_upload disabled"
            ;;
        mixed)
            echo "⚠️ Telemetry is in mixed state → cp_upload not enabled"
            ;;
    esac
}

do_status() {
    # Check install state first
    if [ ! -x "$CP_UPLOAD_SERVICE_DST" ] || [ ! -f "$CP_UPLOAD_SHIM_DST" ]; then
        echo "cp_upload: not installed"
    else
        # Boot-time enable/disable (symlink)
        if [ -L "$CP_UPLOAD_SYMLINK" ]; then
            boot_status="enabled"
        else
            boot_status="disabled"
        fi

        # Runtime (running or not)
        if netstat -tlnp 2>/dev/null | grep -q ":8090.*python"; then
            run_status="running"
        else
            run_status="not running"
        fi

        echo "cp_upload: $boot_status, $run_status"
    fi

    # nginx patch state
    if grep -q "CP_UPLOAD_LOC_BEGIN" /etc/nginx/nginx.conf 2>/dev/null; then
        echo "nginx: patched"
    else
        echo "nginx: unpatched"
    fi
}

### MAIN ###
case "$1" in
    install) do_install ;;
    enable)  do_enable ;;
    disable) do_disable ;;
    status)  do_status ;;
    *)
        echo "Usage: $0 {install|enable|disable|status}"
        exit 1
        ;;
esac
