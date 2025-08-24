#!/bin/ash

set -e

SCRIPT_DIR=$(readlink -f $(dirname ${0}))

cd ${HOME}

export TMPDIR=/mnt/UDISK/tmp
mkdir -p "${TMPDIR}"

# MUST have Entware installed
if [ ! -f /opt/bin/opkg ]; then
    echo "E: you must have entware installed!"
    exit 1
fi

# handle entware being installed in the current login
if [ -f /etc/profile.d/entware.sh ]; then
    echo ${PATH} | grep -q /opt || source /etc/profile.d/entware.sh
fi

if ! type -p git > /dev/null; then
    opkg install git
fi

progress() {
    echo "#### ${1}"
}

install_virtualenv() {
    progress "Installing virtualenv ..."
    type -p virtualenv > /dev/null || pip install virtualenv

    # update pip to pull pre-built wheels
    if ! grep -qE '^extra-index-url=https://www.piwheels.org/simple$' /etc/pip.conf; then
        echo 'extra-index-url=https://www.piwheels.org/simple' >> /etc/pip.conf
    fi
}

remove_legacy_symlinks() {
    progress "Removing legacy symlinks ..."
    for ENTRY in moonraker moonraker-env; do
        if [ -L ${ENTRY} ]; then
            rm -f ${ENTRY}
        fi
    done
}

fetch_moonraker() {
    progress "Fetching moonraker ..."
    TARGET_DIR="/mnt/UDISK/moonraker"

    # clone moonraker fork
    if [ -d "$TARGET_DIR/.git" ]; then
        git -C "$TARGET_DIR" pull
    else
        git clone https://github.com/Arksine/moonraker.git "$TARGET_DIR"
    fi

    # ensure we are on the master branch
    git -C "$TARGET_DIR" checkout master
}

create_moonraker_venv() {
    export VIRTUALENV_OVERRIDE_APP_DATA=/mnt/UDISK/.virtualenv_cache

    BASE_DIR="/mnt/UDISK"
    VENV_DIR="${BASE_DIR}/moonraker-env"
    MOONRAKER_DIR="${BASE_DIR}/moonraker"

    progress "Creating moonraker venv..."

    test -d "$VENV_DIR" || virtualenv -p /usr/bin/python3 "$VENV_DIR"

    "$VENV_DIR/bin/pip" install \
        --upgrade \
        --find-links="${SCRIPT_DIR}/wheels" \
        --requirement "${MOONRAKER_DIR}/scripts/moonraker-requirements.txt"

    "$VENV_DIR/bin/pip" install lmdb

    python3 "${SCRIPT_DIR}/fix_venv.py" "$VENV_DIR"
}

install_libs() {
    progress "Installing mooonraker libs ..."
    for LIB in ${SCRIPT_DIR}/libs/*.so*; do
        cp ${LIB} /lib/
    done
}

install_wrapper_scripts() {
    progress "Installing wrapper scripts ..."
    test -d /mnt/UDISK/bin || mkdir -p /mnt/UDISK/bin

    # copy all wrapper scripts to /mnt/UDISK/bin
    cp -p ${SCRIPT_DIR}/bin/* /mnt/UDISK/bin/
    chmod 755 /mnt/UDISK/bin/*

    # update the path
    echo 'export PATH=/mnt/UDISK/bin:$PATH' > /etc/profile.d/better-init.sh
}

replace_moonraker() {
    BASE_DIR="/mnt/UDISK"

    progress "Stopping legacy mooonraker ..."
    /etc/init.d/moonraker stop

    progress "Replacing legacy mooonraker with mainline ..."

    # update init script location for new config file location
    rm -f /etc/rc.d/S*moonraker
    cp ${SCRIPT_DIR}/moonraker /etc/init.d/moonraker
    ln -sf /etc/init.d/moonraker /opt/etc/init.d/S56moonraker

    # full copy not symlink here
    cp ${SCRIPT_DIR}/moonraker.conf /mnt/UDISK/printer_data/config/moonraker.conf

    progress "Starting mooonraker ..."
    /etc/init.d/moonraker start
}

modify_moonraker_asvc() {
    progress "Modifying moonraker.asvc ..."
    MOONRAKER_ASVC=/mnt/UDISK/printer_data/moonraker.asvc
    for SERVICE in webrtc cartographer klipper; do
        if ! grep -qE "${SERVICE}" ${MOONRAKER_ASVC}; then
            echo "${SERVICE}" >> ${MOONRAKER_ASVC}
        fi
    done
}

wait_for_moonraker() {
    progress "Waiting for moonraker to start ..."
    count=0
    while ! nc -z 127.0.0.1 7125; do
        if [ $count -gt 60 ]; then
            echo "E: moonraker failed to start!"
            exit 1
        fi
        count=$((count + 1))
        sleep 1
    done
}

install_virtualenv
remove_legacy_symlinks
fetch_moonraker
create_moonraker_venv
install_libs
install_wrapper_scripts
modify_moonraker_asvc
replace_moonraker
wait_for_moonraker
