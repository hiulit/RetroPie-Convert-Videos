#!/usr/bin/env bash
# dialogs.sh

# Variables ############################################

DIALOG_BACKTITLE="$SCRIPT_TITLE (v$SCRIPT_VERSION)"
readonly DIALOG_HEIGHT=20
readonly DIALOG_WIDTH=60
readonly DIALOG_OK=0
readonly DIALOG_CANCEL=1
readonly DIALOG_HELP=2
readonly DIALOG_EXTRA=3
readonly DIALOG_ESC=255


# Functions ###########################################

function dialog_msgbox() {
    local title="$1"
    local message="$2"
    local dialog_height="$3"
    local dialog_width="$4"
    [[ -z "$title" ]] && echo "ERROR: '${FUNCNAME[0]}' needs a title as an argument!" && exit 1
    [[ -z "$message" ]] && echo "ERROR: '${FUNCNAME[0]}' needs a message as an argument!" && exit 1
    [[ -z "$dialog_height" ]] && dialog_height=8
    [[ -z "$dialog_width" ]] && dialog_width="$DIALOG_WIDTH"
    dialog \
        --backtitle "$DIALOG_BACKTITLE" \
        --title "$1" \
        --ok-label "OK" \
        --msgbox "$2" "$dialog_height" "$dialog_width" 2>&1 >/dev/tty
}


function dialog_yesno() {
    local title="$1"
    local message="$2"
    local dialog_height="$3"
    local dialog_width="$4"
    [[ -z "$title" ]] && echo "ERROR: '${FUNCNAME[0]}' needs a title as an argument!" && exit 1
    [[ -z "$message" ]] && echo "ERROR: '${FUNCNAME[0]}' needs a message as an argument!" && exit 1
    [[ -z "$dialog_height" ]] && dialog_height=8
    [[ -z "$dialog_width" ]] && dialog_width="$DIALOG_WIDTH"
    dialog \
        --backtitle "$DIALOG_BACKTITLE" \
        --title "$1" \
        --yesno "$2" "$dialog_height" "$dialog_width" 2>&1 >/dev/tty
}


function dialog_choose_all_systems_or_systems() {
    [[ "$STANDALONE_FLAG" -eq 0 ]] && check_retropie

    local options=()
    local menu_text
    local cmd
    local choice

    options=(
        1 "Select systems"
        2 "All systems"
    )
    menu_text="Choose an option."
    cmd=(dialog \
        --backtitle "$DIALOG_BACKTITLE" \
        --title "$SCRIPT_TITLE" \
        --cancel-label "Exit" \
        --menu "$menu_text" 15 "$DIALOG_WIDTH" 15)
    choice="$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)"
    local return_value="$?"

    if [[ "$return_value" -eq "$DIALOG_OK" ]]; then
        if [[ -n "$choice" ]]; then
            case "$choice" in
                1)
                    eval "$SCRIPT_FULL -s"
                    ;;
                2)
                    eval "$SCRIPT_FULL -a"
                    ;;
            esac
        else
            dialog_msgbox "Error!" "Choose an option."
        fi
    elif [[ "$return_value" -eq "$DIALOG_CANCEL" ]]; then
        exit 0
    fi
}
