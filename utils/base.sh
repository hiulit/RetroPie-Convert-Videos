
#!/usr/bin/env bash
# base.sh

# Functions ###########################################

function is_retropie() {
    [[ -d "$home/RetroPie" && -d "$home/.emulationstation" && -d "/opt/retropie" ]]
}


function check_retropie() {
    if ! is_retropie; then
        echo "ERROR: RetroPie is not installed. Aborting ..." >&2
        exit 1
    fi
}


function check_dependencies() {
    local pkg
    for pkg in "${DEPENDENCIES[@]}"; do
        if ! dpkg-query -W -f='${Status}' "$pkg" | awk '{print $3}' | grep -q "^installed$"; then
            echo
            echo "WHOOPS! The '$pkg' package is not installed!"
            echo
            echo "Would you like to install it now?"
            local options=("Yes" "No")
            local option
            select option in "${options[@]}"; do
                case "$option" in
                    Yes)
                        if ! which apt-get > /dev/null; then
                            log "ERROR: Can't install '$pkg' automatically. Try to install it manually."
                            exit 1
                        else
                            if sudo apt-get install "$pkg"; then
                                echo
                                log "YIPPEE! The '$pkg' package installation was successful!"
                            fi
                            break
                        fi
                        ;;
                    No)
                        log "ERROR: Can't launch the script if the '$pkg' package is not installed."
                        exit 1
                        ;;
                    *)
                        echo "Invalid option. Choose a number between 1 and ${#options[@]}."
                        ;;
                esac
            done
        fi
    done
}


function check_argument() {
    # This method doesn't accept arguments starting with '-'.
    if [[ -z "$2" || "$2" =~ ^- ]]; then
        echo >&2
        echo "ERROR: '$1' is missing an argument." >&2
        echo >&2
        echo "Try '$0 --help' for more info." >&2
        echo "Or read the documentation in the README." >&2
        echo >&2
        return 1
    fi
}


function encode_string_with_spaces() {
    local string="$1"
    local whitespace_encoder_default="-..-"
    local whitespace_encoder
    if [[ -n "$2" ]]; then
        whitespace_encoder="$2"
    else
        whitespace_encoder="$whitespace_encoder_default"
    fi
    echo "${string// /$whitespace_encoder}"
}


function decode_string_with_spaces() {
    local string="$1"
    local whitespace_decoder_default="-..-"
    local whitespace_decoder
    if [[ -n "$2" ]]; then
        whitespace_decoder="$2"
    else
        whitespace_decoder="$encode_string_default"
    fi
    echo "${string//$whitespace_decoder_default/ }"
}

function remove_leading_trailing_whitespace() {
    local string
    string="$1"
    echo "$string" | awk '{$1=$1};1'
}


function log() {
    echo "$*" >> "$LOG_FILE"
    echo "$*"
}


function underline() {
    local dashes
    local string="$1"
    if [[ -z "$string" ]]; then
        log "Missing a string as an argument."
        exit 1
    fi
    echo "$string"
    for ((i=1; i<="${#string}"; i+=1)); do [[ -n "$dashes" ]] && dashes+="-" || dashes="-"; done && echo "$dashes"
}


function usage() {
    echo
    echo "USAGE: $0 [OPTIONS]"
    echo
    echo "Use '$0 --help' to see all the options."
    echo
}


function ctrl_c() {
    # echo "Trapped CTRL-C"
    log >&2
    log "Cancelled by user." >&2
    exit 1
}
