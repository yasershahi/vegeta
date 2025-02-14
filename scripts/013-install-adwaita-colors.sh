#!/usr/bin/bash

set -euo pipefail

INSTALL_PATH="/usr/share/icons"

dnf install -y git

TMP_DIR=$(mktemp -d)
git clone https://github.com/dpejoh/Adwaita-colors "$TMP_DIR"

mkdir -p "$INSTALL_PATH"
cp -r "$TMP_DIR"/* "$INSTALL_PATH"

rm -rf "$TMP_DIR"

