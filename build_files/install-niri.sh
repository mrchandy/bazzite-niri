#!/bin/bash

set -ouex pipefail

install -d /usr/share/zirconium/

# Install niri-git
dnf -y copr enable yalter/niri-git
dnf -y copr disable yalter/niri-git
echo "priority=1" | tee -a /etc/yum.repos.d/_copr:copr.fedorainfracloud.org:yalter:niri-git.repo
dnf -y --enablerepo copr:copr.fedorainfracloud.org:yalter:niri-git install niri
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
   swayidle \
   xwayland-satellite \
   tuned \
   tuned-ppd \
   playerctl \
   NetworkManager-openvpn

dnf -y copr enable avengemedia/danklinux
dnf -y copr disable avengemedia/danklinux
dnf -y --enablerepo copr:copr.fedorainfracloud.org:avengemedia:danklinux install quickshell-git
dnf -y copr enable avengemedia/dms-git
dnf -y copr disable avengemedia/dms-git
dnf -y \
    --disablerepo "*" \
    --enablerepo copr:copr.fedorainfracloud.org:avengemedia:dms-git \
    --enablerepo copr:copr.fedorainfracloud.org:avengemedia:danklinux \
    install --setopt=install_weak_deps=False --skip-broken \
    dms \
    dms-cli \
    dms-greeter \
    dgop \
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
