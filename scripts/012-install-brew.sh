#!/usr/bin/bash

set -euox pipefail

# Install Brew dependencies
dnf install -y procps-ng curl file git gcc

# Convince the installer we are in CI
touch /.dockerenv

# Ensure required directories exist
mkdir -p /var/home /var/roothome /home/linuxbrew/.linuxbrew

# Brew Install Script (Non-Interactive)
export NONINTERACTIVE=1
curl -Lo /tmp/brew-install https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh
chmod +x /tmp/brew-install
/tmp/brew-install || { echo "Homebrew installation failed"; exit 1; }

# Ensure Homebrew directory exists before compression
if [ -d "/home/linuxbrew/.linuxbrew" ]; then
    tar --zstd -cvf /usr/share/homebrew.tar.zst /home/linuxbrew/.linuxbrew
else
    echo "Error: Homebrew directory not found!"
    exit 1
fi

# Enable Systemd services if they exist
for service in brew-setup.service brew-upgrade.timer brew-update.timer; do
    if systemctl list-unit-files | grep -q "$service"; then
        systemctl enable "$service"
    else
        echo "Warning: $service not found, skipping..."
    fi
done

# Clean up safely (remove only temp files)
rm -f /.dockerenv

# Register path symlink via tmpfiles.d
cat >/usr/lib/tmpfiles.d/eternal-homebrew.conf <<EOF
d /var/lib/homebrew 0755 1000 1000 - -
d /var/cache/homebrew 0755 1000 1000 - -
d /var/home/linuxbrew 0755 1000 1000 - -
EOF

echo "Script execution completed successfully."

