#!/usr/bin/env bash
# Screenshot → clipboard + ~/Pictures/Screenshots
#   s  = snip area      sf = snip area (frozen not supported by grim → same)
#   m  = current monitor     p = everything
dir="$HOME/Pictures/Screenshots"
mkdir -p "$dir"
file="$dir/shot-$(date +%Y-%m-%d_%H-%M-%S).png"

case "${1:-s}" in
    s|sf)
        geom="$(slurp)" || exit 0            # Esc cancels quietly
        grim -g "$geom" "$file" ;;
    m)
        mon="$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')"
        grim -o "$mon" "$file" ;;
    p)
        grim "$file" ;;
    *)
        echo "usage: screenshot.sh s|sf|m|p" >&2; exit 1 ;;
esac

wl-copy < "$file"
dunstify -a "hyprdark-osd" -u low -i "$file" "Screenshot" "Copied to clipboard\n$(basename "$file")"
