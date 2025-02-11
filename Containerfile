ARG FEDORA_MAJOR_VERSION=41

FROM quay.io/fedora/fedora:${FEDORA_MAJOR_VERSION} AS builder

WORKDIR /tmp
RUN <<-EOT sh
	set -eu

	touch /.dockerenv

	# Install packages
	dnf install -y git xz --setopt=install_weak_deps=False

	# Install Homebrew
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
	set -eu

	rpm-ostree install gcc make libxcrypt-compat

	rpm-ostree install \
		https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
		https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
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

	(rpm-ostree override remove \
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
		--install=gstreamer1-vaapi) || true

	(rpm-ostree override remove \
		mesa-va-drivers \
		--install=mesa-va-drivers-freeworld \
		--install=mesa-vdpau-drivers-freeworld) || true

	case "$(rpm -E %{_arch})" in
		x86_64)
			rpm-ostree install steam-devices
			rpm-ostree install intel-media-driver libva-intel-driver
			;;
	esac
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
		
	# Add Microsoft repository for VSCode
	rpm-ostree install \
		https://packages.microsoft.com/keys/microsoft.asc \
		https://packages.microsoft.com/config/rpm/7/prod.repo

	# Install Visual Studio Code
	rpm-ostree install code

	# Add Google Chrome repository
	rpm-ostree install \
		https://dl.google.com/linux/linux_signing_key.pub

	cat <<EOF > /etc/yum.repos.d/google-chrome.repo
	[google-chrome]
	name=google-chrome
	baseurl=https://dl.google.com/linux/chrome/rpm/stable/x86_64
	gpgcheck=1
	gpgkey=https://dl.google.com/linux/linux_signing_key.pub
	enabled=1
	EOF

	# Install Google Chrome
	rpm-ostree install google-chrome-stable

	# New commands added here
	systemctl enable dconf-update.service
	systemctl enable flatpak-add-flathub-repo.service
	systemctl enable flatpak-replace-fedora-apps.service
	systemctl enable flatpak-cleanup.timer
	systemctl enable rpm-ostreed-automatic.timer

	rpm-ostree cleanup -m && ostree container commit
EOT
