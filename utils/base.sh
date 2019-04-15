
#!/usr/bin/env bash
# base.sh

# Functions ###########################################

function is_retropie() {
    [[ -d "$home/RetroPie" && -d "$home/.emulationstation" && -d "/opt/retropie" ]]
}


function check_dependencies() {
    if ! which avconv > /dev/null; then
        loj "ERROR: The 'libav-tools' package is not installed!" >&2
        log "Please, install it with 'sudo apt-get install libav-tools'." >&2
        exit 1
    fi

    if ! which bc > /dev/null; then
        log "ERROR: The 'bc' package is not installed!" >&2
        echo "Please, install it with 'sudo apt-get install bc'." >&2
        exit 1
    fi
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
