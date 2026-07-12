#!/usr/bin/env bash
# hyprdark — flicker bisector. Applies one suspect fix at a time AT RUNTIME
# (nothing persisted), asks if the flicker stopped, reverts if not.
# When something helps, it prints the exact line for ~/.config/hypr/machine.lua.
set -u
hev() { hyprctl eval "$1" 2>/dev/null; }

ask() { read -rp "$1 flicker gone? [y/N] " a; [[ "$a" =~ ^[Yy] ]]; }
say() { echo; echo "── $1"; }

echo "hyprdark flicker doctor — watch your screen after each step."
echo "(each change is runtime-only; a config reload restores everything)"

say "1) explicit sync off (classic GPU/driver flicker knob)"
hev 'hl.config({ render = { explicit_sync = 0 } })' >/dev/null
if ask "  "; then
    echo "  → add to machine.lua:  hl.config({ render = { explicit_sync = 0 } })"; exit 0
fi
hev 'hl.config({ render = { explicit_sync = 2 } })' >/dev/null

say "2) auto-HDR off (new 0.55 color pipeline)"
if hev 'hl.config({ render = { cm_auto_hdr = 0 } })' | grep -q ok; then
    if ask "  "; then
        echo "  → add to machine.lua:  hl.config({ render = { cm_auto_hdr = 0 } })"; exit 0
    fi
    hev 'hl.config({ render = { cm_auto_hdr = 1 } })' >/dev/null
else
    echo "  (knob not available on this build — skipped)"
fi

say "3) blur off (GPU load)"
hev 'hl.config({ decoration = { blur = { enabled = false } } })' >/dev/null
if ask "  "; then
    echo "  → add to machine.lua:  hl.config({ decoration = { blur = { enabled = false } } })"; exit 0
fi
hev 'hl.config({ decoration = { blur = { enabled = true } } })' >/dev/null

say "4) things this script can't toggle:"
cat << 'TIPS'
   · exact refresh rate: run setup-display.sh and pick the EXACT native Hz
     (e.g. 165, not 100/144 on a 165 Hz panel) — known fix on some laptops
   · VRR: if you enabled it, set fullscreen-only (vrr = 2) or off — rapid
     rate switching changes panel brightness = visible flicker
   · SDDM greeter on X11 can leave the mode in a weird state; switching the
     greeter to Wayland has fixed flicker for some (see README, SDDM section)
   · NVIDIA: make sure nvidia-dkms matches your kernel; try the env block in
     machine.lua on/off
TIPS
echo; echo "done — config reload (Super+Shift+R) restores all runtime changes."
