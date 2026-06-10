FROM us-central1-docker.pkg.dev/cloud-workstations-images/predefined/base

ARG DEBIAN_FRONTEND=noninteractive

# Force CRD to use the virtual framebuffer (Xvfb) instead of Xorg (Crucial for Docker containers)
ENV CHROME_REMOTE_DESKTOP_USE_XVFB=1

# 1. Install Keys, Chrome Remote Desktop Repository, and Core UI Packages
RUN apt-get update && apt-get install -y curl gpg && \
    curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /etc/apt/trusted.gpg.d/chrome-remote-desktop.gpg && \
    echo "deb [arch=amd64 signed-by=/etc/apt/trusted.gpg.d/chrome-remote-desktop.gpg] https://dl.google.com/linux/chrome-remote-desktop/deb stable main" > /etc/apt/sources.list.d/chrome-remote-desktop.list && \
    apt-get update && \
    apt-get install -y \
        chrome-remote-desktop \
        xfce4 \
        desktop-base \
        dbus-x11 \
        xscreensaver \
        python3-psutil \
        python3-packaging \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 2. Configure Global Session Fallback (Strictly following the Google Architecture Guide)
RUN echo "exec /etc/X11/Xsession /usr/bin/xfce4-session" > /etc/chrome-remote-desktop-session

# 3. Apply Container-Specific Compatibility Patches
# Patch A: Disable systemd dependency in CRD Python runtime
RUN sed -i 's/USE_SYSTEMD = True/USE_SYSTEMD = False/g' /opt/google/chrome-remote-desktop/chrome-remote-desktop

# Patch B: Mock systemctl so start-host binary doesn't crash during registration
RUN echo '#!/bin/bash' > /usr/bin/systemctl && \
    echo 'exit 0' >> /usr/bin/systemctl && \
    chmod +x /usr/bin/systemctl

# Patch C: Modify the PAM configurations to bypass loginuid checks inside container
RUN sed -i 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' /etc/pam.d/common-session 2>/dev/null || true && \
    sed -i 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' /etc/pam.d/chrome-remote-desktop 2>/dev/null || true

# 4. Create the Cloud Workstations Runtime Startup Script
RUN printf '#!/bin/bash\n\
TARGET_USER="user"\n\
HOME_DIR="/home/$TARGET_USER"\n\
CONFIG_DIR="$HOME_DIR/.config/chrome-remote-desktop"\n\
\n\
# Fix CRD group membership dynamically\n\
groupadd -f chrome-remote-desktop\n\
usermod -aG chrome-remote-desktop $TARGET_USER || true\n\
\n\
# Fix X11 Socket permissions so Xvfb can create virtual displays\n\
mkdir -p /tmp/.X11-unix\n\
chmod 1777 /tmp/.X11-unix\n\
chown root:root /tmp/.X11-unix\n\
\n\
# Setup DBus System Bus\n\
mkdir -p /var/run/dbus\n\
rm -f /var/run/dbus/pid\n\
dbus-daemon --system --fork\n\
\n\
# Start CRD service if the user has authenticated\n\
if ls "$CONFIG_DIR"/host*.json >/dev/null 2>&1; then\n\
    echo "Starting Chrome Remote Desktop..."\n\
    export CHROME_REMOTE_DESKTOP_USE_XVFB=1\n\
    # Use -E to preserve environment variables like CHROME_REMOTE_DESKTOP_USE_XVFB when switching users\n\
    sudo -H -E -u $TARGET_USER bash -c "/opt/google/chrome-remote-desktop/chrome-remote-desktop --start" &\n\
else\n\
    echo "CRD not configured yet. Run the start-host command in the terminal."\n\
fi\n' > /etc/workstation-startup.d/010_start-crd.sh && \
chmod +x /etc/workstation-startup.d/010_start-crd.sh
