_zdots-update:
    #!/usr/bin/env bash
    yes s | chezmoi apply --no-tty --keep-going -S "/usr/share/zirconium/zdots" --verbose --config "$HOME/.config/zirconium/chezmoi/chezmoi.toml"

_zdots-reset FILE:
    #!/usr/bin/env bash
    chezmoi apply --force -S "/usr/share/zirconium/zdots" --verbose --config "$HOME/.config/zirconium/chezmoi/chezmoi.toml" {{ FILE }}

_zdots-override-all:
    #!/usr/bin/env bash
    chezmoi apply --force -S "/usr/share/zirconium/zdots" --verbose --config "$HOME/.config/zirconium/chezmoi/chezmoi.toml" 

restart-shell:
    #!/usr/bin/env bash
    if systemctl is-active --quiet --user dms ; then
        systemctl restart --user dms
    elif systemctl is-active --quiet --user noctalia ; then
        systemctl restart --user noctalia
    fi

switch-to-dms:
    #!/usr/bin/env bash
    sed -i "s@include \"noctalia.kdl\"@\/\/ include \"noctalia.kdl\"@" $HOME/.config/niri/config.kdl
    sed -i "s@\/\/ include \"dms.kdl\"@include \"dms.kdl\"@" $HOME/.config/niri/config.kdl
    systemctl mask --now --user noctalia.service
    systemctl unmask --user dms.service
    systemctl enable --now --user dms.service
    systemctl disable --now --user swayidle.service

switch-to-noctalia:
    #!/usr/bin/env bash
    sed -i "s@include \"dms.kdl\"@\/\/ include \"dms.kdl\"@" $HOME/.config/niri/config.kdl
    sed -i "s@\/\/ include \"noctalia.kdl\"@include \"noctalia.kdl\"@" $HOME/.config/niri/config.kdl
    systemctl mask --now --user dms.service
    systemctl unmask --user noctalia.service
    systemctl enable --now --user noctalia.service
    systemctl enable --now --user swayidle.service

_reset-niri:
    #!/usr/bin/env bash
    zjust zdots-reset "${HOME}/.config/niri"

update-greeter:
    dms greeter sync
