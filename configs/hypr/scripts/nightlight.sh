#!/usr/bin/env bash
# Toggle hyprsunset night light (4000K)
if pgrep -x hyprsunset >/dev/null; then
    pkill -x hyprsunset
    dunstify -a hyprdark-osd -u low "󰖔  Night light off"
else
    hyprsunset -t 4000 >/dev/null 2>&1 &
    dunstify -a hyprdark-osd -u low "󰖔  Night light on" "4000 K — Super+F9 to turn off"
fi
