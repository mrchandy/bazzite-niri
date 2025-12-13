#!/bin/bash 
# Enable open any terminal copr
dnf -y copr enable monkeygold/nautilus-open-any-terminal
dnf -y copr disable monkeygold/nautilus-open-any-terminal

# Install Nautilus, terminal extension, and thumbnail dependancies
dnf -y install \
    nautilus \
    nautilus-open-any-terminal

# Set settings for default terminal and hotkey
gsettings set com.github.stunkymonkey.nautilus-open-any-terminal terminal ghostty
gsettings set com.github.stunkymonkey.nautilus-open-any-terminal new-tab false
gsettings set com.github.stunkymonkey.nautilus-open-any-terminal keybindings '<Shift>F4'

# Codecs for video thumbnails on nautilus <- From Zirconium
dnf config-manager addrepo --from-repofile=https://negativo17.org/repos/fedora-multimedia.repo
dnf config-manager setopt fedora-multimedia.enabled=0
dnf -y install --enablerepo=fedora-multimedia \
    libavcodec @multimedia gstreamer1-plugins-{bad-free,bad-free-libs,good,base} lame{,-libs} libjxl ffmpegthumbnailer