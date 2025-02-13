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
COPY rootfs/etc/yum.repos.d/ /etc/yum.repos.d/
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
		net-tools \
		nss-tools \
		android-tools \
		ifuse \
		liberation-fonts-all \
		code \
		fastfetch \
		ibm-plex-mono-fonts \
		libimobiledevice \
		libxcrypt-compat \
		libsss_autofs \
		iotop \
		sysprof \
		epiphany \
		dconf-editor \
		zsh
		
	# Install Chrome Unstable for web development testing
	mv /opt{,.bak} \
    && mkdir /opt \
    && dnf install -y --enablerepo="google-chrome" google-chrome-unstable \
    && mv /opt/google/chrome /usr/lib/google-chrome \
    && ln -sf /usr/lib/google-chrome/google-chrome /usr/bin/google-chrome-unstable \
    && mkdir -p /usr/share/icons/hicolor/{16x16/apps,24x24/apps,32x32/apps,48x48/apps,64x64/apps,128x128/apps,256x256/apps} \
    && for i in "16" "24" "32" "48" "64" "128" "256"; do \
        ln -sf /usr/lib/google-chrome/product_logo_$i.png /usr/share/icons/hicolor/${i}x${i}/apps/google-chrome.png; \
    done \
    && rm -rf /etc/cron.daily \
    && rmdir /opt/{google,} \
    && mv /opt{.bak,} \
    && dnf clean all
		
	
	# Remove specified GNOME shell extensions
	(rpm-ostree override remove \
		gnome-classic-session \
		gnome-shell-extension-apps-menu \
		gnome-shell-extension-launch-new-instance \
		gnome-shell-extension-places-menu \
		gnome-shell-extension-window-list \
		gnome-shell-extension-background-logo) || true
		
	# Patch Gnome Shell
	rpm-ostree override replace --experimental --from repo=copr:copr.fedorainfracloud.org:trixieua:mutter-patched gnome-shell mutter mutter-common xorg-x11-server-Xwayland gdm
	
EOT
    
# Cleanup & Finalize
RUN rm -rf /tmp/* /var/*
RUN systemctl enable dconf-update.service && \
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


