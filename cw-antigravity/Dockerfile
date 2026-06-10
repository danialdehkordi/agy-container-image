FROM us-central1-docker.pkg.dev/cloud-workstations-images/predefined/base

ARG DEBIAN_FRONTEND=noninteractive

# 1. Install System Dependencies and XFCE
RUN apt-get update && apt-get install -y \
    xvfb \
    xfce4 \
    xfce4-goodies \
    xbase-clients \
    dbus-x11 \
    psmisc \
    python3-psutil \
    xserver-xorg-video-dummy \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 2. Install Google Chrome and Chrome Remote Desktop
RUN wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/google-chrome-keyring.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome-keyring.gpg] http://dl.google.com/linux/chrome/deb/ stable main" | tee /etc/apt/sources.list.d/google-chrome.list > /dev/null && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome-keyring.gpg] https://dl.google.com/linux/chrome-remote-desktop/deb stable main" | tee /etc/apt/sources.list.d/chrome-remote-desktop.list > /dev/null && \
    apt-get update && \
    apt-get install -y google-chrome-stable chrome-remote-desktop && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Chrome Sandbox Fix
RUN dpkg-divert --add --rename --divert /usr/bin/google-chrome-stable.real /usr/bin/google-chrome-stable && \
    echo '#!/bin/bash' > /usr/bin/google-chrome-stable && \
    echo 'exec /usr/bin/google-chrome-stable.real --no-sandbox --disable-dev-shm-usage "$@"' >> /usr/bin/google-chrome-stable && \
    chmod +x /usr/bin/google-chrome-stable

# 3. Mock systemctl (kept for compatibility with debian package updates)
RUN echo '#!/bin/bash' > /usr/bin/systemctl \
    && echo 'echo "Mock systemctl: $@"' >> /usr/bin/systemctl \
    && echo 'exit 0' >> /usr/bin/systemctl \
    && chmod +x /usr/bin/systemctl

# 4. Patch Chrome Remote Desktop to bypass systemd in container environments
RUN sed -i 's|/run/systemd/system|/run/systemd/system_disabled_for_docker|g' /opt/google/chrome-remote-desktop/chrome-remote-desktop

# 4b. Fix X11 permission wrapper to allow non-root users to start the dummy X server
RUN mkdir -p /etc/X11 && echo "allowed_users=anybody" > /etc/X11/Xwrapper.config

# 5. Install Antigravity
RUN mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://us-central1-apt.pkg.dev/doc/repo-signing-key.gpg | gpg --dearmor -o /etc/apt/keyrings/antigravity-repo-key.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/antigravity-repo-key.gpg] https://us-central1-apt.pkg.dev/projects/antigravity-auto-updater-dev/ antigravity-debian main" | tee /etc/apt/sources.list.d/antigravity.list > /dev/null && \
    apt-get update && \
    apt-get install -y antigravity && \
    dpkg-divert --add --rename --divert /usr/bin/antigravity.real /usr/bin/antigravity && \
    echo '#!/bin/bash' > /usr/bin/antigravity && \
    echo 'exec /usr/bin/antigravity.real --no-sandbox --disable-dev-shm-usage --disable-gpu "$@"' >> /usr/bin/antigravity && \
    chmod +x /usr/bin/antigravity

# 6. Runtime customization scripts
COPY startup-scripts/ /etc/workstation-startup.d/
RUN chmod +x /etc/workstation-startup.d/*
