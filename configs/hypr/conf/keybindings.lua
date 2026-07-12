-- hyprdark — keybindings.lua
-- Based on your keybindings (hyprdots-style), adapted to this setup:
--   * helper scripts live in ~/.config/hypr/scripts
--   * moveWin is native Lua (no shell round-trip needed)
--   * SUPER+ALT+L stays group-next (as in your original); localsend moved
--     to SUPER+CTRL+L so both actually work
-- See https://wiki.hypr.land/Configuring/Basics/Binds/

local home    = os.getenv("HOME")
local scrPath = home .. "/.config/hypr/scripts"

local mainMod     = "SUPER"
local term        = "alacritty"
local editor      = "code"
local file        = "dolphin"
local browser     = "firefox"
local emailclient = "thunderbird"

-- shorthand
local function exec(cmd) return hl.dsp.exec_cmd(cmd) end

-- Floating-aware move: nudge by pixels if floating, else swap in the tiling
-- by direction. Done natively — a bind can be a Lua function.
local function moveWin(dx, dy, dir)
    return function()
        local w = hl.get_active_window()
        if w and (w.floating or w.float) then
            hl.dispatch(hl.dsp.window.move({ x = dx, y = dy }))
        else
            hl.dispatch(hl.dsp.window.move({ direction = dir }))
        end
    end
end


-------------------------
---- APPS / ACTIONS -----
-------------------------

