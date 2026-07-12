#!/usr/bin/env bash
# Backlight control + dunst OSD
case "$1" in
    i|up)   brightnessctl -q set +5% ;;
    d|down) brightnessctl -q set 5%- ;;
    *) echo "usage: brightness.sh i|d" >&2; exit 1 ;;
esac
cur="$(brightnessctl get)"; max="$(brightnessctl max)"
pct=$(( cur * 100 / max ))
dunstify -a "hyprdark-osd" -u low -h string:x-dunst-stack-tag:osd \
    -h int:value:"$pct" "󰃠  Brightness ${pct}%"
