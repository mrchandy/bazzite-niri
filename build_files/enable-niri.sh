#!/bin/bash
set -ouex pipefail

sed -i '/gnome_keyring.so/ s/-auth/auth/ ; /gnome_keyring.so/ s/-session/session/' /etc/pam.d/greetd
cat /etc/pam.d/greetd
sed -i "s/After=.*/After=graphical-session.target/" /usr/lib/systemd/user/plasma-polkit-agent.service
add_wants_niri() {
    sed -i "s/\[Unit\]/\[Unit\]\nWants=$1/" "/usr/lib/systemd/user/niri.service"
}
add_wants_niri cliphist.service
add_wants_niri plasma-polkit-agent.service
add_wants_niri swayidle.service
#add_wants_niri udiskie.service
add_wants_niri xwayland-satellite.service
cat /usr/lib/systemd/user/niri.service
systemctl enable greetd
#systemctl enable flatpak-preinstall.service
#systemctl enable --global chezmoi-init.service
systemctl enable --global app-com.mitchellh.ghostty.service
#systemctl enable --global chezmoi-update.timer
systemctl enable --global dms.service
systemctl enable --global cliphist.service
systemctl enable --global gnome-keyring-daemon.socket
systemctl enable --global gnome-keyring-daemon.service
systemctl enable --global plasma-polkit-agent.service
systemctl enable --global swayidle.service
#systemctl enable --global udiskie.service
systemctl enable --global xwayland-satellite.service
systemctl preset --global app-com.mitchellh.ghostty.service
#systemctl preset --global chezmoi-init
#systemctl preset --global chezmoi-update
systemctl preset --global cliphist
systemctl preset --global plasma-polkit-agent
systemctl preset --global swayidle
#systemctl preset --global udiskie
systemctl preset --global xwayland-satellite
