_zdots-update:
    #!/usr/bin/env bash
    yes s | chezmoi apply --no-tty --keep-going -S "/usr/share/zirconium/zdots" --verbose --config "$HOME/.config/zirconium/chezmoi/chezmoi.toml"

_zdots-reset FILE:
    #!/usr/bin/env bash
    chezmoi apply --force -S "/usr/share/zirconium/zdots" --verbose --config "$HOME/.config/zirconium/chezmoi/chezmoi.toml" {{ FILE }}

_zdots-override-all:
    #!/usr/bin/env bash
    chezmoi apply --force -S "/usr/share/zirconium/zdots" --verbose --config "$HOME/.config/zirconium/chezmoi/chezmoi.toml" 

_reset-niri:
    #!/usr/bin/env bash
    if ! command -v gum &>/dev/null ; then
        echo "This script requires gum to run, install it: brew install gum"
        exit 1
    fi
    if gum confirm "Are you sure you want to reset your niri configuration?" ; then
        zjust zdots-reset "${HOME}/.config/niri"
    fi

update-greeter:
    dms greeter sync
