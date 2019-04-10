#!/usr/bin/env bash

# Convert videos for RetroPie.
# A tool for RetroPie to convert videos.
#
# Author: hiulit
# Repository: https://github.com/hiulit/RetroPie-Convert-Videos
# Issues: https://github.com/hiulit/RetroPie-Convert-Videos/issues
# License: MIT https://github.com/hiulit/RetroPie-Convert-Videos/blob/master/LICENSE
#
# Requirements:
# - Retropie 4.x.x
# - libav-tools package


# Globals ########################################

home="$(find /home -type d -name RetroPie -print -quit 2>/dev/null)"
home="${home%/RetroPie}"

readonly SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
readonly SCRIPT_TITLE="Convert videos for RetroPie."
readonly SCRIPT_DESCRIPTION="A tool for RetroPie to convert videos."
readonly SCRIPT_CFG="$SCRIPT_DIR/retropie-convert-videos-settings.cfg"

readonly ROMS_DIR="$home/RetroPie/roms"
readonly CONVERTED_VIDEOS_DIR="converted"

readonly LOG_DIR="$SCRIPT_DIR/logs"
readonly LOG_FILE="$LOG_DIR/$(date +%F-%T).log"


# Variables #####################################

readonly SCRAPERS=("sselph" "skyscraper")

VIDEOS_DIR=""


# Flags #########################################

CONFIG_FLAG=0


# External resources ############################

source "$SCRIPT_DIR/utils/base.sh"


# Functions #####################################

function is_retropie() {
    [[ -d "$home/RetroPie" && -d "$home/.emulationstation" && -d "/opt/retropie" ]]
}


