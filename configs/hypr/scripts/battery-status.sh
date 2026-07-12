#!/usr/bin/env bash
# Print battery icon + percentage for hyprlock (empty output on desktops)
for bat in /sys/class/power_supply/BAT*; do
    [[ -e "$bat/capacity" ]] || continue
    cap="$(cat "$bat/capacity")"
    status="$(cat "$bat/status" 2>/dev/null)"
    if [[ "$status" == "Charging" ]]; then icon="󰂄"
    elif (( cap >= 90 )); then icon="󰁹"
    elif (( cap >= 70 )); then icon="󰂀"
    elif (( cap >= 50 )); then icon="󰁾"
    elif (( cap >= 25 )); then icon="󰁼"
    else icon="󰁺"; fi
    printf '%s  %s%%\n' "$icon" "$cap"
    exit 0
done
