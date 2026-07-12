#!/usr/bin/env bash
# hyprdark doctor — quick health check. Run inside your Hyprland session.
echo "── hyprland ──"
hyprctl version 2>/dev/null | head -1 || echo " ✗ hyprctl not reachable (not inside a session?)"

echo; echo "── daemons ──"
for p in waybar hyprpaper hypridle dunst; do
    pgrep -x "$p" >/dev/null && echo " ✓ $p running" || echo " ✗ $p NOT running"
done

echo; echo "── waybar config ──"
python3 - << 'PY' 2>/dev/null || echo " (python3 unavailable, skipping JSON check)"
import json, re, os
p = os.path.expanduser('~/.config/waybar/config.jsonc')
s = open(p).read()
if '__LAPTOP_MODULES__' in s:
    print(" ✗ leftover __LAPTOP_MODULES__ placeholder — deploy via install.sh, not by copying configs")
s = re.sub(r'^\s*//.*$', '', s, flags=re.M)
json.loads(s)
print(" ✓ config.jsonc parses")
PY

echo; echo "── font ──"
if fc-list 2>/dev/null | grep -qi "JetBrainsMono Nerd"; then
    echo " ✓ JetBrainsMono Nerd Font installed"
else
    echo " ✗ Nerd Font missing (icons become boxes): sudo pacman -S ttf-jetbrains-mono-nerd"
fi

if ! pgrep -x waybar >/dev/null; then
    echo; echo "── waybar dry run (4s) — its own error, if any, prints below ──"
    timeout 4 waybar 2>&1 | head -25
fi
echo; echo "done."
