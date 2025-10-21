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


#install niri quickshell dank material shell & dms-greeter ghostty
dnf -y copr enable \
    yalter/niri \
    errornointernet/quickshell \
    scottames/ghostty \
    avengemedia/dms

dnf -y install \
    niri \
    dms \
    dms-greeter \
    ghostty

dnf -y copr disable \
    yalter/niri \
    errornointernet/quickshell \
    scottames/ghostty \
    avengemedia/dms


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
    podman \
    udiskie


#install flatpak greetd just naut pipewire lots of tools and stuff FROM zirconium/build_files/01-theme.sh
dnf -y install \
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


#enables greetd and firewalld service FROM zirconium/build_files/01-theme.sh
systemctl enable greetd
systemctl enable firewalld
systemctl enable podman.socket
systemctl enable podman.service


#sets function to edit systemd service files, then inserts wants niri.service FROM zirconium/build_files/01-theme.sh
add_wants_niri() {
    sed -i "s/\[Unit\]/\[Unit\]\nWants=$1/" "/usr/lib/systemd/user/niri.service"
}
#add_wants_niri noctalia.service
#add_wants_niri swayidle.service
add_wants_niri dms.service
add_wants_niri plasma-polkit-agent.service
add_wants_niri udiskie.service
add_wants_niri xwayland-satellite.service
cat /usr/lib/systemd/user/niri.service


#sets the gnome keyring to use greetd i presume? FROM zirconium/build_files/01-theme.sh
#sed -i '/gnome_keyring.so/ s/-auth/auth/ ; /gnome_keyring.so/ s/-session/session/' /etc/pam.d/greetd
#cat /etc/pam.d/greetd


#attempt to use the supplied greeter installer
dms greeter install


#QtQuick pugins and PolicyKit for KDE Desktop and systemd service, I presume this is necessary. FROM zirconium/build_files/01-theme.sh
dnf install -y --setopt=install_weak_deps=False \
    kf6-kirigami \
    polkit-kde

sed -i "s/After=.*/After=graphical-session.target/" /usr/lib/systemd/user/plasma-polkit-agent.service


# Codecs for video thumbnails on nautilus
#dnf config-manager addrepo --from-repofile=https://negativo17.org/repos/fedora-multimedia.repo
#dnf config-manager setopt fedora-multimedia.enabled=0
dnf -y install --enablerepo=fedora-multimedia \
    ffmpeg libavcodec @multimedia gstreamer1-plugins-{bad-free,bad-free-libs,good,base} lame{,-libs} libjxl ffmpegthumbnailer


# #Extracts colors from wallpapers # Note: noctalia says these are required dependacies, but zirc has gone without them so idk
# dnf -y copr enable purian23/matugen
# dnf -y copr disable purian23/matugen
# dnf -y --enablerepo copr:copr.fedorainfracloud.org:puritan23/matugen install matugen


#emoji and fonts FROM zirconium/build_files/01-theme.sh
#dnf install -y \
#    default-fonts-core-emoji \
#    google-noto-fonts-all \
#    google-noto-color-emoji-fonts \
#    google-noto-emoji-fonts \
#    glibc-all-langpacks \
#    inter-font \
#    roboto-fontface-common \
#    roboto-fontface-fonts


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


#ublue copr and packages and their services
dnf -y copr enable ublue-os/packages
dnf -y --enablerepo copr:copr.fedorainfracloud.org:ublue-os:packages install \
	bazaar \
	ublue-brew \
	uupd \
	ublue-os-udev-rules
dnf -y copr disable ublue-os/packages
systemctl enable brew-setup.service
systemctl enable uupd.timer
#systemctl enable io.github.kolunmi.Bazaar.service


#copies /usr and /etc for custom configs
cp -avf "/ctx/files"/. /
mkdir -p /etc/skel/Pictures/Wallpapers
ln -s /usr/share/bazzite-niri/Pictures/Wallpapers/ublue.png /etc/skel/Pictures/Wallpapers/ublue.png
#ln -s /usr/share/bazzite-niri/skel/.face /etc/skel/.face
#file /etc/skel/.face | grep -F -e "empty" -v
#file /etc/skel/Pictures/Wallpapers/* | grep -F -e "empty" -v


#enable systemd services dms/noctalia/etc
#systemctl enable --global chezmoi-init.service
#systemctl enable --global chezmoi-update.timer
#systemctl enable --global noctalia.service
#systemctl enable --global swayidle.service
systemctl enable --global dms.service
systemctl enable --global plasma-polkit-agent.service
systemctl enable --global udiskie.service
systemctl enable --global xwayland-satellite.service
#systemctl preset --global chezmoi-init
#systemctl preset --global chezmoi-update
#systemctl preset --global noctalia
#systemctl preset --global swayidle
systemctl preset --global dms
systemctl preset --global plasma-polkit-agent
systemctl preset --global udiskie
systemctl preset --global xwayland-satellite


#git clone noctalia-shell
git clone "https://github.com/noctalia-dev/noctalia-shell.git" /usr/share/bazzite-niri/noctalia-shell
install -d /etc/niri/
cp -f /usr/share/bazzite-niri/zdots/dot_config/niri/config.kdl /etc/niri/config.kdl
#not sure if these are necessary or not don't look too important
#file /etc/niri/config.kdl | grep -F -e "empty" -v
#stat /etc/skel/.face /etc/skel/Pictures/Wallpapers/* /etc/niri/config.kdl

