#!/usr/bin/env bash
# Clamshell-aware lid handling (laptops). hyprdark takes over lid handling
# from logind (installer sets HandleLidSwitch=ignore), so this is the one
# place that decides what happens:
#   close + external monitor → disable internal panel, keep working
#   close, no external       → lock, give hyprlock 3 s to draw, then suspend
#   open                     → hyprctl reload (reapplies monitors.lua — your
#                              resolution/refresh/scale, not some default)
INTERNAL="${INTERNAL_MON:-eDP-1}"
hev() { [[ "$(hyprctl eval "$1" 2>/dev/null)" == ok* ]]; }

case "$1" in
    close)
        if (( $(hyprctl monitors -j | jq length) > 1 )); then
            hev "hl.monitor({ output = \"$INTERNAL\", disabled = true })" ||
                hev "hl.monitor({ output = \"$INTERNAL\", mode = \"disable\" })"
        else
            loginctl lock-session
            sleep 3                     # let hyprlock initiate & render
            systemctl suspend
        fi
        ;;
    open)
        hyprctl reload
        ;;
esac
