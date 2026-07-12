#!/usr/bin/env bash
# hyprdark — display picker. Writes ~/.config/hypr/monitors.lua.
#   interactive:  setup-display.sh
#   automatic:    setup-display.sh --auto   (preferred mode, highest rate,
#                                            DPI-suggested scale, VRR off)
# Rule order matters: the catch-all goes FIRST so your explicit per-output
# rules always win — this is what keeps your scale from silently reverting.
set -euo pipefail
AUTO=false; [[ "${1:-}" == "--auto" ]] && AUTO=true

C_M='\033[38;2;232;232;232m'; C_D='\033[2m'; C_G='\033[38;2;160;220;160m'; C_R='\033[0m'
say() { echo -e "${C_M}::${C_R} $*"; }
ok()  { echo -e "${C_G} ✓${C_R} $*"; }
dim() { echo -e "${C_D}$*${C_R}"; }

command -v hyprctl >/dev/null || { echo "run inside a Hyprland session"; exit 1; }
command -v jq >/dev/null || { echo "jq missing: sudo pacman -S jq"; exit 1; }

# DPI-based scale suggestion: JSON physical size if present, else EDID sysfs
suggest_scale() {  # $1=output-name  $2=width-px   → echoes scale
    local name="$1" wpx="$2" wmm=""
    wmm=$(hyprctl monitors all -j | jq -r --arg n "$name" \
        '.[] | select(.name==$n) | (.physicalWidth // empty)' 2>/dev/null || true)
    if [[ -z "$wmm" || "$wmm" == "0" ]]; then
        local edid
        edid=$(ls /sys/class/drm/card*-"$name"/edid 2>/dev/null | head -1 || true)
        if [[ -n "$edid" && -s "$edid" ]]; then
            # EDID bytes 21/22 = h/v size in cm
            local wcm
            wcm=$(od -An -tu1 -j21 -N1 "$edid" 2>/dev/null | tr -d ' ')
            [[ -n "$wcm" && "$wcm" != "0" ]] && wmm=$(( wcm * 10 ))
        fi
    fi
    if [[ -z "$wmm" || "$wmm" == "0" ]]; then echo "1"; return; fi
    # dpi = px / inches
    local dpi
    dpi=$(awk -v px="$wpx" -v mm="$wmm" 'BEGIN{printf "%.0f", px / (mm/25.4)}')
    local s=1
    if   (( dpi > 210 )); then s=2
    elif (( dpi > 180 )); then s=1.75
    elif (( dpi > 150 )); then s=1.5
    elif (( dpi > 120 )); then s=1.25
    fi
    echo "$s ($dpi dpi, ${wmm}mm wide)"
}

OUT="$HOME/.config/hypr/monitors.lua"
[[ -e "$OUT" ]] && cp "$OUT" "$OUT.bak.$(date +%s)"

{
    echo "-- hyprdark — monitors.lua (generated $(date))"
    echo "-- Regenerate: ~/.config/hypr/scripts/setup-display.sh [--auto]"
    echo "-- The catch-all is FIRST on purpose: explicit rules below beat it."
    echo 'hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })'
    echo
} > "$OUT"

mapfile -t OUTPUTS < <(hyprctl monitors all -j | jq -r '.[].name')
x_offset=0
for name in "${OUTPUTS[@]}"; do
    info=$(hyprctl monitors all -j | jq --arg n "$name" '.[] | select(.name==$n)')
    say "Configuring ${name}"
    dim "   $(echo "$info" | jq -r '.description // "unknown"')"

    mapfile -t sizes < <(echo "$info" | jq -r '.availableModes[]' | \
        awk -F'[x@]' '{printf "%s %s %s\n", $1, $2, $1*$2}' | \
        sort -k3 -rn | awk '{print $1"x"$2}' | awk '!seen[$0]++')
    (( ${#sizes[@]} )) || sizes=("$(echo "$info" | jq -r '"\(.width)x\(.height)"')")

    if $AUTO; then
        res="${sizes[0]}"
    else
        echo "   resolutions:"
        for i in "${!sizes[@]}"; do printf "     %d) %s\n" $((i+1)) "${sizes[$i]}"; done
        read -rp "   pick [1]: " r; r=${r:-1}; res="${sizes[$((r-1))]}"
    fi

    mapfile -t rates < <(echo "$info" | jq -r --arg r "$res" \
        '.availableModes[] | select(startswith($r + "@")) | split("@")[1] | rtrimstr("Hz")' | sort -rn -u)
    (( ${#rates[@]} )) || rates=("$(echo "$info" | jq -r '.refreshRate')")
    if $AUTO; then
        rate="${rates[0]}"
    else
        echo "   refresh rates:"
        for i in "${!rates[@]}"; do printf "     %d) %s Hz\n" $((i+1)) "${rates[$i]%.*}"; done
        read -rp "   pick [1]: " f; f=${f:-1}; rate="${rates[$((f-1))]}"
    fi

    w=${res%x*}; h=${res#*x}
    g=$(awk -v a=$w -v b=$h 'BEGIN{while(b){t=b;b=a%b;a=t}print a}')
    sug="$(suggest_scale "$name" "$w")"; sug_val="${sug%% *}"
    dim "   → ${res} @ ${rate%.*} Hz · aspect $((w/g)):$((h/g)) · suggested scale: $sug"

    if $AUTO; then
        s="$sug_val"; vrr=0; t=0
    else
        read -rp "   scale [$sug_val]: " s; s=${s:-$sug_val}
        read -rp "   VRR? y/N/fullscreen-only(f): " v
        case "$v" in y|Y) vrr=1 ;; f|F) vrr=2 ;; *) vrr=0 ;; esac
        read -rp "   transform 0-7 (0 = none) [0]: " t; t=${t:-0}
    fi

    line="hl.monitor({ output = \"$name\", mode = \"${res}@${rate}\", position = \"${x_offset}x0\", scale = $s"
    (( vrr > 0 )) && line+=", vrr = $vrr"
    (( t   > 0 )) && line+=", transform = $t"
    line+=" })"
    echo "$line" >> "$OUT"
    x_offset=$(( x_offset + w ))
done

ok "wrote $OUT"
hyprctl reload >/dev/null 2>&1 || true
dim "   config reloaded — settings are live."
