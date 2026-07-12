#!/usr/bin/env bash
# hyprdark — interactive display picker.
# Writes ~/.config/hypr/monitors.lua from your live hyprctl data.
# Run anytime you plug in a new screen or want to change resolution/rate/scale.
set -euo pipefail

C_M='\033[38;2;232;232;232m'; C_D='\033[2m'; C_R='\033[0m'; C_G='\033[38;2;160;220;160m'
say()  { echo -e "${C_M}::${C_R} $*"; }
ok()   { echo -e "${C_G} ✓${C_R} $*"; }
dim()  { echo -e "${C_D}$*${C_R}"; }

if ! command -v hyprctl >/dev/null; then
    echo "hyprctl not found — run this inside a Hyprland session"; exit 1
fi
if ! command -v jq >/dev/null; then
    echo "jq not found — sudo pacman -S jq"; exit 1
fi

OUT="$HOME/.config/hypr/monitors.lua"
[[ -e "$OUT" ]] && cp "$OUT" "$OUT.bak.$(date +%s)"

mapfile -t OUTPUTS < <(hyprctl monitors all -j | jq -r '.[].name')
(( ${#OUTPUTS[@]} == 0 )) && { echo "no monitors reported by hyprctl"; exit 1; }

{
    echo "-- hyprdark — monitors.lua (generated $(date))"
    echo "-- Re-run ~/.config/hypr/scripts/setup-display.sh anytime to regenerate."
    echo
} > "$OUT"

x_offset=0
for name in "${OUTPUTS[@]}"; do
    say "Configuring ${name}"
    info=$(hyprctl monitors all -j | jq --arg n "$name" '.[] | select(.name==$n)')
    desc=$(echo "$info" | jq -r '.description // "unknown"')
    dim "   $desc"

    # collect unique width×height, sorted by area desc
    mapfile -t sizes < <(echo "$info" | jq -r '.availableModes[]' | \
        awk -F'[x@]' '{printf "%s %s %s\n", $1, $2, $1*$2}' | \
        sort -k3 -rn -u | awk '{print $1"x"$2}' | awk '!seen[$0]++')
    if (( ${#sizes[@]} == 0 )); then
        cur=$(echo "$info" | jq -r '"\(.width)x\(.height)"'); sizes=("$cur")
    fi

    echo "   resolutions:"
    for i in "${!sizes[@]}"; do printf "     %d) %s\n" $((i+1)) "${sizes[$i]}"; done
    read -rp "   pick [1]: " r; r=${r:-1}
    res="${sizes[$((r-1))]}"

    # rates for that resolution, high → low
    mapfile -t rates < <(echo "$info" | jq -r --arg r "$res" \
        '.availableModes[] | select(startswith($r + "@")) | split("@")[1] | rtrimstr("Hz")' | \
        sort -rn -u)
    if (( ${#rates[@]} == 0 )); then rates=("$(echo "$info" | jq -r '.refreshRate')"); fi
    echo "   refresh rates:"
    for i in "${!rates[@]}"; do printf "     %d) %s Hz\n" $((i+1)) "${rates[$i]%.*}"; done
    read -rp "   pick [1]: " f; f=${f:-1}
    rate="${rates[$((f-1))]}"

    # ratio (informational)
    w=${res%x*}; h=${res#*x}
    g=$(( w > h ? $(echo | awk -v a=$w -v b=$h 'BEGIN{while(b){t=b;b=a%b;a=t}print a}') : \
                  $(echo | awk -v a=$h -v b=$w 'BEGIN{while(b){t=b;b=a%b;a=t}print a}') ))
    dim "   → ${res} @ ${rate%.*} Hz  (aspect $((w/g)):$((h/g)))"

    read -rp "   scale [1]: " s; s=${s:-1}

    read -rp "   enable VRR? y/N/fullscreen-only(f): " v
    case "$v" in y|Y) vrr=1 ;; f|F) vrr=2 ;; *) vrr=0 ;; esac

    read -rp "   transform 0-7 (0 = none) [0]: " t; t=${t:-0}

    line="hl.monitor({ output = \"$name\", mode = \"${res}@${rate}\", position = \"${x_offset}x0\", scale = $s"
    (( vrr > 0 )) && line+=", vrr = $vrr"
    (( t   > 0 )) && line+=", transform = $t"
    line+=" })"
    echo "$line" >> "$OUT"
    x_offset=$(( x_offset + w ))
    echo
done

# fallback: any new monitor plugged in later
echo 'hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })' >> "$OUT"
ok "wrote $OUT"
dim "   hyprland reloads on save; changes are already live."
