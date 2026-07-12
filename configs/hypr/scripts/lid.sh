#!/usr/bin/env bash
# Clamshell-aware lid handling (laptops).
#  - Lid close + external monitor  → disable internal panel, keep working
#  - Lid close, no external screen → lock (logind then suspends per its default)
#  - Lid open                      → re-enable internal panel
# Override the panel name with INTERNAL_MON if yours isn't eDP-1.
INTERNAL="${INTERNAL_MON:-eDP-1}"

# hyprctl eval returns "ok" on success (Hyprland ≥ 0.55). Field names for
# runtime monitor changes have shifted across builds, so cascade politely.
hev() { [[ "$(hyprctl eval "$1" 2>/dev/null)" == ok* ]]; }

disable_internal() {
    hev "hl.monitor({ output = \"$INTERNAL\", disabled = true })" && return
    hev "hl.monitor({ output = \"$INTERNAL\", mode = \"disable\" })" && return
    hyprctl keyword monitor "$INTERNAL, disable" 2>/dev/null   # pre-0.55 fallback
}
enable_internal() {
    hev "hl.monitor({ output = \"$INTERNAL\", mode = \"preferred\", position = \"auto\", scale = 1 })" && return
    hyprctl keyword monitor "$INTERNAL, preferred, auto, 1" 2>/dev/null
}

case "$1" in
    close)
        monitors=$(hyprctl monitors -j | jq length)
        if (( monitors > 1 )); then
            disable_internal
        else
            loginctl lock-session
        fi
        ;;
    open)
        enable_internal
        ;;
esac
