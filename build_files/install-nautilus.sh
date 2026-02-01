#!/bin/bash 

# Install Nautilus, and thumbnailers
dnf -y install \
    nautilus \
    nautilus-python \
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

# Tulips workflow for the Nautilus xdg-terminal-exec extension
XDG_EXT_TMPDIR="$(mktemp -d)"
curl -fsSLo - "$(curl -fsSL https://api.github.com/repos/tulilirockz/xdg-terminal-exec-nautilus/releases/latest | jq -rc .tarball_url)" | tar -xzvf - -C "${XDG_EXT_TMPDIR}"
install -Dpm0644 -t "/usr/share/nautilus-python/extensions/" "${XDG_EXT_TMPDIR}"/*/xdg-terminal-exec-nautilus.py
rm -rf "${XDG_EXT_TMPDIR}"