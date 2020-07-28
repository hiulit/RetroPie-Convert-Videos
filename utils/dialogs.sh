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
        --yes-label "Yes" \
        --no-label "No" \
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
        --ok-label "OK" \
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


function dialog_select_systems() {
    cmd=(dialog \
        --backtitle "$SCRIPT_TITLE (v$SCRIPT_VERSION)" \
        --title "$SCRIPT_TITLE" \
        --ok-label "OK" \
        --cancel-label "Exit" \
        --extra-button \
        --extra-label "Back" \
        --checklist "Select systems." "$DIALOG_HEIGHT" "$DIALOG_WIDTH" "${#systems[@]}")

    IFS=" " read -r -a systems <<< "${systems[@]}"
    for system in "${systems[@]}"; do
        local decoded_system
        decoded_system="$(decode_string_with_spaces "$system")"
        options+=("$i" "$decoded_system" off)
        ((i++))
    done

    choices="$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)"
    local return_value="$?"

    if [[ "$return_value" -eq "$DIALOG_OK" ]]; then
        if [[ -n "${choices[@]}" ]]; then
            log "$(underline "GUI mode")"
            log

            IFS=" " read -r -a choices <<< "${choices[@]}"
            for choice in "${choices[@]}"; do
                selected_systems+=("${options[choice*3-2]}")
            done
            log "> Selected systems: '${selected_systems[@]}'."

            local encoded_selected_systems=()
            for selected_system in "${selected_systems[@]}"; do
                local encoded_system
                encoded_system="$(encode_string_with_spaces "$selected_system")"
                encoded_selected_systems+=("$encoded_system")
            done

            selected_systems="${encoded_selected_systems[@]}"
        else
            dialog_msgbox "Info" "You must select at least 1 system."
            dialog_select_systems
        fi
    elif [[ "$return_value" -eq "$DIALOG_EXTRA" ]]; then
       dialog_choose_all_systems_or_systems
    elif [[ "$return_value" -eq "$DIALOG_CANCEL" ]]; then
        exit 0
    fi
}
