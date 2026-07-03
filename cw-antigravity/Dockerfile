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

# 5. Install Antigravity Tools (Antigravity 2.0, CLI and IDE)
ARG AGY_CLI_URL="https://antigravity.google/cli/install.sh"
ARG AGY_IDE_URL="https://edgedl.me.gvt1.com/edgedl/release2/j0qc3/antigravity/stable/2.1.1-6123990880747520/linux-x64/Antigravity%20IDE.tar.gz"
ARG AGY_2_0_URL="https://storage.googleapis.com/antigravity-public/antigravity-hub/2.2.1-5287492581195776/linux-x64/Antigravity.tar.gz"

RUN curl -fsSL "$AGY_CLI_URL" | bash -s -- --dir /usr/local/bin

RUN mkdir -p /opt/agy-ide /opt/agy2 \
    && wget -qO- "$AGY_IDE_URL" | tar -xzf - -C /opt/agy-ide --strip-components=1 \
    && wget -qO- "$AGY_2_0_URL" | tar -xzf - -C /opt/agy2 --strip-components=1 \
    && echo '#!/bin/bash' > /usr/local/bin/antigravity-ide \
    && echo 'exec /opt/agy-ide/antigravity-ide --no-sandbox --disable-dev-shm-usage "$@"' >> /usr/local/bin/antigravity-ide \
    && chmod +x /usr/local/bin/antigravity-ide \
    && echo '#!/bin/bash' > /usr/local/bin/antigravity \
    && echo 'exec /opt/agy2/antigravity --no-sandbox --disable-dev-shm-usage "$@"' >> /usr/local/bin/antigravity \
    && chmod +x /usr/local/bin/antigravity

# 6. Add Desktop Entries
RUN mkdir -p /usr/share/applications && \
    echo "[Desktop Entry]" > /usr/share/applications/antigravity-ide.desktop && \
    echo "Name=Antigravity IDE" >> /usr/share/applications/antigravity-ide.desktop && \
    echo "Comment=Google Antigravity IDE" >> /usr/share/applications/antigravity-ide.desktop && \
    echo "Exec=/usr/local/bin/antigravity-ide" >> /usr/share/applications/antigravity-ide.desktop && \
    echo "Icon=utilities-terminal" >> /usr/share/applications/antigravity-ide.desktop && \
    echo "Terminal=false" >> /usr/share/applications/antigravity-ide.desktop && \
    echo "Type=Application" >> /usr/share/applications/antigravity-ide.desktop && \
    echo "Categories=Development;Utility;" >> /usr/share/applications/antigravity-ide.desktop

RUN echo "[Desktop Entry]" > /usr/share/applications/antigravity.desktop && \
    echo "Name=Antigravity 2.0" >> /usr/share/applications/antigravity.desktop && \
    echo "Comment=Google Antigravity 2.0" >> /usr/share/applications/antigravity.desktop && \
    echo "Exec=/usr/local/bin/antigravity" >> /usr/share/applications/antigravity.desktop && \
    echo "Icon=utilities-terminal" >> /usr/share/applications/antigravity.desktop && \
    echo "Terminal=false" >> /usr/share/applications/antigravity.desktop && \
    echo "Type=Application" >> /usr/share/applications/antigravity.desktop && \
    echo "Categories=Development;Utility;" >> /usr/share/applications/antigravity.desktop

# 7. Runtime customization scripts
COPY startup-scripts/ /etc/workstation-startup.d/
RUN chmod +x /etc/workstation-startup.d/*
