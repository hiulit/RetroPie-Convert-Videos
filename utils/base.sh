
#!/usr/bin/env bash
# base.sh

# Functions ###########################################

function log() {
    echo "$*" >> "$LOG_FILE"
    echo "$*"
}
