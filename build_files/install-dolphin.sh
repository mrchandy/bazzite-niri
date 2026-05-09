#!/bin/bash

# Install dolphin, ark, portal, thumbnailers, and dependancies
dnf -y install \
    dolphin \
    ark \
    xdg-desktop-portal-kde \
    ffmpegthumbs \
    kdegraphics-thumbnailers \
    kdesdk-thumbnailers \
    qt6-qtimageformats \
    kde-cli-tools \
    kf5-kservice \
    kio-extras \
    icoutils

# Setup Portals for niri, and dolphin
tee /usr/share/xdg-desktop-portal/niri-portals.conf <<'EOF'
[preferred]
default=gnome;gtk;
org.freedesktop.impl.portal.FileChooser=kde;
org.freedesktop.impl.portal.Access=gtk;
org.freedesktop.impl.portal.Notification=gtk;
org.freedesktop.impl.portal.Secret=gnome-keyring;
EOF

kbuildsycoca6 --noincremental