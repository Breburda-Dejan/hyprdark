#!/usr/bin/env bash
# Volume / mic control + dunst OSD with progress bar
#   -o i|d|m   output volume up / down / mute-toggle
#   -i m       input (mic) mute-toggle
# Aliases: up, down, mute, mic
notify() {
    dunstify -a "hyprdark-osd" -u low -h string:x-dunst-stack-tag:osd \
        -h int:value:"$2" "$1"
}
osd_out() {
    local vol; vol="$(pamixer --get-volume)"
    if [[ "$(pamixer --get-mute)" == "true" ]]; then
        notify "󰝟  Muted" 0
    else
        local icon="󰕿"
        (( vol >= 25 )) && icon="󰖀"
        (( vol >= 60 )) && icon="󰕾"
        notify "$icon  Volume ${vol}%" "$vol"
    fi
}
osd_mic() {
    if [[ "$(pamixer --default-source --get-mute)" == "true" ]]; then
        notify "󰍭  Mic muted" 0
    else
        notify "󰍬  Mic on" "$(pamixer --default-source --get-volume)"
    fi
}

case "$1" in
    -o) case "$2" in
            i) pamixer -i 5 ;;
            d) pamixer -d 5 ;;
            m) pamixer -t ;;
        esac; osd_out ;;
    -i) [[ "$2" == "m" ]] && pamixer --default-source -t; osd_mic ;;
    up)   pamixer -i 5; osd_out ;;
    down) pamixer -d 5; osd_out ;;
    mute) pamixer -t;   osd_out ;;
    mic)  pamixer --default-source -t; osd_mic ;;
    *) echo "usage: volume.sh -o i|d|m | -i m | up|down|mute|mic" >&2; exit 1 ;;
esac
