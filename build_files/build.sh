#!/bin/bash

set -ouex pipefail

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/39/x86_64/repoview/index.html&protocol=https&redirect=1

# this installs a package from fedora repos


#install tailscale repo/package and enable systemd service FROM zirconium/build_files/00-base.sh
dnf -y install dnf-plugins-core 'dnf5-command(config-manager)'

dnf config-manager addrepo --from-repofile=https://pkgs.tailscale.com/stable/fedora/tailscale.repo
dnf config-manager setopt tailscale-stable.enabled=0
dnf -y install --enablerepo='tailscale-stable' tailscale

systemctl enable tailscaled


#install niri quickshell ghostty FROM zirconium/build_files/01-theme.sh
dnf -y copr enable yalter/niri
dnf -y --enablerepo copr:copr.fedorainfracloud.org:yalter:niri install niri
dnf -y copr disable yalter/niri

dnf -y copr enable errornointernet/quickshell
dnf -y --enablerepo copr:copr.fedorainfracloud.org:errornointernet:quickshell install quickshell
dnf -y copr disable errornointernet/quickshell

dnf -y copr enable scottames/ghostty
dnf -y --enablerepo copr:copr.fedorainfracloud.org:scottames:ghostty install ghostty
dnf -y copr disable scottames/ghostty


#install network/net-firmware/firewalld FROM zirconium/build_files/00-base.sh
dnf -y install \
    NetworkManager-wifi \
    atheros-firmware \
    brcmfmac-firmware \
    iwlegacy-firmware \
    iwlwifi-dvm-firmware \
    iwlwifi-mvm-firmware \
    mt7xxx-firmware \
    nxpwireless-firmware \
    libcamera{,-{v4l2,gstreamer,tools}} \
    realtek-firmware \
    tiwilink-firmware \
    firewalld \
    fwupd \
    whois \
    unzip \
    rclone \
    fuse \
    fuse-common \
    uxplay \
    btop \
    plymouth \
    plymouth-system-theme \
    fastfetch \
    fish \
    podman


#install flatpak greetd just naut pipewire lots of tools and stuff FROM zirconium/build_files/01-theme.sh
dnf -y install \
    brightnessctl \
    chezmoi \
    ddcutil \
    fastfetch \
    flatpak \
    fpaste \
    fzf \
    git-core \
    gnome-keyring \
    greetd \
    greetd-selinux \
    just \
    nautilus \
    orca \
    pipewire \
    tuigreet \
    udiskie \
    wireplumber \
    wl-clipboard \
    wlsunset \
    xdg-desktop-portal-gnome \
    xdg-user-dirs \
    xwayland-satellite


#bootc update service/timer adjustments FROM zirconium/build_files/00-base.sh
sed -i 's|^ExecStart=.*|ExecStart=/usr/bin/bootc update --quiet|' /usr/lib/systemd/system/bootc-fetch-apply-updates.service
sed -i 's|^OnUnitInactiveSec=.*|OnUnitInactiveSec=7d\nPersistent=true|' /usr/lib/systemd/system/bootc-fetch-apply-updates.timer
sed -i 's|#AutomaticUpdatePolicy.*|AutomaticUpdatePolicy=stage|' /etc/rpm-ostreed.conf
sed -i 's|#LockLayering.*|LockLayering=true|' /etc/rpm-ostreed.conf

systemctl enable bootc-fetch-apply-updates

tee /usr/lib/systemd/zram-generator.conf <<'EOF'
[zram0]
zram-size = min(ram, 8192)
EOF

tee /usr/lib/systemd/system-preset/91-resolved-default.preset <<'EOF'
enable systemd-resolved.service
EOF
tee /usr/lib/tmpfiles.d/resolved-default.conf <<'EOF'
L /etc/resolv.conf - - - - ../run/systemd/resolve/stub-resolv.conf
EOF

systemctl preset systemd-resolved.service


#ublue copr and packages
dnf -y copr enable ublue-os/packages
dnf -y --enablerepo copr:copr.fedorainfracloud.org:ublue-os:packages install \
	bazaar \
	ublue-brew \
	uupd \
	ublue-os-udev-rules
dnf -y copr disable ublue-os/packages
systemctl enable brew-setup.service
systemctl enable uupd.timer


# Use a COPR Example:
#
# dnf5 -y copr enable ublue-os/staging
# dnf5 -y install package
# Disable COPRs so they don't end up enabled on the final image:
# dnf5 -y copr disable ublue-os/staging

#### Example for enabling a System Unit File

#systemctl enable podman.socket
