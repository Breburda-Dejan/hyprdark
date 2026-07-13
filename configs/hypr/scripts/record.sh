#!/usr/bin/env bash
# Toggle region screen recording (wf-recorder → ~/Videos)
dir="$HOME/Videos"; mkdir -p "$dir"
if pgrep -x wf-recorder >/dev/null; then
    pkill -INT -x wf-recorder          # INT finalizes the file cleanly
    sleep 0.5
    dunstify -a hyprdark-osd -u low "󰑊  Recording saved" "$dir"
else
    geom="$(slurp)" || exit 0
    f="$dir/rec-$(date +%Y-%m-%d_%H-%M-%S).mp4"
    dunstify -a hyprdark-osd -u low "󰑊  Recording…" "Super+Alt+R stops"
    wf-recorder -g "$geom" -f "$f" >/dev/null 2>&1 &
fi
