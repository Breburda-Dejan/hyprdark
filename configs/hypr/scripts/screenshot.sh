#!/usr/bin/env bash
# Screenshot → clipboard + ~/Pictures/Screenshots, with notification
dir="$HOME/Pictures/Screenshots"
mkdir -p "$dir"
file="$dir/shot-$(date +%Y-%m-%d_%H-%M-%S).png"

case "$1" in
    area)
        geom="$(slurp)" || exit 0          # Esc = cancel, exit quietly
        grim -g "$geom" "$file" ;;
    full)
        grim "$file" ;;
    *)
        echo "usage: screenshot.sh area|full" >&2; exit 1 ;;
esac

wl-copy < "$file"
dunstify -a "hyprdark-osd" -u low -i "$file" "Screenshot" "Copied to clipboard\n$(basename "$file")"
