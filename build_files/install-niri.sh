#!/bin/bash

set -ouex pipefail

install -d /usr/share/zirconium/

# Install niri-git
dnf -y copr enable yalter/niri
dnf -y copr disable yalter/niri
echo "priority=1" | tee -a /etc/yum.repos.d/_copr:copr.fedorainfracloud.org:yalter:niri.repo
dnf -y --enablerepo copr:copr.fedorainfracloud.org:yalter:niri install niri
rm -rf /usr/share/doc/niri

# Install ghostty
dnf -y copr enable scottames/ghostty
dnf -y copr disable scottames/ghostty
dnf -y --enablerepo copr:copr.fedorainfracloud.org:scottames:ghostty install ghostty

# DMS dependancies not in COPR
dnf -y install \
   brightnessctl \
   cava \
   chezmoi \
   ddcutil \
   git-core \
   gnome-disk-utility \
   xdg-desktop-portal-gnome \
   xdg-desktop-portal-gtk \
   xdg-user-dirs \
   accountsservice \
   gnome-keyring \
   gnome-keyring-pam \
   adw-gtk3-theme \
   greetd \
   greetd-selinux \
   input-remapper \
   wl-clipboard \
   xwayland-satellite \
   tuned \
   tuned-ppd \
   playerctl \
   NetworkManager-openvpn \
   cups-pk-helper \
   qt6-qtmultimedia \
   qt6-qtimageformats

dnf -y copr enable avengemedia/danklinux
dnf -y copr disable avengemedia/danklinux
dnf -y --enablerepo copr:copr.fedorainfracloud.org:avengemedia:danklinux install quickshell-git
dnf -y copr enable avengemedia/dms
dnf -y copr disable avengemedia/dms
dnf -y \
    --disablerepo "*" \
    --enablerepo copr:copr.fedorainfracloud.org:avengemedia:dms \
    --enablerepo copr:copr.fedorainfracloud.org:avengemedia:danklinux \
    install --setopt=install_weak_deps=False --skip-broken \
    dms \
    dms-cli \
    dms-greeter \
    dgop \
    dsearch \
    matugen \
    cliphist

rm -rf /usr/share/doc/just

dnf install -y --setopt=install_weak_deps=False \
   kf6-kirigami \
   qt6ct \
   polkit-kde \
   plasma-breeze \
   kf6-qqc2-desktop-style

git clone "https://github.com/zirconium-dev/zdots.git" /usr/share/zirconium/zdots

install -d /etc/niri/
cp -f /usr/share/zirconium/zdots/dot_config/niri/config.kdl /etc/niri/config.kdl
file /etc/niri/config.kdl | grep -F -e "empty" -v
stat /etc/niri/config.kdl
