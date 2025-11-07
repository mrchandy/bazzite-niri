#!/bin/bash

set -ouex pipefail

install -d /usr/share/zirconium/
dnf -y copr enable yalter/niri-git
dnf -y copr disable yalter/niri-git
echo "priority=1" | tee -a /etc/yum.repos.d/_copr:copr.fedorainfracloud.org:yalter:niri-git.repo
dnf -y --enablerepo copr:copr.fedorainfracloud.org:yalter:niri-git install niri
rm -rf /usr/share/doc/niri
dnf -y copr enable avengemedia/danklinux
dnf -y copr disable avengemedia/danklinux
dnf -y --enablerepo copr:copr.fedorainfracloud.org:avengemedia:danklinux install quickshell-git
dnf -y copr enable avengemedia/dms-git
dnf -y copr disable avengemedia/dms-git
dnf -y \
    --enablerepo copr:copr.fedorainfracloud.org:avengemedia:dms-git \
    --enablerepo copr:copr.fedorainfracloud.org:avengemedia:danklinux \
    install --setopt=install_weak_deps=False \
    dms \
    dms-cli \
    dms-greeter \
    dgop
dnf -y copr enable zirconium/packages
dnf -y copr disable zirconium/packages
dnf -y --enablerepo copr:copr.fedorainfracloud.org:zirconium:packages install \
    matugen \
    cliphist
dnf -y install \
   brightnessctl \
   cava \
   chezmoi \
   ddcutil \
   git-core \
   glycin-thumbnailer \
   gnome-keyring \
   greetd \
   greetd-selinux \
   input-remapper \
   nautilus \
   webp-pixbuf-loader \
   wl-clipboard \
   wlsunset \
   xdg-desktop-portal-gnome \
   xdg-user-dirs \
   xwayland-satellite \
   tuned \
   tuned-ppd
rm -rf /usr/share/doc/just                                    
dnf install -y --setopt=install_weak_deps=False \
   kf6-kirigami \
   qt6ct \
   polkit-kde \
   plasma-breeze \
   kf6-qqc2-desktop-style
git clone "https://github.com/noctalia-dev/noctalia-shell.git" /usr/share/zirconium/noctalia-shell
git clone "https://github.com/zirconium-dev/zdots.git" /usr/share/zirconium/zdots
install -d /etc/niri/
cp -f /usr/share/zirconium/zdots/dot_config/niri/config.kdl /etc/niri/config.kdl
file /etc/niri/config.kdl | grep -F -e "empty" -v
stat /etc/niri/config.kdl
