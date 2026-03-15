#!/bin/bash
set -e

# --- 1. Variables ---
TARGET_USER="user"
HOME_DIR="/home/$TARGET_USER"
CONFIG_DIR="$HOME_DIR/.config/chrome-remote-desktop"

# --- 2. Fix Permissions & Directories (Runtime) ---
mkdir -p "$HOME_DIR/.pki/nssdb"
chown -R $TARGET_USER:$TARGET_USER "$HOME_DIR/.pki"
chmod 700 "$HOME_DIR/.pki"

groupadd -f chrome-remote-desktop
usermod -aG chrome-remote-desktop $TARGET_USER

# --- 3. Setup Session File ---
if [ ! -f "$HOME_DIR/.chrome-remote-desktop-session" ]; then
    echo "Creating default .chrome-remote-desktop-session file."
    cat <<'EOF' > "$HOME_DIR/.chrome-remote-desktop-session"
#!/bin/bash
exec > /tmp/chrome-session.log 2>&1

# 1. Clean up environment from previous failed attempts
unset DBUS_SESSION_BUS_ADDRESS
unset XDG_RUNTIME_DIR

# 2. Set XFCE variables
export DESKTOP_SESSION=xfce
export GDMSESSION=xfce
export XDG_CURRENT_DESKTOP=XFCE
# Vital for finding default configs in a container
export XDG_CONFIG_DIRS=/etc/xdg:/etc/xdg/xfce4

# 3. Clean up stale session cache (prevents "failsafe" loops)
rm -rf ~/.cache/sessions

# 4. Start XFCE wrapped in its own DBus session
# This ensures xfconfd can always talk to the bus
echo "Starting XFCE with dbus-launch..."
exec /usr/bin/dbus-launch --exit-with-session /usr/bin/startxfce4
EOF
    chown $TARGET_USER:$TARGET_USER "$HOME_DIR/.chrome-remote-desktop-session"
    chmod +x "$HOME_DIR/.chrome-remote-desktop-session"
fi

# --- 4. Setup DBus (Runtime) ---
if [ ! -f /var/lib/dbus/machine-id ]; then
    mkdir -p /var/lib/dbus
    dbus-uuidgen > /var/lib/dbus/machine-id
fi

mkdir -p /var/run/dbus
rm -f /var/run/dbus/pid
dbus-daemon --system --fork

mkdir -p "$CONFIG_DIR"
chown -R $TARGET_USER:$TARGET_USER "$HOME_DIR"

# --- 5. Start Service ---
if ls "$CONFIG_DIR"/host*.json >/dev/null 2>&1; then
    echo "Starting Chrome Remote Desktop Service..."
    sudo -H -u $TARGET_USER bash -c "/opt/google/chrome-remote-desktop/chrome-remote-desktop --start" &
else
    echo "No configuration file matching $CONFIG_DIR/host*.json found. Skipping service start."
    echo "SSH into this container after launch and follow the instructions at https://remotedesktop.google.com/headless to register the remote service for the first time."
fi

