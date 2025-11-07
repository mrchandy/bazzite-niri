#
#     %%%%%%====%%%%%%%%%%
#   %%%%%%%%    %%%%%%%%%%%%%%
#  %%%%%%%%%    %%%%%%%%%%%%%%%%
#  %%%%%%%%%    %%%%%%%%%%%%%%%###
#  %%%%%%%%%    %%%%%%%%%%%%%######
#  ==                  =======######
#  ==                  =========#####
#  %%%%%%%%%    %%%%%%%####======#####
#  %%%%%%%%%    %%%%%#######=====#####
#  %%%%%%%%%    %%%#########=====#####
#  %%%%%%%%%    %%##########=====#####
#  %%%%%%%%%====###########=====######
#   %%%%%%%%====#########======######
#    %%%%%%%=====#####========######
#     %%%%###===============#######
#      %#######==========#########
#        #######################
#          ###################
#              ###########
#
# Welcome to Bazzite! If you're looking to
# build your own, we highly recommend you
# use our custom image template. Forking
# the main repo provides more control, but
# is often unnecessary.
#
# https://github.com/ublue-os/image-template

ARG BASE_IMAGE_NAME="${BASE_IMAGE_NAME}"
ARG FEDORA_VERSION="${FEDORA_VERSION:-43}"
ARG ARCH="${ARCH:-x86_64}"

ARG BASE_IMAGE="${BASE_IMAGE:-ghcr.io/ublue-os/${BASE_IMAGE_NAME}-main:${FEDORA_VERSION}}"
ARG NVIDIA_BASE="${NVIDIA_BASE:-bazzite}"
ARG KERNEL_REF="${KERNEL_REF:-ghcr.io/bazzite-org/kernel-bazzite:latest-f${FEDORA_VERSION}-${ARCH}}"
ARG NVIDIA_REF="${NVIDIA_REF:-ghcr.io/bazzite-org/nvidia-drivers:latest-f${FEDORA_VERSION}-${ARCH}}"

FROM ${KERNEL_REF} AS kernel
FROM ${NVIDIA_REF} AS nvidia

################
# DESKTOP BUILDS
################

FROM ${BASE_IMAGE} AS bazzite

ARG IMAGE_NAME="${IMAGE_NAME:-bazzite}"
ARG IMAGE_VENDOR="${IMAGE_VENDOR:-ublue-os}"
ARG IMAGE_BRANCH="${IMAGE_BRANCH:-stable}"
ARG BASE_IMAGE_NAME="${BASE_IMAGE_NAME:-niri}"
ARG SHA_HEAD_SHORT="${SHA_HEAD_SHORT}"
ARG VERSION_TAG="${VERSION_TAG}"
ARG VERSION_PRETTY="${VERSION_PRETTY}"

COPY system_files/desktop/shared system_files/desktop/${BASE_IMAGE_NAME} /
COPY ./build_files/cleanup ./build_files/install-kernel ./build_files/ghcurl ./build_files/dnf5-setopt ./build_files/dnf5-search ./build_files/build-gnome-extensions /ctx/

