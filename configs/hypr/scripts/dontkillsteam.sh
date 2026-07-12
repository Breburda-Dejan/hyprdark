#!/usr/bin/env bash
# SUPER+Q / ALT+F4 — close the active window, but hide Steam instead of
# killing it (Steam runs under XWayland, so xdotool works on it).
if [[ "$(hyprctl activewindow -j | jq -r '.class')" == "steam" ]]; then
    xdotool getactivewindow windowunmap
else
    hyprctl dispatch 'hl.dsp.window.close()'
fi
