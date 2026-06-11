# Chrome Remote Desktop (XFCE4) on Google Cloud Workstations

This repository contains the Docker configuration and runtime startup scripts to build and deploy a lightweight, high-performance **XFCE4 Desktop Environment** accessible via **Google Chrome Remote Desktop (CRD)** inside a Google Cloud Workstation.

It is specifically optimized for running graphical applications like **Antigravity** with maximum performance and stability.

---

## 🚀 Architecture & Logic (How It Works)

To make Chrome Remote Desktop run reliably in a headless container environment without systemd, several key engineering hurdles were solved:

### 1. Bypassing Systemd with `--child-process`
Normally, the `chrome-remote-desktop --start` command tries to register and start itself via systemd (`systemctl`). Since Cloud Workstations run in containers where systemd is either mocked or unavailable, calling the default start command would fail.
* **Solution:** We run the daemon directly using `/opt/google/chrome-remote-desktop/chrome-remote-desktop --start --child-process` in the background. This forces CRD to run directly as a standard user process, bypassing systemd entirely.

### 2. Dynamic Hostname MD5 Synchronization
When you register a headless workstation using Google's setup portal, CRD generates credentials and saves them to a global system path: `/etc/chrome-remote-desktop/host.json`.
However, the user-space CRD daemon expects to find this file in the user's home configuration directory, specifically named using the **MD5 hash of the workstation's hostname** (e.g., `~/.config/chrome-remote-desktop/host#<MD5_HASH>.json`).
* **Solution:** On every boot, the startup script (`/etc/workstation-startup.d/script.sh`) dynamically:
  1. Computes the MD5 hash of the current workstation hostname.
  2. Copies `/etc/chrome-remote-desktop/host.json` to the correct location: `/home/user/.config/chrome-remote-desktop/host#<MD5_HASH>.json`.
  3. Updates ownership (`user:user`) and permissions (`600`) so the service can read it.

### 3. Headless X11 Permissive Wrapper
By default, modern Debian security policies restrict non-root users from launching an X Server (Xorg) in a headless, non-interactive shell.
* **Solution:** We inject a custom `/etc/X11/Xwrapper.config` with `allowed_users=anybody`. This allows the non-root `user` to start the virtual display server (`Xvfb`) required by CRD to render XFCE4.

---

## 🛠️ Step-by-Step Setup Guide

Follow these exact steps whenever you spin up a new Cloud Workstations instance or rebuild your container image.

### Step 1: Rebuild & Deploy the Container Image
Any changes committed and pushed to the `master` branch of this repository will automatically trigger a Google Cloud Build build via your CI/CD pipeline, pushing the updated image to your Artifact Registry.
```bash
git add .
git commit -m "docs: add comprehensive README explaining setup and fixes"
git push origin master
```

### Step 2: Configure Your Cloud Workstation
Ensure your Cloud Workstation configuration is pointed to use your custom container image from Artifact Registry:
`us-central1-docker.pkg.dev/<PROJECT_ID>/<REPOSITORY>/<IMAGE_NAME>:<TAG>`

### Step 3: Register a New Workstation Instance (First-Time Boot)
When you start a fresh Workstation instance, it must be registered with Google Remote Desktop to generate your unique credentials:
1. Open your web browser on your personal computer and go to **[remotedesktop.google.com/headless](https://remotedesktop.google.com/headless)**.
2. Sign in, click **Begin**, then click **Next**, and click **Authorize**.
3. Under **Debian Linux**, copy the terminal command (which begins with `DISPLAY= /opt/google/chrome-remote-desktop/start-host ...`).
4. Open your Cloud Workstation terminal and paste and run the copied command.
5. Enter a **6-digit PIN** of your choice and confirm it.

### Step 4: Run the Startup Script
Now that `/etc/chrome-remote-desktop/host.json` exists, run the container's built-in startup script to perform the synchronization and launch the remote desktop service in the background:
```bash
sudo /etc/workstation-startup.d/script.sh
```

### Step 5: Connect to Your Desktop
1. Go to **[remotedesktop.google.com/access](https://remotedesktop.google.com/access)**.
2. You will see your workstation name listed under your devices (it will display as **Online**).
3. Click on it, enter the **6-digit PIN** you set in Step 3, and your interactive XFCE4 desktop session will load!

---

## 🔍 Troubleshooting & Verification

If your remote desktop session does not connect, use these commands to verify the system's state:

### 1. Verify Configuration Sync
Confirm that the host file exists and was correctly copied with the MD5 hash matching your workstation's hostname:
```bash
# Calculate expected filename
echo "Expected config filename: host#$(echo -n $(hostname) | md5sum | cut -d' ' -f1).json"

# Check if the user config exists and has the correct permissions
ls -la /home/user/.config/chrome-remote-desktop/
```

### 2. Verify Running Processes
Run this command to check if all necessary desktop services are running:
```bash
ps aux | grep -E 'chrome-remote-desktop|Xorg|Xvfb|xfce4|startxfce' | grep -v grep
```
*You should see several active processes for `chrome-remote-desktop` and the X server.*

### 3. Inspect Desktop Logs
If the connection is made but you see a black screen or it disconnects, check the virtual desktop session logs:
```bash
cat /tmp/chrome-session.log
```
*(This log contains startup messages for DBus, the session manager, and XFCE4).*
