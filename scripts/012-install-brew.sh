#!/usr/bin/bash

set -euox pipefail

# Install Brew dependencies
dnf install -y procps-ng curl file git gcc

# Convince the installer we are in CI
touch /.dockerenv

# Make these directories so the script will work
mkdir -p /var/home /var/roothome

# Check if Homebrew is already installed
if [[ ! -d "/home/linuxbrew/.linuxbrew" ]]; then
    curl -Lo /tmp/brew-install https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh
    chmod +x /tmp/brew-install
    /tmp/brew-install
    tar --zstd -cvf /usr/share/homebrew.tar.zst /home/linuxbrew/.linuxbrew
else
    echo "Homebrew already installed, skipping installation."
fi

# Enable Systemd services
systemctl enable brew-setup.service
systemctl enable brew-upgrade.timer
systemctl enable brew-update.timer

# Clean up installer but keep essential directories
rm -rf /.dockerenv /tmp/brew-install

# Register path symlink using tmpfiles.d
cat >/usr/lib/tmpfiles.d/homebrew.conf <<EOF
d /var/lib/homebrew 0755 1000 1000 - -
d /var/cache/homebrew 0755 1000 1000 - -
d /var/home/linuxbrew 0755 1000 1000 - -
EOF

