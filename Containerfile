# Use the Fedora base image for the builder stage
FROM quay.io/fedora/fedora:${FEDORA_MAJOR_VERSION} AS builder

# Set the working directory
WORKDIR /tmp

# Install essential packages
RUN dnf install -y git xz --setopt=install_weak_deps=False || { echo "Failed to install git and xz"; exit 1; }

# Install Homebrew for x86_64 architecture
RUN <<-EOT
	set -eu
	set -x  # Enable debugging output

	case "\$(rpm -E %{_arch})" in
		x86_64)
			curl -fLs https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | bash -s
			/home/linuxbrew/.linuxbrew/bin/brew update
			;;
		*)
			mkdir -p /home/linuxbrew
			;;
	esac
EOT

# Use the Fedora Silverblue base image for the final stage
FROM quay.io/fedora/fedora-silverblue:${FEDORA_MAJOR_VERSION}

# Copy necessary files from the builder stage
COPY rootfs/ /
COPY cosign.pub /etc/pki/containers/
COPY --from=builder --chown=1000:1000 /home/linuxbrew /usr/share/homebrew

# Install packages and configure the system
RUN <<-'EOT'
	set -eu
	set -x  # Enable debugging output

	# Install essential development tools
	rpm-ostree install gcc make libxcrypt-compat

	# Install RPMFusion repositories
	rpm-ostree install \
		https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
		https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

	# Install RPMFusion packages
	rpm-ostree install rpmfusion-free-release rpmfusion-nonfree-release \
		--uninstall rpmfusion-free-release \
		--uninstall rpmfusion-nonfree-release

	# Remove specified GNOME shell extensions
	rpm-ostree override remove \
		gnome-shell-extension-apps-menu \
		gnome-shell-extension-launch-new-instance \
		gnome-shell-extension-places-menu \
		gnome-shell-extension-window-list \
		gnome-shell-extension-background-logo || true

	# Remove free versions of multimedia libraries and install alternatives
	rpm-ostree override remove \
		ffmpeg-free \
		libavcodec-free \
		libavdevice-free \
		libavfilter-free \
		libavformat-free \
		libavutil-free \
		libpostproc-free \
		libswresample-free \
		libswscale-free \
		--install=ffmpeg \
		--install=gstreamer1-plugin-libav \
		--install=gstreamer1-plugins-bad-free-extras \
		--install=gstreamer1-plugins-bad-freeworld \
		--install=gstreamer1-plugins-ugly \
		--install=gstreamer1-vaapi || true

	# Install additional drivers
	rpm-ostree override remove \
		mesa-va-drivers \
		--install=mesa-va-drivers-freeworld \
		--install=mesa-vdpau-drivers-freeworld || true

	case "$(rpm -E %{_arch})" in
		x86_64)
			rpm-ostree install steam-devices
			rpm-ostree install intel-media-driver libva-intel-driver
			;;
	esac

	# Install NVIDIA driver
	rpm-ostree install libva-nvidia-driver

	# Install additional packages
	rpm-ostree install \
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
		net-tools

	# Install Visual Studio Code
	rpm-ostree install code

	# Install Google Chrome
	rpm-ostree install google-chrome-stable

	# Enable systemd services
	systemctl enable dconf-update.service
	systemctl enable flatpak-add-flathub-repo.service
	systemctl enable flatpak-replace-fedora-apps.service
	systemctl enable flatpak-cleanup.timer
	systemctl enable rpm-ostreed
	systemctl enable rpm-ostreed-automatic.timer

	# Perform cleanup and commit the changes
	rpm-ostree cleanup -m && ostree container commit
EOT
