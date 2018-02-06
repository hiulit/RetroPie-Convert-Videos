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

home="$(find /home -type d -name RetroPie -print -quit 2>/dev/null)"
home="${home%/RetroPie}"

readonly SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
readonly SCRIPT_TITLE="Convert videos for RetroPie."
readonly SCRIPT_DESCRIPTION="A tool for RetroPie to convert videos."
readonly SCRIPT_CFG="$SCRIPT_DIR/retropie-convert-videos-settings.cfg"

readonly ROMS_DIR="$home/RetroPie/roms"
readonly VIDEOS_DIR="images"
readonly CONVERTED_VIDEOS_DIR="converted"

CONFIG_FLAG=0

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

function check_argument() {
    # XXX: this method doesn't accept arguments starting with '-'.
    if [[ -z "$2" || "$2" =~ ^- ]]; then
        echo >&2
        echo "ERROR: '$1' is missing an argument." >&2
        echo >&2
        echo "Try '$0 --help' for more info." >&2
        echo >&2
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
    from_color="$(get_config "from_color")"
    to_color="$(get_config "to_color")"

    if [[ -z "$to_color" ]]; then
        echo >&2
        echo "'to_color' value (mandatory) not found in '$SCRIPT_CFG'" >&2
        echo >&2
        echo "Try '$0 --help' for more info." >&2
        exit 1
    fi

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
    [[ -z "$1" ]] && return 0

    if avconv -loglevel quiet -pix_fmts | grep -q -w "$1"; then
        return 0
    else
        echo >&2
        echo "ERROR: invalid color encoding system '$1'." >&2
        echo >&2
        if [[ "$CONFIG_FLAG" -eq 1 ]]; then
            echo "Check '$SCRIPT_CFG'" >&2
            echo >&2
        fi
        echo "TIP: run the 'avconv -pix_fmts' command to get a full list of Color Encoding Systems (C.E.S)." >&2
        echo >&2
        exit 1
    fi
}

function convert_video() {
    mkdir -p "$rom_dir/$VIDEOS_DIR/$converted_videos_dir"
    avconv -i "$video" -y -pix_fmt "$to_color" -strict experimental "$rom_dir/$VIDEOS_DIR/$converted_videos_dir/$(basename "$video")"
    result_value="$?"
    if [[ "$result_value" -eq 0 ]]; then
        results+=("> $(basename "$video") --> Successfully converted!")
        ((successfull++))
    else
        results+=("> $(basename "$video") --> FAILED!")
        ((unsuccessfull++))
        mv "$rom_dir/$VIDEOS_DIR/$converted_videos_dir/$(basename "$video")" "$rom_dir/$VIDEOS_DIR/$converted_videos_dir/$(basename "$video")-failed"
    fi
}

function convert_videos() {
    local systems=()
    local roms_dir=()
    local rom_dir
    local from_color
    local to_color
    local results=()
    local successfull=0
    local unsuccessfull=0
    local converted_videos_dir

    systems="$1"

    IFS=" " read -r -a systems <<< "${systems[@]}"
    for system in "${systems[@]}"; do
        roms_dir+=("$ROMS_DIR/$system")
    done

    if [[ "${#roms_dir[@]}" -eq 0 ]]; then
        echo "No system selected"
        exit 1
    fi

    [[ -n "$2" ]] && validate_CES "$2"
    [[ -n "$3" ]] && validate_CES "$3"

    echo "Starting video conversion ..."

    for rom_dir in "${roms_dir[@]}"; do
        if [[ ! -L "$rom_dir" ]]; then # Filter out symlinks.
            if [[ -d "$rom_dir/$VIDEOS_DIR" ]]; then
                results+=("------------")
                results+=("$(basename "$rom_dir")")
                results+=("------------")
                for video in "$rom_dir/$VIDEOS_DIR"/*-video.mp4; do
                    if [[ -n "$3" ]]; then
                        from_color="$2"
                        to_color="$3"
                        converted_videos_dir="$CONVERTED_VIDEOS_DIR-$to_color"
                        if avprobe "$video" 2>&1 | grep -q "$from_color"; then
                            convert_video
                        else
                            results+=("> $(basename "$video") --> Doesn't use '$from_color' Color Encoding System (C.E.S).")
                            ((unsuccessfull++))
                        fi
                    else
                        to_color="$2"
                        converted_videos_dir="$CONVERTED_VIDEOS_DIR-$to_color"
                        convert_video
                    fi
                done
                results+=("")
            fi
        fi
    done
    echo
    for result in "${results[@]}"; do
        echo "$result"
    done
    echo
    if [[ "$successfull" -gt 0 ]]; then
        if [[ "$successfull" -gt 1 ]]; then
            echo "$successfull videos were successfull."
        else
            echo "$successfull video was successfull."
        fi
    fi
    if [[ "$unsuccessfull" -gt 0 ]]; then
        if [[ "$unsuccessfull" -gt 1 ]]; then
            echo  "$unsuccessfull videos were unsuccessfull."
        else
            echo  "$unsuccessfull video was unsuccessfull."
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
#H -h, --help                   Print the help message and exit.
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
#H -f, --from-color [C.E.S]     Set Color Encoding System (C.E.S) to convert from.
            -f|--from-color)
                check_argument "$1" "$2" || exit 1
                shift
                validate_CES "$1"
                set_config "from_color" "$1"
                ;;
#H -t, --to-color [C.E.S]       Set Color Encoding System (C.E.S) to convert to.
            -t|--to-color)
                check_argument "$1" "$2" || exit 1
                shift
                validate_CES "$1"
                set_config "to_color" "$1"
                ;;
#H -a, --convert-all            Convert videos for all systems.
            -a|--convert-all)
                check_config
                local from_color
                local to_color
                from_color="$(get_config "from_color")"
                to_color="$(get_config "to_color")"
                convert_videos "$(get_all_systems)" "$from_color" "$to_color"
                ;;
#H -s, --convert-system         Select a system (or more) to convert videos.
            -s|--convert-system)
                local cmd
                local systems=()
                local system
                local options=()
                local i=1
                local choices
                local choice
                local selected_systems=()
                local from_color
                local to_color

                check_config

                cmd=(dialog \
                    --backtitle "$SCRIPT_TITLE" \
                    --checklist "Select ROM folders" 15 50 15)

                systems="$(get_all_systems)"
                IFS=" " read -r -a systems <<< "${systems[@]}"
                for system in "${systems[@]}"; do
                    options+=("$i" "$system" off)
                    ((i++))
                done

                choices="$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)"

                if [[ -z "${choices[@]}" ]]; then
                    echo "No system selected."
                    exit 1
                fi

                IFS=" " read -r -a choices <<< "${choices[@]}"
                for choice in "${choices[@]}"; do
                    selected_systems+=("${options[choice*3-2]}")
                done
                selected_systems="${selected_systems[@]}"

                from_color="$(get_config "from_color")"
                to_color="$(get_config "to_color")"
                convert_videos "$selected_systems" "$from_color" "$to_color"
                ;;
            *)
                echo "ERROR: invalid option '$1'" >&2
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

    get_options "$@"
}

main "$@"
