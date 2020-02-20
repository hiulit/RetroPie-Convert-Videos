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
# - RetroPie 4.x.x
# - libav-tools
# - bc


# Globals ########################################

home="$(find /home -type d -name RetroPie -print -quit 2>/dev/null)"
home="${home%/RetroPie}"

readonly SCRIPT_VERSION="2.1.2"
readonly SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_FULL="$SCRIPT_DIR/$SCRIPT_NAME"
readonly SCRIPT_TITLE="RetroPie Convert Videos"
readonly SCRIPT_DESCRIPTION="A tool for RetroPie to convert videos."
readonly SCRIPT_CFG="$SCRIPT_DIR/retropie-convert-videos-settings.cfg"

readonly CONVERTED_VIDEOS_DIR="converted"

readonly LOG_DIR="$SCRIPT_DIR/logs"
readonly LOG_FILE="$LOG_DIR/$(date +%F-%T).log"

readonly DEPENDENCIES=("ffmpeg" "bc")


# Variables #####################################

readonly SCRAPERS=("sselph" "skyscraper")

ROMS_DIR="$home/RetroPie/roms"
VIDEOS_DIR=""


# Flags #########################################

CONFIG_FLAG=0
STANDALONE_FLAG=0


# External resources ############################

source "$SCRIPT_DIR/utils/base.sh"
source "$SCRIPT_DIR/utils/dialogs.sh"
source "$SCRIPT_DIR/utils/progress-bar.sh"


# Functions #####################################

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
    local from_ces
    local to_ces
    local scraper
    local roms_path
    from_ces="$(get_config "from_ces")"
    to_ces="$(get_config "to_ces")"
    scraper="$(get_config "scraper")"
    roms_path="$(get_config "roms_path")"

    if [[ -z "$to_ces" ]]; then
        echo
        log "'to_ces' value (mandatory) not found in '$SCRIPT_CFG'" >&2
        log >&2
        log "Try '$0 --help' for more info." >&2
        log >&2
        log "Or read the documentation in the README." >&2
        echo
        exit 1
    fi

    if [[ -z "$scraper" ]]; then
        echo
        log "'scraper' value (mandatory) not found in '$SCRIPT_CFG'" >&2
        log >&2
        log "Try '$0 --help' for more info." >&2
        log "Or read the documentation in the README." >&2
        echo
        exit 1
    fi

    validate_CES "$from_ces"
    validate_CES "$to_ces"
    validate_scraper "$scraper"

    if [[ -n "$roms_path" ]]; then
        validate_path "$roms_path"
        ROMS_DIR="$roms_path"
    fi
}


function validate_CES() {
    local ces
    ces="$1"

    [[ -z "$ces" ]] && return 0

    if ffmpeg -loglevel quiet -pix_fmts | grep -q -w "$ces"; then
        return 0
    else
        log "ERROR: Invalid Color Encoding System (C.E.S): '$ces'." >&2
        log >&2
        if [[ "$CONFIG_FLAG" -eq 1 ]]; then
            log "Check '$SCRIPT_CFG'." >&2
            log >&2
        fi
        log "TIP: Run the 'ffmpeg -pix_fmts' command to get a full list of Color Encoding Systems (C.E.S)." >&2
        exit 1
    fi
}

function validate_scraper() {
    local scraper
    scraper="$1"

    if ! printf '%s\n' "${SCRAPERS[@]}" | grep -w "$scraper" &>/dev/null; then
        echo
        log "The '$scraper' scraper is not supported." >&2
        log >&2
        log "Try one of the supported scrapers:" >&2
        for item in ${SCRAPERS[@]}; do
            log "- $item" >&2
        done
        echo
        exit 1
    fi

    if [[ "$scraper" == "sselph" ]]; then
        VIDEOS_DIR="images"
    elif [[ "$scraper" == "skyscraper" ]]; then
        VIDEOS_DIR="media/videos"
    fi
}

