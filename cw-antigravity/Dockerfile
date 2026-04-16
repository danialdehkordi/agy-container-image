FROM us-central1-docker.pkg.dev/cloud-workstations-images/predefined/base

ARG DEBIAN_FRONTEND=noninteractive

# 1. Add ALL external repositories and keys first
RUN rm -rf /var/lib/apt/lists/* && apt-get clean && \
    mkdir -p /etc/apt/keyrings && \
    # Swap out flaky global mirror for the more stable US mirror
    sed -i 's/archive.ubuntu.com/us.archive.ubuntu.com/g' /etc/apt/sources.list.d/ubuntu.sources 2>/dev/null || true && \
    sed -i 's/archive.ubuntu.com/us.archive.ubuntu.com/g' /etc/apt/sources.list 2>/dev/null || true && \
    # --- Yarn Key & Repo ---
    curl -fsSL https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor -o /usr/share/keyrings/yarnkey.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/yarnkey.gpg] https://dl.yarnpkg.com/debian stable main" | tee /etc/apt/sources.list.d/yarn.list > /dev/null && \
    # --- Chrome Key & Repo ---
    wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/google-chrome-keyring.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome-keyring.gpg] http://dl.google.com/linux/chrome/deb/ stable main" | tee /etc/apt/sources.list.d/google-chrome.list > /dev/null && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome-keyring.gpg] https://dl.google.com/linux/chrome-remote-desktop/deb stable main" | tee /etc/apt/sources.list.d/chrome-remote-desktop.list > /dev/null && \
    # --- Antigravity Key & Repo ---
    curl -fsSL https://us-central1-apt.pkg.dev/doc/repo-signing-key.gpg | gpg --dearmor -o /etc/apt/keyrings/antigravity-repo-key.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/antigravity-repo-key.gpg] https://us-central1-apt.pkg.dev/projects/antigravity-auto-updater-dev/ antigravity-debian main" | tee /etc/apt/sources.list.d/antigravity.list > /dev/null && \
    # --- Execute Update and Install ---
    apt-get update && apt-get install -y --no-install-recommends \
    xvfb \
    xfce4 \
    xfce4-goodies \
    xbase-clients \
    dbus-x11 \
    psmisc \
    python3-psutil \
    xserver-xorg-video-dummy \
    google-chrome-stable \
    chrome-remote-desktop \
    antigravity \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 3. Apply configurations, diverts, and mock scripts
RUN dpkg-divert --add --rename --divert /usr/bin/google-chrome-stable.real /usr/bin/google-chrome-stable && \
    echo '#!/bin/bash' > /usr/bin/google-chrome-stable && \
    echo 'exec /usr/bin/google-chrome-stable.real --no-sandbox --disable-dev-shm-usage "$@"' >> /usr/bin/google-chrome-stable && \
    chmod +x /usr/bin/google-chrome-stable && \
    # Mock systemctl
    echo '#!/bin/bash' > /usr/bin/systemctl && \
    echo 'echo "Mock systemctl: $@"' >> /usr/bin/systemctl && \
    echo 'exit 0' >> /usr/bin/systemctl && \
    chmod +x /usr/bin/systemctl && \
    # Setup Antigravity Wrapper
    echo "Installed Antigravity Version: $(dpkg-query -W -f='${Version}' antigravity)" && \
    dpkg-divert --add --rename --divert /usr/bin/antigravity.real /usr/bin/antigravity && \
    echo '#!/bin/bash' > /usr/bin/antigravity && \
    echo 'exec /usr/bin/antigravity.real --no-sandbox --disable-dev-shm-usage --disable-gpu "$@"' >> /usr/bin/antigravity && \
    chmod +x /usr/bin/antigravity

# 4. Runtime customization scripts
COPY startup-scripts/ /etc/workstation-startup.d/
RUN chmod +x /etc/workstation-startup.d/*
