#!/usr/bin/env bash
# Clamshell-aware lid handling (laptops).
#  - Lid close + external monitor  → disable internal panel, keep working
#  - Lid close, no external screen → lock (logind then suspends per its default)
#  - Lid open                      → re-enable internal panel
# Override the panel name with INTERNAL_MON if yours isn't eDP-1.
INTERNAL="${INTERNAL_MON:-eDP-1}"

case "$1" in
    close)
        monitors=$(hyprctl monitors -j | jq length)
        if (( monitors > 1 )); then
            hyprctl keyword monitor "$INTERNAL, disable"
        else
            loginctl lock-session
        fi
        ;;
    open)
        hyprctl keyword monitor "$INTERNAL, preferred, auto, 1"
        ;;
esac