function validate_path() {
    [[ -z "$1" ]] && return 0

    if [[ ! -d "$1" ]]; then
        log "ERROR: '$1' path doesn't exist." >&2
        log >&2
        if [[ "$CONFIG_FLAG" -eq 1 ]]; then
            log "Check '$SCRIPT_CFG'." >&2
        fi
        exit 1
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

    log "$(underline "$(basename "$rom_dir")")"
    log "Converting -> \"$(basename "$video")\" ... ($i/${#videos[@]})"
    # The conversion function used to be here but it's been moved to 'utils/progress-bar.sh'.
    # ffmpeg -i "$video" -y -pix_fmt "$to_ces" -strict experimental "$rom_dir/$VIDEOS_DIR/$converted_videos_dir/$(basename "$video")"
    progress_bar
    return_value="$?"
    if [[ "$return_value" -eq 1 ]]; then
        return 1
    fi
    log "Done."
    log
}


function check_CES() {
    local video
    video="$1"
    if [[ -z "$video" ]]; then
        log "ERROR: Can't check for C.E.S. No video input file detected." >&2
        exit 1
    fi

    [[ -z "$from_ces" ]] && return 0 # Ignore the checking if "$from_ces" is not set

    local ces
    ces="$(avprobe -show_streams "$video" 2>&1 | grep -Po "(?<=^pix_fmt=).*")"
    [[ "$ces" == "$to_ces" ]] && return 1 || return 0
}


