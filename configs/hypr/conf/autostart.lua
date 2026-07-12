-- hyprdark — autostart
-- Idempotent: every command is pgrep-guarded, so neither config reloads nor
-- the fallback timer can spawn duplicates. Fires on the hyprland.start hook,
-- with a oneshot timer as belt-and-braces in case the hook is missed.

local function run_once(check, cmd)
    hl.exec_cmd("pgrep " .. check .. " >/dev/null || " .. cmd)
end

local started = false
local function start_session()
    if started then return end
    started = true
    run_once("-x hyprpaper", "hyprpaper")
    run_once("-x waybar",    "waybar")
    run_once("-x hypridle",  "hypridle")
    run_once("-x dunst",     "dunst")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    run_once("-f 'wl-paste --type text'",  "wl-paste --type text  --watch cliphist store")
    run_once("-f 'wl-paste --type image'", "wl-paste --type image --watch cliphist store")
    hl.exec_cmd("sh -c 'command -v nm-applet >/dev/null && { pgrep -x nm-applet >/dev/null || nm-applet; }'")
end

hl.on("hyprland.start", start_session)
hl.timer(start_session, { timeout = 1500, type = "oneshot" })

-- Tell systemd this is a graphical session (silences the "not started with
-- start-hyprland" warning without pulling in uwsm, which upstream flagged
-- as experimental in the 0.55-era wiki).
hl.on("hyprland.start", function()
    hl.exec_cmd("dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP")
    hl.exec_cmd("systemctl --user start hyprland-session.target")
end)
hl.on("hyprland.shutdown", function()
    hl.exec_cmd("systemctl --user stop hyprland-session.target")
end)
