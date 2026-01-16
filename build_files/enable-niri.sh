#!/bin/bash
set -ouex pipefail

sed -i '/gnome_keyring.so/ s/-auth/auth/ ; /gnome_keyring.so/ s/-session/session/' /etc/pam.d/greetd
cat /etc/pam.d/greetd
add_wants_niri() {
    sed -i "s/\[Unit\]/\[Unit\]\nWants=$1/" "/usr/lib/systemd/user/niri.service"
}
#add_wants_niri swayidle.service
#add_wants_niri udiskie.service
cat /usr/lib/systemd/user/niri.service
systemctl enable greetd
#systemctl enable flatpak-preinstall.service
#systemctl enable --global chezmoi-init.service
#systemctl enable --global chezmoi-update.timer
systemctl enable --global app-com.mitchellh.ghostty.service
systemctl enable --global dms.service
systemctl enable --global gnome-keyring-daemon.socket
systemctl enable --global gnome-keyring-daemon.service
#systemctl enable --global swayidle.service
systemctl enable --global ssh-agent.service
systemctl preset --global app-com.mitchellh.ghostty.service
#systemctl preset --global swayidle
#systemctl preset --global chezmoi-init
#systemctl preset --global chezmoi-update
#systemctl enable --global udiskie.service
#systemctl preset --global udiskie