# Setup Copr repos
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    mkdir -p /var/roothome && \
    dnf5 -y install dnf5-plugins && \
    for copr in \
        bazzite-org/bazzite \
        bazzite-org/bazzite-multilib \
        ublue-os/staging \
        ublue-os/packages \
        bazzite-org/obs-vkcapture \
        ycollet/audinux \
        bazzite-org/rom-properties \
        bazzite-org/webapp-manager \
        hhd-dev/hhd \
        lizardbyte/beta \
        che/nerd-fonts; \
    do \
        echo "Enabling copr: $copr"; \
        dnf5 -y copr enable $copr; \
        dnf5 -y config-manager setopt copr:copr.fedorainfracloud.org:${copr////:}.priority=98 ;\
    done && unset -v copr && \
    dnf5 -y install --nogpgcheck --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' terra-release{,-extras} && \
    dnf5 -y config-manager addrepo --overwrite --from-repofile=https://pkgs.tailscale.com/stable/fedora/tailscale.repo && \
    dnf5 -y install \
        https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
        https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm && \
    sed -i 's@enabled=0@enabled=1@g' /etc/yum.repos.d/negativo17-fedora-multimedia.repo && \
    dnf5 -y config-manager addrepo --from-repofile=https://negativo17.org/repos/fedora-steam.repo && \
    dnf5 -y config-manager addrepo --from-repofile=https://negativo17.org/repos/fedora-rar.repo && \
    dnf5 -y config-manager setopt "*bazzite*".priority=1 && \
    dnf5 -y config-manager setopt "*terra*".priority=3 "*terra*".exclude="nerd-fonts topgrade scx-scheds steam python3-protobuf" && \
    dnf5 -y config-manager setopt "terra-mesa".enabled=true && \
    dnf5 -y config-manager setopt "terra-nvidia".enabled=false && \
    eval "$(/ctx/dnf5-setopt setopt '*negativo17*' priority=4 exclude='mesa-* *xone*')" && \
    dnf5 -y config-manager setopt "*rpmfusion*".priority=5 "*rpmfusion*".exclude="mesa-*" && \
    dnf5 -y config-manager setopt "*fedora*".exclude="mesa-* kernel-core-* kernel-modules-* kernel-uki-virt-*" && \
    dnf5 -y config-manager setopt "*staging*".exclude="scx-scheds kf6-* mesa* mutter*" && \
    /ctx/cleanup

# Install kernel
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=bind,from=kernel,src=/,dst=/rpms/kernel \
    /ctx/install-kernel && \
    dnf5 -y config-manager setopt "*rpmfusion*".enabled=0 && \
    dnf5 -y copr enable bieszczaders/kernel-cachyos-addons && \
    dnf5 -y install \
        scx-scheds && \
    dnf5 -y copr disable bieszczaders/kernel-cachyos-addons && \
    declare -A toswap=( \
        ["copr:copr.fedorainfracloud.org:bazzite-org:bazzite"]="bootc rpm-ostree plymouth" \
    ) && \
    for repo in "${!toswap[@]}"; do \
        for package in ${toswap[$repo]}; do dnf5 -y swap --repo=$repo $package $package; done; \
    done && unset -v toswap repo package && \
    dnf5 versionlock add \
        bootc \
        rpm-ostree \
        plymouth \
        plymouth-scripts \
        plymouth-core-libs \
        plymouth-graphics-libs \
        plymouth-plugin-label \
        plymouth-plugin-two-step \
        plymouth-plugin-theme-spinner \
        plymouth-system-theme && \
    /ctx/cleanup

COPY ./build_files/install-firmware /ctx/

# Setup firmware
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    /ctx/install-firmware && \
    /ctx/cleanup

# Install patched fwupd
# Install Valve's patched Mesa, Pipewire, Bluez, and Xwayland
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    declare -A toswap=( \
        ["copr:copr.fedorainfracloud.org:bazzite-org:bazzite"]="wireplumber" \
        ["copr:copr.fedorainfracloud.org:bazzite-org:bazzite-multilib"]="pipewire bluez xorg-x11-server-Xwayland" \
        ["terra-mesa"]="mesa-filesystem" \
        ["copr:copr.fedorainfracloud.org:ublue-os:staging"]="fwupd" \
    ) && \
    for repo in "${!toswap[@]}"; do \
        for package in ${toswap[$repo]}; do dnf5 -y swap --repo=$repo $package $package; done; \
    done && unset -v toswap repo package && \
    dnf5 versionlock add \
        pipewire \
        pipewire-alsa \
        pipewire-gstreamer \
        pipewire-jack-audio-connection-kit \
        pipewire-jack-audio-connection-kit-libs \
        pipewire-libs \
        pipewire-plugin-libcamera \
        pipewire-pulseaudio \
        pipewire-utils \
        wireplumber \
        wireplumber-libs \
        bluez \
        bluez-cups \
        bluez-libs \
        bluez-obexd \
        xorg-x11-server-Xwayland \
        mesa-dri-drivers \
        mesa-filesystem \
        mesa-libEGL \
        mesa-libGL \
        mesa-libgbm \
        mesa-va-drivers \
        mesa-vulkan-drivers \
        fwupd \
        fwupd-plugin-flashrom \
        fwupd-plugin-modem-manager \
        fwupd-plugin-uefi-capsule-data && \
    dnf5 -y install \
        mesa-va-drivers.i686 \
        libfreeaptx && \
    dnf5 -y install --enable-repo="*rpmfusion*" --disable-repo="*fedora-multimedia*" \
        libaacs \
        libbdplus \
        libbluray \
        libbluray-utils && \
    /ctx/cleanup

# Remove unneeded packages
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    dnf5 -y remove \
        ublue-os-update-services \
        firefox \
        firefox-langpacks \
        toolbox \
        htop && \
    /ctx/cleanup

# Install new packages
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=secret,id=GITHUB_TOKEN \
    dnf5 -y install \
        $(/ctx/ghcurl https://api.github.com/repos/bazzite-org/cicpoffs/releases/latest | jq -r '.assets[] | select(.name| test(".*rpm$")).browser_download_url') && \
    dnf5 -y install \
        bazaar \
        iwd \
        twitter-twemoji-fonts \
        google-noto-sans-cjk-fonts \
        lato-fonts \
        fira-code-fonts \
        nerd-fonts \
        Sunshine \
        python3-pip \
        libadwaita \
        duperemove \
        cpulimit \
        sqlite \
        xwininfo \
        xrandr \
        compsize \
        ryzenadj \
        ddcutil \
        input-remapper \
        libinput-utils \
        i2c-tools \
        lm_sensors \
        fw-ectool \
        fw-fanctrl \
        udica \
        ladspa-caps-plugins \
        ladspa-noise-suppression-for-voice \
        pipewire-module-filter-chain-sofa \
        python3-icoextract \
        tailscale \
        webapp-manager \
        btop \
        duf \
        fish \
        lshw \
        xdotool \
        wmctrl \
        libcec \
        yad \
        f3 \
        pulseaudio-utils \
        lzip \
        p7zip \
        p7zip-plugins \
        rar \
        libxcrypt-compat \
        vulkan-tools \
        xwiimote-ng \
        fastfetch \
        glow \
        gum \
        vim \
        cockpit-networkmanager \
        cockpit-podman \
        cockpit-selinux \
        cockpit-system \
        cockpit-files \
        cockpit-storaged \
        topgrade \
        ydotool \
        stress-ng \
        snapper \
        btrfs-assistant \
        edk2-ovmf \
        qemu \
        libvirt \
        lsb_release \
        uupd \
        ds-inhibit \
        rocm-hip \
        rocm-opencl \
        rocm-clinfo \
        waydroid \
        cage \
        wlr-randr && \
    systemctl mask iscsi && \
    mkdir -p /usr/lib/extest/ && \
    /ctx/ghcurl "$(/ctx/ghcurl https://api.github.com/repos/bazzite-org/extest/releases/latest | jq -r '.assets[] | select(.name| test(".*so$")).browser_download_url')" -Lo /usr/lib/extest/libextest.so && \
    /ctx/ghcurl "$(/ctx/ghcurl https://api.github.com/repos/FrameworkComputer/framework-system/releases/latest | jq -r '.assets[] | select(.name == "framework_tool").browser_download_url')" -Lo /usr/bin/framework_tool && \
    chmod +x /usr/bin/framework_tool && \
    /ctx/ghcurl "$(/ctx/ghcurl https://api.github.com/repos/HikariKnight/ls-iommu/releases/latest | jq -r '.assets[] | select(.name| test(".*x86_64.tar.gz$")).browser_download_url')" -Lo /tmp/ls-iommu.tar.gz && \
    mkdir -p /tmp/ls-iommu && \
    sed -i 's|uupd|& --disable-module-distrobox|' /usr/lib/systemd/system/uupd.service && \
    setcap 'cap_sys_admin+p' $(readlink -f /usr/bin/sunshine) && \
    dnf5 -y --setopt=install_weak_deps=False install \
        rocm-hip \
        rocm-opencl \
        rocm-clinfo \
        rocm-smi && \
    mkdir -p /etc/xdg/autostart && \
    sed -i~ -E 's/=.\$\(command -v (nft|ip6?tables-legacy).*/=/g' /usr/lib/waydroid/data/scripts/waydroid-net.sh && \
    sed -i 's/ --xdg-runtime=\\"${XDG_RUNTIME_DIR}\\"//g' /usr/bin/btrfs-assistant-launcher && \
    /ctx/ghcurl "https://raw.githubusercontent.com/bazzite-org/steam-proton-mf-wmv/master/installcab.py" -Lo /usr/bin/installcab && \
    chmod +x /usr/bin/installcab && \
    /ctx/ghcurl "https://raw.githubusercontent.com/bazzite-org/steam-proton-mf-wmv/refs/heads/master/install-mf-wmv.sh" -Lo /usr/bin/install-mf-wmv && \
    chmod +x /usr/bin/install-mf-wmv && \
    tar --no-same-owner --no-same-permissions --no-overwrite-dir -xvzf /tmp/ls-iommu.tar.gz -C /tmp/ls-iommu && \
    rm -f /tmp/ls-iommu.tar.gz && \
    cp -r /tmp/ls-iommu/ls-iommu /usr/bin/ && \
    /ctx/ghcurl "https://github.com/HikariKnight/ScopeBuddy/archive/refs/tags/$(/ctx/ghcurl https://api.github.com/repos/HikariKnight/scopebuddy/releases/latest | jq -r '.tag_name').tar.gz" -Lo /tmp/scopebuddy.tar.gz && \
    mkdir -p /tmp/scopebuddy && \
    tar --no-same-owner --no-same-permissions --no-overwrite-dir -xvzf /tmp/scopebuddy.tar.gz -C /tmp/scopebuddy && \
    rm -f /tmp/scopebuddy.tar.gz && \
    cp -r /tmp/scopebuddy/ScopeBuddy-*/bin/* /usr/bin/ && \
    /ctx/cleanup

# Install Steam & Lutris, plus supporting packages
# Downgrade ibus to fix an issue with the Steam keyboard
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=secret,id=GITHUB_TOKEN \
    dnf5 versionlock add \
        ibus && \
    dnf5 -y install \
        gamescope.x86_64 \
        gamescope-libs.x86_64 \
        gamescope-libs.i686 \
        gamescope-shaders \
        jupiter-sd-mounting-btrfs \
        umu-launcher \
        dbus-x11 \
        xdg-user-dirs \
        gobject-introspection \
        libFAudio.x86_64 \
        libFAudio.i686 \
        vkBasalt.x86_64 \
        vkBasalt.i686 \
        mangohud.x86_64 \
        mangohud.i686 \
        libobs_vkcapture.x86_64 \
        libobs_glcapture.x86_64 \
        libobs_vkcapture.i686 \
        libobs_glcapture.i686 \
        VK_hdr_layer && \
    dnf5 -y --setopt=install_weak_deps=False install \
        steam \
        lutris && \
    dnf5 -y remove \
        gamemode && \
    /ctx/ghcurl "https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks" -Lo /usr/bin/winetricks && \
    chmod +x /usr/bin/winetricks && \
    /ctx/cleanup

# Install yafti-go & ujust-picker from GitHub releases
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=secret,id=GITHUB_TOKEN \
    /ctx/ghcurl "$(/ctx/ghcurl "https://api.github.com/repos/bazzite-org/yafti-go/releases/latest" -s | jq -r '.assets[] | select(.name == "yafti-go").browser_download_url')" -sL -o /bin/yafti-go && \
    chmod +x /bin/yafti-go && \
    chmod +x /usr/libexec/bazzite-yafti-launcher && \
    /ctx/ghcurl "$(/ctx/ghcurl "https://api.github.com/repos/xXJSONDeruloXx/bazzite-ujust-picker/releases/latest" -s | jq -r '.assets[] | select(.name | test("x86_64$")) | .browser_download_url')" -sL -o /usr/bin/ujust-picker && \
    chmod +x /usr/bin/ujust-picker && \
    /ctx/cleanup


#-------------------- Configure DE ------------------------------ 
COPY ./build_files/install-niri.sh /ctx/

RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=secret,id=GITHUB_TOKEN \
    /ctx/install-niri.sh && \
    /ctx/cleanup

# ublue-os packages
# Homebrew & Bash Prexec
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=secret,id=GITHUB_TOKEN \
    dnf5 install -y ublue-brew && \
    /ctx/ghcurl "https://raw.githubusercontent.com/ublue-os/bash-preexec/master/bash-preexec.sh" -Lo /usr/share/bash-prexec && \
    /ctx/cleanup

# ublue-os-media-automount-udev, mount non-removable device partitions automatically under /media/media-automount/
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    dnf5 install -y --enable-repo=copr:copr.fedorainfracloud.org:ublue-os:packages \
        ublue-os-media-automount-udev && \
    { systemctl enable ublue-os-media-automount.service || true; } && \
    /ctx/cleanup

# Cleanup & Finalize
COPY system_files/overrides /
COPY ./build_files/finalize ./build_files/build-initramfs ./build_files/image-info ./build_files/dnf5-setopt ./build_files/dnf5-search /ctx/
COPY ./build_files/enable-niri.sh /ctx/

RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=secret,id=GITHUB_TOKEN \
    rm -f /etc/profile.d/toolbox.sh && \
    mkdir -p /var/tmp && chmod 1777 /var/tmp && \
    cp --no-dereference --preserve=links /usr/lib/libdrm.so.2 /usr/lib/libdrm.so && \
    cp --no-dereference --preserve=links /usr/lib64/libdrm.so.2 /usr/lib64/libdrm.so && \
    sed -i 's@/usr/bin/steam@/usr/bin/bazzite-steam@g' /usr/share/applications/steam.desktop && \
    sed -i 's@Exec=steam steam://open/bigpicture@Exec=/usr/bin/bazzite-steam-bpm@g' /usr/share/applications/steam.desktop && \
    sed -i 's|^Exec=lutris %U$|Exec=env PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION=python lutris %U|' /usr/share/applications/net.lutris.Lutris.desktop && \
    mkdir -p /etc/skel/.config/autostart/ && \
    cp "/usr/share/applications/steam.desktop" "/etc/skel/.config/autostart/steam.desktop" && \
    sed -i 's@/usr/bin/bazzite-steam %U@/usr/bin/bazzite-steam -silent %U@g' /etc/skel/.config/autostart/steam.desktop && \
    sed -i 's@\[Desktop Entry\]@\[Desktop Entry\]\nNoDisplay=true@g' /usr/share/applications/nvtop.desktop && \
    sed -i 's@\[Desktop Entry\]@\[Desktop Entry\]\nNoDisplay=true@g' /usr/share/applications/btop.desktop && \
    sed -i 's@\[Desktop Entry\]@\[Desktop Entry\]\nNoDisplay=true@g' /usr/share/applications/yad-icon-browser.desktop && \
    sed -i 's/#UserspaceHID.*/UserspaceHID=true/' /etc/bluetooth/input.conf && \
    sed -i "s|grub_probe\} --target=device /\`|grub_probe} --target=device /sysroot\`|g" /usr/bin/grub2-mkconfig && \
    rm -f /usr/lib/systemd/system/service.d/50-keep-warm.conf && \
    echo "import \"/usr/share/ublue-os/just/80-bazzite.just\"" >> /usr/share/ublue-os/justfile && \
    echo "import \"/usr/share/ublue-os/just/81-bazzite-fixes.just\"" >> /usr/share/ublue-os/justfile && \
    echo "import \"/usr/share/ublue-os/just/82-bazzite-apps.just\"" >> /usr/share/ublue-os/justfile && \
    echo "import \"/usr/share/ublue-os/just/82-bazzite-cdemu.just\"" >> /usr/share/ublue-os/justfile && \
    echo "import \"/usr/share/ublue-os/just/82-bazzite-sunshine.just\"" >> /usr/share/ublue-os/justfile && \
    echo "import \"/usr/share/ublue-os/just/82-bazzite-rmlint.just\"" >> /usr/share/ublue-os/justfile && \
    echo "import \"/usr/share/ublue-os/just/82-bazzite-waydroid.just\"" >> /usr/share/ublue-os/justfile && \
    echo "import \"/usr/share/ublue-os/just/83-bazzite-audio.just\"" >> /usr/share/ublue-os/justfile && \
    echo "import \"/usr/share/ublue-os/just/84-bazzite-virt.just\"" >> /usr/share/ublue-os/justfile && \
    echo "import \"/usr/share/ublue-os/just/85-bazzite-image.just\"" >> /usr/share/ublue-os/justfile && \
    echo "import \"/usr/share/ublue-os/just/86-bazzite-windows.just\"" >> /usr/share/ublue-os/justfile && \
    echo "import \"/usr/share/ublue-os/just/87-bazzite-framegen.just\"" >> /usr/share/ublue-os/justfile && \
    echo "import \"/usr/share/ublue-os/just/88-bazzite-webapps.just\"" >> /usr/share/ublue-os/justfile && \
    echo "import \"/usr/share/ublue-os/just/89-bazzite-mesa-git.just\"" >> /usr/share/ublue-os/justfile && \
    echo "import \"/usr/share/ublue-os/just/90-bazzite-picker.just\"" >> /usr/share/ublue-os/justfile && \
    echo "import \"/usr/share/ublue-os/just/90-bazzite-de.just\"" >> /usr/share/ublue-os/justfile && \
    echo "import \"/usr/share/ublue-os/just/91-bazzite-decky.just\"" >> /usr/share/ublue-os/justfile && \
    
    #------------------------ service enables for DE ------------------------
    /ctx/enable-niri.sh && \


    #mkdir -p /tmp/bazzite-schema-test && \
    #find "/usr/share/glib-2.0/schemas/" -type f ! -name "*.gschema.override" -exec cp {} "/tmp/bazzite-schema-test/" \; && \
    #cp "/usr/share/glib-2.0/schemas/zz0-"*".gschema.override" "/tmp/bazzite-schema-test/" && \
    #glib-compile-schemas --strict /tmp/bazzite-schema-test && \
    #glib-compile-schemas /usr/share/glib-2.0/schemas &>/dev/null && \
    #rm -r /tmp/bazzite-schema-test && \
    sed -i 's/stage/none/g' /etc/rpm-ostreed.conf && \
    for repo in \
        fedora-cisco-openh264 \
        fedora-steam \
        fedora-rar \
        google-chrome \
        tailscale \
        _copr_ublue-os-akmods \
        terra \
        terra-extras \
        negativo17-fedora-multimedia; \
    do \
        sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/$repo.repo; \
    done && for copr in \
        bazzite-org/bazzite \
        bazzite-org/bazzite-multilib \
        ublue-os/staging \
        ublue-os/packages \
        bazzite-org/obs-vkcapture \
        ycollet/audinux \
        bazzite-org/rom-properties \
        bazzite-org/webapp-manager \
        hhd-dev/hhd \
        lizardbyte/beta \
        che/nerd-fonts; \
    do \
        dnf5 -y copr disable $copr; \
    done && unset -v copr && \
    eval "$(/ctx/dnf5-setopt setopt '*negativo17*' enabled=0)" && \
    sed -i 's#/var/lib/selinux#/etc/selinux#g' /usr/lib/python3.*/site-packages/setroubleshoot/util.py && \
    sed -i 's|^ExecStart=.*|ExecStart=/usr/libexec/rtkit-daemon --no-canary|' /usr/lib/systemd/system/rtkit-daemon.service && \
    sed -i 's/power-saver=powersave$/power-saver=powersave-bazzite/' /etc/tuned/ppd.conf && \
    sed -i 's/balanced=balanced$/balanced=balanced-bazzite/' /etc/tuned/ppd.conf && \
    sed -i 's/performance=throughput-performance$/performance=throughput-performance-bazzite/' /etc/tuned/ppd.conf && \
    sed -i 's/balanced=balanced-battery$/balanced=balanced-battery-bazzite\npower-saver=powersave-battery-bazzite/' /etc/tuned/ppd.conf && \
    ln -s /usr/bin/true /usr/bin/pulseaudio && \
    mkdir -p /etc/flatpak/remotes.d && \
    curl --retry 3 -Lo /etc/flatpak/remotes.d/flathub.flatpakrepo https://dl.flathub.org/repo/flathub.flatpakrepo && \
    systemctl enable brew-setup.service && \
    systemctl disable brew-upgrade.timer && \
    systemctl disable brew-update.timer && \
    systemctl disable fw-fanctrl.service && \
    systemctl disable scx_loader.service && \
    systemctl enable input-remapper.service && \
    systemctl enable bazzite-flatpak-manager.service && \
    systemctl disable rpm-ostreed-automatic.timer && \
    systemctl enable uupd.timer && \
    systemctl enable incus-workaround.service && \
    systemctl enable bazzite-hardware-setup.service && \
    systemctl disable tailscaled.service && \
    systemctl enable dev-hugepages1G.mount && \
    systemctl enable ds-inhibit.service && \
    systemctl --global enable bazzite-user-setup.service && \
    systemctl --global enable podman.socket && \
    systemctl --global enable systemd-tmpfiles-setup.service && \
    systemctl --global disable sunshine.service && \
    systemctl disable waydroid-container.service && \
    systemctl disable force-wol.service && \
    systemctl --global enable bazzite-dynamic-fixes.service && \
    /ctx/ghcurl "https://raw.githubusercontent.com/doitsujin/dxvk/master/dxvk.conf" -Lo /etc/dxvk-example.conf && \
    /ctx/ghcurl "https://raw.githubusercontent.com/bazzite-org/waydroid-scripts/main/waydroid-choose-gpu.sh" -Lo /usr/bin/waydroid-choose-gpu && \
    chmod +x /usr/bin/waydroid-choose-gpu && \
    /ctx/ghcurl "https://github.com/ublue-os/toolboxes/raw/refs/heads/main/apps/docker/distrobox.ini" -Lo /etc/distrobox/docker.ini && \
    /ctx/ghcurl "https://github.com/ublue-os/toolboxes/raw/refs/heads/main/apps/incus/distrobox.ini" -Lo /etc/distrobox/incus.ini && \
    /ctx/image-info && \
    /ctx/build-initramfs && \
    /ctx/finalize

RUN dnf5 config-manager setopt skip_if_unavailable=1 && \
    bootc container lint