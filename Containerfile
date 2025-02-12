ARG FEDORA_MAJOR_VERSION=41

FROM quay.io/fedora/fedora:${FEDORA_MAJOR_VERSION} AS builder

WORKDIR /tmp
RUN <<-EOT sh
	set -eu
	touch /.dockerenv
	dnf install -y git xz --setopt=install_weak_deps=False
	case "$(rpm -E %{_arch})" in
		x86_64)
			curl -fLs \
				https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | bash -s
			/home/linuxbrew/.linuxbrew/bin/brew update
			;;
		*)
			mkdir /home/linuxbrew
			;;
	esac
EOT

FROM quay.io/fedora/fedora-silverblue:${FEDORA_MAJOR_VERSION}

COPY rootfs/ /
COPY cosign.pub /etc/pki/containers/
COPY --from=builder --chown=1000:1000 /home/linuxbrew /usr/share/homebrew

RUN <<-'EOT' sh
	set -euxo pipefail

	# Base development tools
	rpm-ostree install gcc make libxcrypt-compat

	# RPM Fusion setup
	rpm-ostree install \
		https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
		https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

	# Remove GNOME extensions without breaking dependencies
	rpm-ostree override remove \
		gnome-shell-extension-apps-menu \
		gnome-shell-extension-launch-new-instance \
		gnome-shell-extension-places-menu \
		gnome-shell-extension-window-list \
		gnome-shell-extension-background-logo

	# Multimedia stack
	rpm-ostree override replace \
		--remove=ffmpeg-free \
		--install=ffmpeg \
		--install=gstreamer1-plugin-libav \
		--install=gstreamer1-plugins-bad-free-extras \
		--install=gstreamer1-plugins-bad-freeworld \
		--install=gstreamer1-plugins-ugly \
		--install=gstreamer1-vaapi

	# Graphics drivers
	rpm-ostree override replace \
		--remove=mesa-va-drivers \
		--install=mesa-va-drivers-freeworld \
		--install=mesa-vdpau-drivers-freeworld

	# x86_64 specific packages
	case "$(rpm -E %{_arch})" in
		x86_64)
			rpm-ostree install \
				steam-devices \
				intel-media-driver \
				libva-intel-driver
			;;
	esac

	# Third-party repos
	rpm --import https://packages.microsoft.com/keys/microsoft.asc
	rpm --import https://dl.google.com/linux/linux_signing_key.pub

	cat > /etc/yum.repos.d/vscode.repo <<'EOF'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF

	cat > /etc/yum.repos.d/google-chrome.repo <<'EOF'
[google-chrome]
name=google-chrome
baseurl=https://dl.google.com/linux/chrome/rpm/stable/x86_64
enabled=1
gpgcheck=1
gpgkey=https://dl.google.com/linux/linux_signing_key.pub
EOF

	# Combined package installation
	rpm-ostree install \
		code \
		google-chrome-stable \
		tailscale \
		gnome-backgrounds-extras \
		unrar \
		p7zip \
		p7zip-plugins \
		wireguard-tools \
		subversion \
		aria2 \
		sstp-client \
		NetworkManager-sstp \
		NetworkManager-sstp-gnome \
		net-tools \
		libva-nvidia-driver

	# Systemd services
	for service in \
		dconf-update.service \
		flatpak-add-flathub-repo.service \
		flatpak-replace-fedora-apps.service \
		flatpak-cleanup.timer \
		rpm-ostreed-automatic.timer
	do
		if systemctl list-unit-files | grep -q "^${service}"; then
			systemctl enable "${service}"
		fi
	done

	# Final cleanup
	rpm-ostree cleanup -m
EOT