function check_dependencies() {
    if ! which avconv > /dev/null; then
        echo "ERROR: The libav-tools package is not installed!" >&2
        echo "Please, install it with 'sudo apt-get install libav-tools'." >&2
        exit 1
    fi
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


function check_argument() {
    # XXX: this method doesn't accept arguments starting with '-'.
    if [[ -z "$2" || "$2" =~ ^- ]]; then
        echo "ERROR: '$1' is missing an argument." >&2
        echo >&2
        echo "Try '$0 --help' for more info." >&2
        return 1
    fi
}


function set_config() {
    sed -i "s|^\($1\s*=\s*\).*|\1\"$2\"|" "$SCRIPT_CFG"
    echo "\"$1\" set to \"$2\"."
}


function get_config() {
    local config
    config="$(grep -Po "(?<=^$1 = ).*" "$SCRIPT_CFG")"
    config="${config%\"}"
    config="${config#\"}"
    echo "$config"
}


function check_config() {
    CONFIG_FLAG=1
    local from_color
    local to_color
    local scraper
    from_color="$(get_config "from_color")"
    to_color="$(get_config "to_color")"
    scraper="$(get_config "scraper")"

    if [[ -z "$to_color" ]]; then
        log "'to_color' value (mandatory) not found in '$SCRIPT_CFG'" >&2
        log >&2
        log "Try '$0 --help' for more info." >&2
        exit 1
    fi

    if [[ -z "$scraper" ]]; then
        log "'scraper' value (mandatory) not found in '$SCRIPT_CFG'" >&2
        log >&2
        log "Try '$0 --help' for more info." >&2
        exit 1
    fi

    validate_scraper "$scraper"
    validate_CES "$from_color"
    validate_CES "$to_color"
}


function usage() {
    echo
    echo "USAGE: $0 [options]"
    echo
    echo "Use '$0 --help' to see all the options."
    echo
}


function validate_CES() {
    local ces
    ces="$1"

    [[ -z "$ces" ]] && return 0

    if avconv -loglevel quiet -pix_fmts | grep -q -w "$ces"; then
        return 0
    else
        log "ERROR: Invalid Color Encoding System (C.E.S): '$ces'." >&2
        log >&2
        if [[ "$CONFIG_FLAG" -eq 1 ]]; then
            log "Check '$SCRIPT_CFG'" >&2
            log >&2
        fi
        log "TIP: Run the 'avconv -pix_fmts' command to get a full list of Color Encoding Systems (C.E.S)." >&2
        exit 1
    fi
}

function validate_scraper() {
    local scraper
    scraper="$1"

    if ! printf '%s\n' "${SCRAPERS[@]}" | grep -w "$scraper" &>/dev/null; then
        log "The '$scraper' scraper is not supported." >&2
        log >&2
        log "Try one of the supported scrapers:" >&2
        for item in ${SCRAPERS[@]}; do
            log "- $item" >&2
        done
        exit 1
    fi

    if [[ "$scraper" == "sselph" ]]; then
        VIDEOS_DIR="images"
    elif [[ "$scraper" == "skyscraper" ]]; then
        VIDEOS_DIR="media"
    fi
}


function convert_video() {
    local video
    video="$1"

    if [[ -z "$video" ]]; then
        log "ERROR: In line ${BASH_LINENO}." >&2
        log "'${FUNCNAME[0]}' function needs a path to a video file."
        exit 1
    fi

    mkdir -p "$rom_dir/$VIDEOS_DIR/$converted_videos_dir"

    avconv -i "$video" -y -pix_fmt "$to_color" -strict experimental "$rom_dir/$VIDEOS_DIR/$converted_videos_dir/$(basename "$video")"
    result_value="$?"
    if [[ "$result_value" -eq 0 ]]; then
        results+=("> \"$(basename "$video")\" --> SUCCESSFUL!")
        ((successful++))
    else
        results+=("> \"$(basename "$video")\" --> FAILED!")
        ((unsuccessful++))
        mv "$rom_dir/$VIDEOS_DIR/$converted_videos_dir/$(basename "$video")" "$rom_dir/$VIDEOS_DIR/$converted_videos_dir/$(basename "$video")-failed"
    fi
}


function check_CES() {
    local video
    video="$1"

    if [[ -z "$video" ]]; then
        log "ERROR: No video input file detected." >&2
        exit 1
    fi

    local CES
    CES="$(avprobe -show_streams "$video" | grep -Po "(?<=^pix_fmt=).*")"
    echo "$CES"
}


function convert_videos() {
    local systems=()
    local roms_dir=()
    local rom_dir
    local from_color
    local to_color
    local results=()
    local successful=0
    local unsuccessful=0
    local converted_videos_dir

    systems="$1"

    IFS=" " read -r -a systems <<< "${systems[@]}"
    for system in "${systems[@]}"; do
        roms_dir+=("$ROMS_DIR/$system")
    done

    if [[ "${#roms_dir[@]}" -eq 0 ]]; then
        log "No systems selected" >&2
        log "Aborting ..." >&2
        exit 1
    fi

    [[ -n "$2" ]] && validate_CES "$2"
    [[ -n "$3" ]] && validate_CES "$3"

    log
    log "Starting video conversion ..."
    log

    for rom_dir in "${roms_dir[@]}"; do
        if [[ ! -L "$rom_dir" ]]; then # Filter out symlinks.
            if [[ -d "$rom_dir/$VIDEOS_DIR" ]]; then
                results+=("$(underline "$(basename "$rom_dir")")")
                for video in "$rom_dir/$VIDEOS_DIR"/*.mp4; do
                    if [[ -n "$3" ]]; then
                        from_color="$2"
                        to_color="$3"
                        converted_videos_dir="$CONVERTED_VIDEOS_DIR-$to_color"
                        if avprobe "$video" 2>&1 | grep -q "$from_color"; then
                            convert_video "$video"
                        else
                            results+=("> $(basename "$video") --> Doesn't use '$from_color' Color Encoding System (C.E.S).")
                            ((unsuccessful++))
                        fi
                    else
                        to_color="$2"
                        converted_videos_dir="$CONVERTED_VIDEOS_DIR-$to_color"
                        convert_video "$video"
                    fi
                done
                results+=("")
            fi
        fi
    done
    log
    for result in "${results[@]}"; do
        log "$result"
    done
    log
    if [[ "$successful" -gt 0 ]]; then
        if [[ "$successful" -gt 1 ]]; then
            log "$successful videos were successful."
        else
            log "$successful video was successful."
        fi
    fi
    if [[ "$unsuccessful" -gt 0 ]]; then
        if [[ "$unsuccessful" -gt 1 ]]; then
            log "$unsuccessful videos were unsuccessful."
        else
            log "$unsuccessful video was unsuccessful."
        fi
    fi
}


function get_all_systems() {
    local all_systems=()
    local system_dir
    local i=1
    for system_dir in "$ROMS_DIR/"*; do
        if [[ ! -L "$system_dir" ]]; then # Filter out symlinks.
            if [[ -d "$system_dir/$VIDEOS_DIR" ]]; then
                all_systems+=("$(basename "$system_dir")")
                ((i++))
            fi
        fi
    done
    echo "${all_systems[@]}"
}


function get_options() {
    if [[ -z "$1" ]]; then
        usage
        exit 0
    else
        case "$1" in
#H -h, --help                       Print the help message and exit.
            -h|--help)
                echo
                echo "$SCRIPT_TITLE"
                echo "$SCRIPT_DESCRIPTION"
                echo
                echo "USAGE: $0 [OPTIONS]"
                echo
                echo "OPTIONS:"
                echo
                sed '/^#H /!d; s/^#H //' "$0"
                echo
                exit 0
                ;;
#H -f, --from-color [C.E.S]         Set Color Encoding System (C.E.S) to convert from.
            -f|--from-color)
                check_argument "$1" "$2" || exit 1
                shift
                validate_CES "$1"
                set_config "from_color" "$1"
                ;;
#H -t, --to-color [C.E.S]           Set Color Encoding System (C.E.S) to convert to.
            -t|--to-color)
                check_argument "$1" "$2" || exit 1
                shift
                validate_CES "$1"
                set_config "to_color" "$1"
                ;;
#H -r, --scraper                    Set the scraper.
            -r|--scraper)
                check_argument "$1" "$2" || exit 1
                shift
                set_config "scraper" "$1"
                ;;
#H -a, --convert-all                Convert videos for all systems.
            -a|--convert-all)
                check_config
                local from_color
                local to_color
                from_color="$(get_config "from_color")"
                to_color="$(get_config "to_color")"
                convert_videos "$(get_all_systems)" "$from_color" "$to_color"
                ;;
#H -s, --convert-systems [SYSTEMS]  Select systems to convert videos.
            -s|--convert-systems)
                local cmd
                local systems=()
                local system
                local options=()
                local i=1
                local choices
                local choice
                local selected_systems=()
                local no_found_systems=()
                local from_color
                local to_color

                check_config

                if [[ -n "$2" ]]; then
                    log "$(underline "CLI mode")"
                    log

                    local input_systems=("$2")
                    log "Inputted systems: '${input_systems[@]}'."
                    IFS=" " read -r -a input_systems <<< "${input_systems[@]}"

                    systems="$(get_all_systems)"
                    IFS=" " read -r -a systems <<< "${systems[@]}"

                    for system in "${systems[@]}"; do
                        for input_system in "${input_systems[@]}"; do
                            if [[ "$input_system" == "$system" ]]; then
                                selected_systems+=("$input_system")
                            fi
                        done
                    done

                    for input_system in ${input_systems[@]}; do
                        if ! printf '%s\n' "${selected_systems[@]}" | grep -w "$input_system" &>/dev/null; then
                            no_found_systems+=("$input_system")
                        fi
                    done

                    if [[ "${#selected_systems[@]}" -eq 0 ]]; then
                        log "ERROR: No videos found for any of the inputted ('${input_systems[@]}') systems!" >&2
                        log "Aborting ..."
                        exit 1
                    else
                        log "Systems found: '${selected_systems[@]}'."
                        selected_systems="${selected_systems[@]}"
                        if [[ "${#no_found_systems[@]}" -gt 0 ]]; then
                            log
                            log "No videos found for the following systems: '"${no_found_systems[@]}"'." >&2
                        fi
                    fi
                else
                    log "$(underline "GUI mode")"
                    log
                    cmd=(dialog \
                        --backtitle "$SCRIPT_TITLE" \
                        --checklist "Select ROM folders" 15 50 15)

                    systems="$(get_all_systems)"
                    if [[ "${systems[@]}" -eq 0 ]]; then
                        local scraper
                        scraper="$(get_config "scraper")"
                        log "ERROR: No videos found in any systems!" >&2
                        log >&2
                        log "You are using '$scraper' scraper." >&2
                        if [[ "$scraper" == "sselph" ]]; then
                            log "Remember to use the 'ROM folder for gamelists & images' option." >&2
                        elif [[ "$scraper" == "skyscraper" ]]; then
                            log "Remember to use the 'ROM folder for gamelists & media' option." >&2
                        fi
                        log >&2
                        log "Or maybe try using '$(printf '%s\n' "${SCRAPERS[@]}" | grep -Fv "$scraper")'." >&2
                        exit 1
                    fi
                    IFS=" " read -r -a systems <<< "${systems[@]}"
                    for system in "${systems[@]}"; do
                        options+=("$i" "$system" off)
                        ((i++))
                    done

                    choices="$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)"

                    if [[ -z "${choices[@]}" ]]; then
                        log "No systems selected." >&2
                        log "Aborting ..."
                        exit 1
                    fi

                    IFS=" " read -r -a choices <<< "${choices[@]}"
                    for choice in "${choices[@]}"; do
                        selected_systems+=("${options[choice*3-2]}")
                    done
                    log "Selected systems: '${selected_systems[@]}'."
                    selected_systems="${selected_systems[@]}"
                fi

                from_color="$(get_config "from_color")"
                to_color="$(get_config "to_color")"
                convert_videos "$selected_systems" "$from_color" "$to_color"
                ;;
            *)
                echo "ERROR: Invalid option '$1'." >&2
                exit 2
                ;;
        esac
    fi
}


function main() {

    if ! is_retropie; then
        echo "ERROR: RetroPie is not installed. Aborting ..." >&2
        exit 1
    fi

    check_dependencies

    mkdir -p "$LOG_DIR"

    find "$LOG_DIR" -type f | sort | head -n -9 | xargs -d '\n' --no-run-if-empty rm

    get_options "$@"
}


main "$@"
