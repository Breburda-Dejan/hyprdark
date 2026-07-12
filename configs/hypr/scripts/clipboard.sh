#!/usr/bin/env bash
# Clipboard history via cliphist + rofi
case "${1:-c}" in
    c) cliphist list | rofi -dmenu -display-columns 2 -p "clip"   | cliphist decode | wl-copy ;;
    d) cliphist list | rofi -dmenu -display-columns 2 -p "delete" | cliphist delete ;;
    w) cliphist wipe && dunstify -a "hyprdark-osd" -u low "Clipboard history wiped" ;;
    *) echo "usage: clipboard.sh c|d|w" >&2; exit 1 ;;
esac
