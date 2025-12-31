#!/bin/bash

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (sudo ./setup_server.sh)"
  exit
fi

echo "--- Starting Headless Server Setup ---"

# 1. System Update & Dependencies
echo "[1/6] Updating system and installing base dependencies..."
apt update && apt upgrade -y
apt install -y curl wget gnupg2 ca-certificates lsb-release ubuntu-keyring software-properties-common

# 2. Add Repositories (PPAs and Official Vendor Repos)
echo "[2/6] Adding repositories..."

# Add Ondrej PPA for Apache2 and Nginx (Best for Ubuntu)
add-apt-repository ppa:ondrej/apache2 -y
add-apt-repository ppa:ondrej/nginx -y

# Add OpenLiteSpeed Official Repo
# Note: OpenLiteSpeed provides a setup script to add their repo
wget -O - https://repo.litespeed.sh | bash

# 3. Install Core Tools & Snapd
echo "[3/6] Installing Snapd and SSH Server..."
apt install -y snapd openssh-server
# Ensure snapd service is running
systemctl enable --now snapd.socket

# 4. Install Web Servers
echo "[4/6] Installing Web Servers (Nginx, Apache2, OpenLiteSpeed)..."

# Install Apache2 and Nginx
apt install -y apache2 nginx

# Install OpenLiteSpeed
apt install -y openlitespeed

# --- CRITICAL: PREVENT PORT CONFLICTS ---
echo "(!) Stopping web services to prevent Port 80 conflicts..."
systemctl stop apache2
systemctl disable apache2
systemctl stop nginx
systemctl disable nginx
# OpenLiteSpeed usually runs on port 8088 (admin 7080) by default, 
# but we stop it just in case to let you configure it manually.
systemctl stop lsws
systemctl disable lsws

# 5. Install Wasm Runtime (Wasmtime & Wasmer)
# "Workers" usually refers to serverless wasm environments. 
# Wasmtime is the industry standard runtime.
echo "[5/6] Installing Wasm Runtimes..."

# Option A: Wasmtime (Fast, secure, standard)
curl https://wasmtime.dev/install.sh -sSf | bash

# Option B: Wasmer (Popular alternative for running universal binaries)
curl https://get.wasmer.io -sSf | sh

# Make wasm available in current session path for verification
export PATH="$HOME/.wasmtime/bin:$HOME/.wasmer/bin:$PATH"

# 6. Final Cleanup
echo "[6/6] Cleaning up..."
apt autoremove -y

echo "----------------------------------------------------"
echo "Installation Complete!"
echo "----------------------------------------------------"
echo "STATUS:"
echo "1. SSH Server:     Installed & Running"
echo "2. Snapd:          Installed & Running"
echo "3. Nginx:          Installed (Stopped/Disabled)"
echo "4. Apache2:        Installed (Stopped/Disabled)"
echo "5. OpenLiteSpeed:  Installed (Stopped/Disabled)"
echo "6. Wasm Runtimes:  Installed (Wasmtime & Wasmer)"
echo ""
echo "NEXT STEPS:"
echo "To start a specific web server, use:"
echo "  - Nginx:         sudo systemctl enable --now nginx"
echo "  - Apache:        sudo systemctl enable --now apache2"
echo "  - OpenLiteSpeed: sudo systemctl enable --now lsws"
echo ""
echo "Note: OpenLiteSpeed Admin panel is usually at https://<IP>:7080"
echo "      (Default credentials are often 'admin' / '123456' or set via /usr/local/lsws/admin/misc/admpass.sh)"
