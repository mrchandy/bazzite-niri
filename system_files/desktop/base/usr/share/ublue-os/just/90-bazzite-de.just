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

enable-dsearch ACTION="":
    #!/usr/bin/env bash
    source /usr/lib/ujust/ujust.sh
    DSEARCH_STATUS="Disabled"
    if systemctl --user is-enabled dsearch | grep -q enabled; then
      DSEARCH_STATUS="Enabled"
    fi
    OPTION="{{ ACTION }}"
    if [ "$OPTION" == "help" ]; then
      echo "Usage: ujust enable-dsearch <option>"
      echo "  <option>: Specify the option to skip the interactive prompt"
      echo "  Use 'enable' to enable dsearch service"
      echo "  Use 'disable' to disable dsearch service"
      exit 0
    elif [ "$OPTION" == "" ]; then
      # Display current status
      if [ "$DSEARCH_STATUS" == "Enabled" ]; then
        echo -e "\n${bold}dsearch${normal} is ${green}$DSEARCH_STATUS${normal}\n"
      else
        echo -e "\n${bold}dsearch${normal} is ${yellow}$DSEARCH_STATUS${normal}\n"
      fi
      # Prompt user for action
      echo "Choose an option:"
      OPTION=$(ugum choose "Enable dsearch" "Disable dsearch" "Exit without saving")
    fi
    case "$OPTION" in
      "Enable dsearch"|enable)
        echo "Enabling dsearch..."
        systemctl --user enable dsearch
        systemctl --user start dsearch
        echo -e "\n${bold}dsearch is now ${green}Enabled${normal}."
        echo -e "\n${bold}dsearch${normal} config is generated at ~/.config/danksearch/config.toml"
        echo -e "See https://danklinux.com/docs/danksearch/configuration for configuration documentation."
        echo -e "\nUse ${bold}dsearch index generate${normal} to build the initial index"
        echo -e "Initiate a filesystem search by typing ${bold}/ ${normal}in the launcher"
        echo " "
        ;;
      "Disable dsearch"|disable)
        echo -e "\nDisabling dsearch..."
        systemctl --user disable dsearch
        systemctl --user stop dsearch
        echo -e "\n${bold}dsearch${normal} is now ${yellow}Disabled${normal}."
        echo " "
        ;;
      "Exit without saving"|*)
        echo "No changes made."
        ;;
    esac
