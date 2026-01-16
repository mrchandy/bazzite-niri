#!/bin/bash 

# Install Nautilus, and thumbnailers
dnf -y install \
    nautilus \
    glycin-thumbnailer \
    mcomix3-thumbnailer \
    evince-thumbnailer \
    webp-pixbuf-loader \
    sushi

# Codecs for video thumbnails on nautilus <- From Zirconium
dnf config-manager addrepo --from-repofile=https://negativo17.org/repos/fedora-multimedia.repo
dnf config-manager setopt fedora-multimedia.enabled=0
dnf -y install --enablerepo=fedora-multimedia \
    libavcodec @multimedia gstreamer1-plugins-{bad-free,bad-free-libs,good,base} lame{,-libs} libjxl ffmpegthumbnailer