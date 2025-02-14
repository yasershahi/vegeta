#!/usr/bin/env bash

set -euox pipefail

sed -i 's/enabled=1/enabled=0/g' /etc/yum.repos.d/rpmfusion-{free,nonfree}{,-updates,-updates-testing}.repo

# Clear out unsupported directories
rm -rf /tmp/* /var/*
systemctl enable dconf-update.service && \
    rm -rf /usr/share/gnome-shell/extensions/background-logo@fedorahosted.org && \
    rm -f /etc/yum.repos.d/_copr:copr.fedorainfracloud.org:phracek:PyCharm.repo && \
    rm -f /etc/yum.repos.d/fedora-cisco-openh264.repo && \
    rm -f /etc/yum.repos.d/trixieua-mutter-patched.repo && \
    systemctl enable flatpak-add-flathub-repo.service && \
    systemctl enable flatpak-replace-fedora-apps.service && \
    systemctl enable flatpak-cleanup.timer && \
    sed -i 's/#AutomaticUpdatePolicy.*/AutomaticUpdatePolicy=stage/' /etc/rpm-ostreed.conf && \
    sed -i 's/#DefaultTimeoutStopSec.*/DefaultTimeoutStopSec=15s/' /etc/systemd/user.conf && \
    sed -i 's/#DefaultTimeoutStopSec.*/DefaultTimeoutStopSec=15s/' /etc/systemd/system.conf && \
    systemctl enable rpm-ostreed-automatic.timer && \
    rpm-ostree cleanup -m && \
    ostree container commit
