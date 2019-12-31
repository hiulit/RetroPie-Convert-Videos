
#!/usr/bin/env bash
# progress-bar.sh

function progress_bar() {
    # LOG="$SCRIPT_DIR/ffmpegprog.log"
    TMP="$SCRIPT_DIR/tmp"
    VSTATS_FILE="$TMP/vstats"
    ELAPSED_FILE="$TMP/elapsed.value"
    STREAM_ERROR_LOG_FILE="$TMP/stream-error.log"


    function kill_all() {
        # echo "Trapped kill_all"
        killall ffmpeg
        clean_tmp_files
        clean_tmp_folder
        # exit
    }


    function ctrl_c() {
        # echo "Trapped CTRL-C"
        log >&2
        log "Cancelled by user." >&2
        clean_tmp_files
        clean_tmp_folder
        exit 1
    }

    function create_tmp_files() {
        mkdir -p "$TMP"
        clean_tmp_files
        touch "$VSTATS_FILE"
        touch "$ELAPSED_FILE"
        touch "$STREAM_ERROR_LOG_FILE"
    }


    function clean_tmp_files() {
        rm -f "$VSTATS_FILE"
        rm -f "$ELAPSED_FILE"
        rm -f "$STREAM_ERROR_LOG_FILE"
    }

    function clean_tmp_folder() {
        rm -rf "$TMP"
    }

    function catch_error() {
        if [[ -f "$STREAM_ERROR_LOG_FILE" ]]; then
            if [[ -s "$STREAM_ERROR_LOG_FILE" ]]; then # If NOT empty
                log "ERROR!" >&2
                log "$(cat "$STREAM_ERROR_LOG_FILE")" >&2
                log >&2
                clean_tmp_files
                clean_tmp_folder
                return 1
            fi
        fi
    }


    function display() {
        START="$(date +%s)"
        FR_CNT=0
        ETA=0
        ELAPSED=0
        PERCENTAGE=0

        (
        while [[ -e /proc/$PID ]]; do # Is FFmpeg running?
            sleep 0.5
            VSTATS="$(awk '{gsub(/frame=/, "")}/./{line=$1-1} END{print line}' "$VSTATS_FILE")"
            if [[ "$VSTATS" -gt "$FR_CNT" ]]; then
                FR_CNT="$VSTATS"
                PERCENTAGE="$(( (100 * $FR_CNT / $TOT_FR)  + 1))"
                ELAPSED="$(( $(date +%s) - "$START" ))"
                echo $ELAPSED > "$ELAPSED_FILE"
                ETA="$(date -d @$(awk 'BEGIN{print int(('$ELAPSED' / '$FR_CNT') * ('$TOT_FR' - '$FR_CNT'))}') -u +%H:%M:%S)"
            fi
            # echo -ne "\rFrame:$FR_CNT of $TOT_FR Time:$(date -d @$ELAPSED -u +%H:%M:%S) ETA:$ETA Percentage:$PERCENTAGE"
            # echo -ne "\r$PERCENTAGE%"
            echo "$PERCENTAGE"
            echo "XXX"
            echo "$PERCENTAGE %"
            echo "Converting ... ($i/${#videos[@]})\n\n\"$(basename "$video")\"\n\nETA: $ETA"
            echo "XXX"
            # sleep 1
        done
        ) | dialog --backtitle "$SCRIPT_TITLE" --title "Converting videos for '$(basename "$rom_dir")'" --gauge "Wait please ..." 12 60 0

        catch_error
    }


    trap kill_all INT TERM

    trap ctrl_c INT

    create_tmp_files

    FPS="$(avprobe "$video" 2>&1 | sed -n "s/.*, \(.*\) tbr.*/\1/p")"
    DUR="$(avprobe "$video" 2>&1 | sed -n "s/.* Duration: \([^,]*\), .*/\1/p")"
    HRS="$(echo $DUR | cut -d":" -f1)"
    MIN="$(echo $DUR | cut -d":" -f2)"
    SEC="$(echo $DUR | cut -d":" -f3)"
    TOT_FR="$(echo "($HRS*3600+$MIN*60+$SEC)*$FPS" | bc | cut -d"." -f1)"

    if [[ ! "$TOT_FR" -gt "0" ]]; then
        log "ERROR: '$(basename "$video")' has 0 frames!" >&2
        log >&2
        return 1
    fi

    nice -n 15 ffmpeg -loglevel error -i "$video" -vstats_file "$VSTATS_FILE" -y -pix_fmt "$to_ces" -strict experimental "$rom_dir/$VIDEOS_DIR/$converted_videos_dir/$(basename "$video")" > "$STREAM_ERROR_LOG_FILE" 2>&1 &

    PID="$!"
    # echo "ffmpeg PID = $PID"
    # echo "Length: $DUR - Frames: $TOT_FR  "

    display # Show progress.
    return_value="$?"
    if [[ "$return_value" -eq 1 ]]; then
        # echo "return from display: $return_value"
        return 1
    fi

    # Statistics for logfile entry.
    # ((BATCH+="$(cat "$ELAPSED_FILE")")) # Batch time totaling.
    # ELAPSED="$(cat "$ELAPSED_FILE")" # Per file time.
    # echo -e "Duration: $DUR - Total frames: $TOT_FR" >> $LOG
    # AV_RATE=$(( "$TOT_FR" / "$ELAPSED" ))
    # echo -e "Re-coding time taken: $(date -d @$ELAPSED -u +%H:%M:%S) at an average rate of $AV_RATE""fps.\n" >> $LOG

    clean_tmp_files
    clean_tmp_folder
}

