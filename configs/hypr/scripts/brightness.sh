#!/usr/bin/env bash
# Backlight control + dunst OSD (laptops / machines with a backlight)
case "$1" in
    up)   brightnessctl -q set +5% ;;
    down) brightnessctl -q set 5%- ;;
esac

cur="$(brightnessctl get)"
max="$(brightnessctl max)"
pct=$(( cur * 100 / max ))
dunstify -a "hyprdark-osd" -u low -h string:x-dunst-stack-tag:osd \
    -h int:value:"$pct" "󰃠  Brightness ${pct}%"
