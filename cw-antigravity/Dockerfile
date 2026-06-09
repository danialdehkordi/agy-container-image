FROM us-central1-docker.pkg.dev/cloud-workstations-images/predefined/base

ARG DEBIAN_FRONTEND=noninteractive

# 1. Install Desktop Environment (XFCE) and requirements
RUN apt-get update && apt-get install -y \
    xvfb \
    xfce4 \
    desktop-base \
    dbus-x11 \
    wget \
    curl \
    gnupg \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 2. Install Google Chrome & Chrome Remote Desktop
RUN wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/google-chrome-keyring.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome-keyring.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list && \
    wget -q -O /tmp/crd.deb https://dl.google.com/linux/direct/chrome-remote-desktop_current_amd64.deb && \
    apt-get update && \
    apt-get install -y google-chrome-stable /tmp/crd.deb && \
    rm /tmp/crd.deb && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 3. CRUCIAL FIXES FOR DOCKER
# Fix A: Disable systemd dependency in CRD (Prevents the "stuck at starting" issue)
RUN sed -i 's/USE_SYSTEMD = True/USE_SYSTEMD = False/g' /opt/google/chrome-remote-desktop/chrome-remote-desktop

# Fix B: Fix Chrome Sandbox crashing in Docker
RUN dpkg-divert --add --rename --divert /usr/bin/google-chrome-stable.real /usr/bin/google-chrome-stable && \
    printf '#!/bin/bash\nexec /usr/bin/google-chrome-stable.real --no-sandbox --disable-dev-shm-usage "$@"\n' > /usr/bin/google-chrome-stable && \
    chmod +x /usr/bin/google-chrome-stable

# Fix C: Manually create the CRD group and add default user to it
RUN groupadd -f chrome-remote-desktop && \
    usermod -aG chrome-remote-desktop user
    
# 4. Create the Cloud Workstations Startup Script
# This runs every time the workstation boots to configure DBus and start the CRD daemon
RUN printf '#!/bin/bash\n\
set -e\n\
TARGET_USER="user"\n\
HOME_DIR="/home/$TARGET_USER"\n\
CONFIG_DIR="$HOME_DIR/.config/chrome-remote-desktop"\n\
\n\
# Setup XFCE Session file\n\
if [ ! -f "$HOME_DIR/.chrome-remote-desktop-session" ]; then\n\
    echo "exec /usr/bin/startxfce4" > "$HOME_DIR/.chrome-remote-desktop-session"\n\
    chown $TARGET_USER:$TARGET_USER "$HOME_DIR/.chrome-remote-desktop-session"\n\
    chmod +x "$HOME_DIR/.chrome-remote-desktop-session"\n\
fi\n\
\n\
# Setup DBus (Required for XFCE/CRD to talk to each other)\n\
mkdir -p /var/run/dbus\n\
rm -f /var/run/dbus/pid\n\
dbus-daemon --system --fork\n\
\n\
# Start CRD service if the user has authenticated\n\
if ls "$CONFIG_DIR"/host*.json >/dev/null 2>&1; then\n\
    echo "Starting Chrome Remote Desktop..."\n\
    sudo -H -u $TARGET_USER bash -c "/opt/google/chrome-remote-desktop/chrome-remote-desktop --start" &\n\
else\n\
    echo "CRD not configured yet. Run the start-host command in the terminal."\n\
fi\n' > /etc/workstation-startup.d/010_start-crd.sh && \
chmod +x /etc/workstation-startup.d/010_start-crd.sh

