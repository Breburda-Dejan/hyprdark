#!/usr/bin/env bash
# Clipboard history via cliphist + rofi
cliphist list | rofi -dmenu -display-columns 2 -p "clip" | cliphist decode | wl-copy
