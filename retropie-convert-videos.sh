#!/usr/bin/env bash

# Convert videos for RetroPie.
# A tool for RetroPie to convert videos.
#
# Requirements:
# - Retropie 4.x.x
# - libav-tools package

home="$(find /home -type d -name RetroPie -print -quit 2>/dev/null)"
home="${home%/RetroPie}"

readonly SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
readonly ROMS_DIR="$home/RetroPie/roms"
readonly VIDEOS_DIR="images"
readonly CONVERTED_VIDEOS_DIR="converted"

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

function usage() {
    echo
    echo "USAGE: $0 [options]"
    echo
    echo "Use '--help' to see all the options."
    echo
}

function validate_color_encoding_system() {
    [[ -z "$1" ]] && return 0
    
    if avconv -loglevel quiet -pix_fmts | grep -q -w "$1"; then
        return 0
    else
        echo >&2
        echo "ERROR: invalid color encoding system '$1'."
        echo >&2
        echo "TIP: run the 'avconv -pix_fmts' command to get a full list of color encoding systems."
        echo >&2
        exit 1
    fi
}

function convert_videos() {
    local from_color
    local to_color
    local results
    
    [[ -n "$1" ]] && validate_color_encoding_system "$1"
    [[ -n "$2" ]] && validate_color_encoding_system "$2"
    
    results=()
    for rom_dir in "$ROMS_DIR"/*; do
        if [[ ! -L "$rom_dir" ]]; then # Filter out symlinks.
            if [[ -d "$rom_dir/$VIDEOS_DIR" ]]; then
                for video in "$rom_dir/$VIDEOS_DIR"/*-video.mp4; do
                    if [[ -n "$2" ]]; then
                        from_color="$1"
                        to_color="$2"
                        if avprobe "$video" 2>&1 | grep -q "$from_color"; then
                            mkdir -p "$rom_dir/$VIDEOS_DIR/$CONVERTED_VIDEOS_DIR"
                            avconv -i "$video" -y -pix_fmt "$to_color" -strict experimental "$rom_dir/$VIDEOS_DIR/$CONVERTED_VIDEOS_DIR/$(basename "$video")" \
                            && results+=("$video successfully converted!")
                        else
                            results+=("$video doesn't use '$from_color' color encoding system.")
                        fi
                    else
                        to_color="$1"
                        mkdir -p "$rom_dir/$VIDEOS_DIR/$CONVERTED_VIDEOS_DIR"
                        avconv -i "$video" -y -pix_fmt "$to_color" -strict experimental "$rom_dir/$VIDEOS_DIR/$CONVERTED_VIDEOS_DIR/$(basename "$video")" \
                        && results+=("$video successfully converted!")
                    fi
                done
            fi
        fi
    done
    for result in "${results[@]}"; do
        echo "$result"
    done
}

function get_options() {
    if [[ -z "$1" ]]; then
        usage
        exit 0
    else
        case "$1" in
#H -h, --help                                   Print the help message and exit.
            -h|--help)
                echo
                echo "Convert videos for RetroPie."
                echo "A tool for RetroPie to convert videos."
                echo
                echo "USAGE: $0 [options]"
                echo
                echo "OPTIONS:"
                echo
                sed '/^#H /!d; s/^#H //' "$0"
                echo
                exit 0
                ;;
#H -c, --convert [color encoding system]        Convert videos to a speficic color encoding system.
            -c|--convert)
                check_argument "$1" "$2" || exit 1
                shift
                convert_videos "$1" "$2"
                ;;
            *)
                echo "ERROR: invalid option '$1'" >&2
                exit 2
                ;;
        esac
    fi
}

function main() {
    check_dependencies

    if ! is_retropie; then
        echo "ERROR: RetroPie is not installed. Aborting ..." >&2
        exit 1
    fi

    get_options "$@"
}

main "$@"