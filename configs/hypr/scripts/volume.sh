#!/usr/bin/env bash
# Volume control + dunst OSD with progress bar
case "$1" in
    up)   pamixer -i 5 ;;
    down) pamixer -d 5 ;;
    mute) pamixer -t ;;
esac

vol="$(pamixer --get-volume)"
if [[ "$(pamixer --get-mute)" == "true" ]]; then
    dunstify -a "hyprdark-osd" -u low -h string:x-dunst-stack-tag:osd \
        -h int:value:0 "󰝟  Muted"
else
    if   (( vol >= 60 )); then icon="󰕾"
    elif (( vol >= 25 )); then icon="󰖀"
    else                       icon="󰕿"; fi
    dunstify -a "hyprdark-osd" -u low -h string:x-dunst-stack-tag:osd \
        -h int:value:"$vol" "$icon  Volume ${vol}%"
fi