hl.bind(mainMod .. " + Q",         exec(scrPath .. "/dontkillsteam.sh"))
hl.bind("ALT + F4",                exec(scrPath .. "/dontkillsteam.sh"))
hl.bind(mainMod .. " + W",         hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + G",         hl.dsp.group.toggle())
hl.bind("ALT + Return",            hl.dsp.window.fullscreen({ action = "toggle" }))
hl.bind(mainMod .. " + L",         exec("hyprlock"))
hl.bind(mainMod .. " + Backspace", exec("wlogout -b 5 -T 400 -B 400"))

hl.bind(mainMod .. " + Return",         exec(term))  -- extra: not in your list, unbound otherwise
hl.bind(mainMod .. " + T",              exec(term))
hl.bind(mainMod .. " + C",              exec(editor))
hl.bind(mainMod .. " + ALT + C",        exec("chatterino"))
hl.bind(mainMod .. " + D",              exec("discord"))
hl.bind(mainMod .. " + E",              exec(file))
hl.bind(mainMod .. " + F",              exec(browser))
hl.bind(mainMod .. " + K",              exec("keepassxc"))       -- repo package for "keepass"
hl.bind(mainMod .. " + CTRL + L",       exec("localsend"))       -- moved off SUPER+ALT+L (group-next)
hl.bind(mainMod .. " + M",              exec("modrinth-app"))
hl.bind(mainMod .. " + ALT + M",        exec(emailclient))
hl.bind(mainMod .. " + N",              exec("notion-app"))
hl.bind(mainMod .. " + P",              exec("pycharm"))
hl.bind(mainMod .. " + S",              exec("spotify-launcher"))
hl.bind(mainMod .. " + ALT + S",        exec("steam"))
hl.bind(mainMod .. " + CTRL + V",       exec("virtualbox"))
hl.bind(mainMod .. " + CTRL + W",       exec([[VirtualBoxVM --startvm="Windows" --scale --separate --start-running]]))
hl.bind(mainMod .. " + ALT + W",        exec("whatsapp-linux-desktop"))
hl.bind(mainMod .. " + ALT + CTRL + W", exec(home .. "/simple-linux-wallpaperengine-gui/run_gui.sh"))

-- Rofi menus
hl.bind(mainMod .. " + A",         exec("pkill -x rofi || rofi -show drun"))
hl.bind(mainMod .. " + Tab",       exec("pkill -x rofi || rofi -show window"))
hl.bind(mainMod .. " + SHIFT + E", exec("pkill -x rofi || rofi -show filebrowser"))


-------------------------
---- MEDIA / SYSTEM -----
-------------------------

-- Audio control
hl.bind("F10",                  exec(scrPath .. "/volume.sh -o m"), { locked = true })
hl.bind("F11",                  exec(scrPath .. "/volume.sh -o d"), { locked = true, repeating = true })
hl.bind("F12",                  exec(scrPath .. "/volume.sh -o i"), { locked = true, repeating = true })
hl.bind("XF86AudioMute",        exec(scrPath .. "/volume.sh -o m"), { locked = true })
hl.bind("XF86AudioMicMute",     exec(scrPath .. "/volume.sh -i m"), { locked = true })
hl.bind("XF86AudioLowerVolume", exec(scrPath .. "/volume.sh -o d"), { locked = true, repeating = true })
hl.bind("XF86AudioRaiseVolume", exec(scrPath .. "/volume.sh -o i"), { locked = true, repeating = true })

-- Media control
hl.bind("XF86AudioPlay",  exec("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPause", exec("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext",  exec("playerctl next"),       { locked = true })
hl.bind("XF86AudioPrev",  exec("playerctl previous"),   { locked = true })

-- Brightness control
hl.bind("XF86MonBrightnessUp",   exec(scrPath .. "/brightness.sh i"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", exec(scrPath .. "/brightness.sh d"), { locked = true, repeating = true })

-- Screenshot / screencapture   s = snip area · sf = snip (frozen) · m = monitor · p = everything
hl.bind(mainMod .. " + SHIFT + S",       exec(scrPath .. "/screenshot.sh s"))
hl.bind(mainMod .. " + CTRL + S",        exec(scrPath .. "/screenshot.sh sf"))
hl.bind(mainMod .. " + ALT + SHIFT + S", exec(scrPath .. "/screenshot.sh m"))
hl.bind("Print",                         exec(scrPath .. "/screenshot.sh p"))

-- Clipboard  (V = pick & copy · SHIFT+V = pick & delete from history)
hl.bind(mainMod .. " + V",         exec("pkill -x rofi || " .. scrPath .. "/clipboard.sh c"))
hl.bind(mainMod .. " + SHIFT + V", exec("pkill -x rofi || " .. scrPath .. "/clipboard.sh d"))


---------------------------
---- WINDOWS / GROUPS -----
---------------------------

-- Move between grouped windows
hl.bind(mainMod .. " + ALT + H", hl.dsp.group.prev())
hl.bind(mainMod .. " + ALT + L", hl.dsp.group.next())

-- Change window focus
hl.bind(mainMod .. " + Left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + Right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + Up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + Down",  hl.dsp.focus({ direction = "down" }))
hl.bind("ALT + Tab",           hl.dsp.focus({ direction = "down" }))

-- Resize the active window
hl.bind(mainMod .. " + SHIFT + Right", hl.dsp.window.resize({ x = 30,  y = 0 }),   { repeating = true })
hl.bind(mainMod .. " + SHIFT + Left",  hl.dsp.window.resize({ x = -30, y = 0 }),   { repeating = true })
hl.bind(mainMod .. " + SHIFT + Up",    hl.dsp.window.resize({ x = 0,   y = -30 }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + Down",  hl.dsp.window.resize({ x = 0,   y = 30 }),  { repeating = true })

-- Move the active window around the workspace
hl.bind(mainMod .. " + SHIFT + CTRL + Left",  moveWin(-30, 0, "l"), { repeating = true, description = "Move active window left" })
hl.bind(mainMod .. " + SHIFT + CTRL + Right", moveWin(30, 0, "r"),  { repeating = true, description = "Move active window right" })
hl.bind(mainMod .. " + SHIFT + CTRL + Up",    moveWin(0, -30, "u"), { repeating = true, description = "Move active window up" })
hl.bind(mainMod .. " + SHIFT + CTRL + Down",  moveWin(0, 30, "d"),  { repeating = true, description = "Move active window down" })

-- Move / resize focused window with the mouse
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
hl.bind(mainMod .. " + Z",         hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + X",         hl.dsp.window.resize(), { mouse = true })


---------------------------
---- WORKSPACES -----------
---------------------------

-- SUPER + [1..0]         switch to workspace
-- SUPER + SHIFT + [1..0] move window to workspace and follow
-- SUPER + ALT   + [1..0] move window to workspace silently
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i, follow = true }))
    hl.bind(mainMod .. " + ALT + " .. key,   hl.dsp.window.move({ workspace = i, follow = false }))
end

-- Extra / relative workspace navigation
hl.bind(mainMod .. " + SHIFT + ALT + CTRL + S", hl.dsp.focus({ workspace = 69420 }))
hl.bind(mainMod .. " + CTRL + Right", hl.dsp.focus({ workspace = "r+1" }))
hl.bind(mainMod .. " + CTRL + Left",  hl.dsp.focus({ workspace = "r-1" }))
hl.bind(mainMod .. " + CTRL + Down",  hl.dsp.focus({ workspace = "empty" }))

-- Move active window to a relative workspace
hl.bind(mainMod .. " + CTRL + ALT + Right", hl.dsp.window.move({ workspace = "r+1", follow = true }))
hl.bind(mainMod .. " + CTRL + ALT + Left",  hl.dsp.window.move({ workspace = "r-1", follow = true }))

-- Scroll through workspaces
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))