function convert_videos() {
    local systems=()
    local roms_dir=()
    local rom_dir
    local from_ces
    local to_ces
    local results=()
    local successful=0
    local unsuccessful=0
    local failed=0
    local converted_videos_dir

    systems="$1"

    IFS=" " read -r -a systems <<< "${systems[@]}"
    for system in "${systems[@]}"; do
        roms_dir+=("$ROMS_DIR/$system")
    done

    if [[ "${#roms_dir[@]}" -eq 0 ]]; then
        echo "No systems selected" >&2
        echo "Aborting ..." >&2
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
                local videos
                videos=("$rom_dir/$VIDEOS_DIR"/*.mp4)
                local i=1
                for video in "${videos[@]}"; do
                    if [[ -n "$3" ]]; then
                        from_ces="$2"
                        to_ces="$3"
                        converted_videos_dir="$CONVERTED_VIDEOS_DIR-$to_ces"
                        if avprobe "$video" 2>&1 | grep -q "$from_ces"; then
                            check_CES "$video"
                            local return_value="$?"
                            if [[ "$return_value" -eq 0 ]]; then
                                convert_video "$video"
                                if [[ "$return_value" -eq 0 ]]; then
                                    results+=("> \"$(basename "$video")\" --> SUCCESSFUL!")
                                    ((successful++))
                                else
                                    results+=("> \"$(basename "$video")\" --> FAILED!")
                                    ((failed++))
                                    if [[ -f "$rom_dir/$VIDEOS_DIR/$converted_videos_dir/$(basename "$video")" ]]; then
                                        mv "$rom_dir/$VIDEOS_DIR/$converted_videos_dir/$(basename "$video")" "$rom_dir/$VIDEOS_DIR/$converted_videos_dir/$(basename "$video")-failed"
                                    fi
                                fi
                            else
                                results+=("> \"$(basename "$video")\" --> Don't convert! Has the same Color Encoding System (C.E.S) as 'from_ces': '$from_ces'.")
                                ((unsuccessful++))
                            fi
                        else
                            results+=("> $(basename "$video") --> Can't convert! Doesn't use the Color Encoding System (C.E.S set in 'from_ces': '$from_ces'.")
                            ((unsuccessful++))
                        fi
                    else
                        to_ces="$2"
                        converted_videos_dir="$CONVERTED_VIDEOS_DIR-$to_ces"
                        convert_video "$video"
                    fi
                    ((i++))
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
    if [[ "$failed" -gt 0 ]]; then
        if [[ "$unsuccessful" -gt 1 ]]; then
            log "$failed videos failed."
        else
            log "$failed video failed."
        fi
    fi
    echo
    echo "See the log file in '$LOG_DIR'."
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
#H -h, --help                       Print the help message.
            -h|--help)
                echo
                underline "$SCRIPT_TITLE"
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
#H -p, --path [PATH]                Set the path to the ROMs folder.
            -p|--path)
                check_argument "$1" "$2" || exit 1
                shift
                validate_path "$1"
                set_config "roms_path" "$1"
                exit
                ;;
#H -f, --from-ces [C.E.S]           Set Color Encoding System (C.E.S) to convert from.
            -f|--from-ces)
                check_argument "$1" "$2" || exit 1
                shift
                validate_CES "$1"
                set_config "from_ces" "$1"
                ;;
#H -t, --to-ces [C.E.S]             Set Color Encoding System (C.E.S) to convert to (mandatory).
            -t|--to-ces)
                check_argument "$1" "$2" || exit 1
                shift
                validate_CES "$1"
                set_config "to_ces" "$1"
                ;;
#H -r, --scraper [SCRAPER]          Set the scraper (mandatory).
            -r|--scraper)
                check_argument "$1" "$2" || exit 1
                shift
                set_config "scraper" "$1"
                ;;
#H -a, --convert-all                Convert videos for all systems.
            -a|--convert-all)
                [[ "$STANDALONE_FLAG" -eq 0 ]] && check_retropie

                check_config
                local from_ces
                local to_ces
                from_ces="$(get_config "from_ces")"
                to_ces="$(get_config "to_ces")"
                dialog_yesno "Warning!" "Converting videos is very demanding.\nIt takes about 35 seconds to convert a video, so if you have a lot of videos... Do the math ;)\n\nDo you want to continue anyway?" 10
                local return_value="$?"
                if [[ "$return_value" -eq 0 ]]; then
                    log "$(underline "Convert all systems ($(get_all_systems))")"
                    log
                    convert_videos "$(get_all_systems)" "$from_ces" "$to_ces"
                else
                    echo "Aborting ..." >&2
                    exit 1
                fi
                ;;
#H -s, --convert-systems [SYSTEMS]  Select systems to convert videos.
            -s|--convert-systems)
                [[ "$STANDALONE_FLAG" -eq 0 ]] && check_retropie

                local cmd
                local systems=()
                local system
                local options=()
                local i=1
                local choices
                local choice
                local selected_systems=()
                local no_found_systems=()
                local from_ces
                local to_ces

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

                    systems="$(get_all_systems)"
                    IFS=" " read -r -a systems <<< "${systems[@]}"

                    cmd=(dialog \
                        --backtitle "$SCRIPT_TITLE" \
                        --checklist "Select systems" "$DIALOG_HEIGHT" "$DIALOG_WIDTH" "${#systems[@]}")

                    if [[ "${#systems[@]}" -eq 0 ]]; then
                        local scraper
                        scraper="$(get_config "scraper")"
                        local roms_path
                        roms_path="$(get_config "roms_path")"

                        log "ERROR: No videos found in any system!" >&2
                        log >&2
                        log "$(underline "Troubleshooting")" >&2
                        log >&2
                        log "$(underline "ROMs path")" >&2
                        if [[ -z "$roms_path" ]]; then
                            roms_path="$ROMS_DIR"
                            log "You are using the default ROMs path: '$roms_path'." >&2
                            log >&2
                            log "If that's not the path to your ROMs folder, you can change it by using the '--path' option." >&2
                            log "(e.g. '$0 --path \"/path/to/your/roms/folder\"')." >&2
                            log >&2
                            log "Or by editting the value of 'roms_path' directly in '$SCRIPT_CFG'." >&2
                        else
                            log "Check the 'roms_path' value in '$SCRIPT_CFG'." >&2
                            log "Right now it's set to '$roms_path'. Is that correct?" >&2
                        fi
                        log >&2
                        log "$(underline "Scraper")" >&2
                        log "You are using '$scraper' scraper." >&2
                        log >&2
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

                from_ces="$(get_config "from_ces")"
                to_ces="$(get_config "to_ces")"
                convert_videos "$selected_systems" "$from_ces" "$to_ces"
                ;;
#H -g, --gui [STANDALONE]           Start the GUI.
            -g|--gui)
                if [[ -n "$2" ]] && [[ "$2" == "standalone" ]]; then
                    STANDALONE_FLAG=1
                fi
                dialog_choose_all_systems_or_systems
                ;;
#H -v, --version                    Print the script's version.
            -v|--version)
                echo "$SCRIPT_VERSION"
                exit 0
                ;;
            *)
                echo "ERROR: Invalid option '$1'." >&2
                exit 2
                ;;
        esac
    fi
}


function main() {
    check_dependencies

    mkdir -p "$LOG_DIR"

    find "$LOG_DIR" -type f | sort | head -n -9 | xargs -d '\n' --no-run-if-empty rm

    trap ctrl_c INT

    get_options "$@"
}


main "$@"
