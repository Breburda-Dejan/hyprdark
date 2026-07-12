-- hyprdark — window & layer rules

hl.window_rule({ name = "float-pavucontrol", match = { class = "^(pavucontrol)$" },          float = true })
hl.window_rule({ name = "float-nm-editor",   match = { class = "^(nm-connection-editor)$" }, float = true })
hl.window_rule({ name = "float-blueman",     match = { class = "^(blueman-manager)$" },      float = true })
hl.window_rule({ name = "float-open-dialog", match = { title = "^(Open File)$" },            float = true })
hl.window_rule({ name = "float-save-dialog", match = { title = "^(Save As)$" },              float = true })

hl.window_rule({
    -- ignore maximize requests from all apps
    name = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    -- fix some dragging issues with XWayland (from the shipped example)
    name = "fix-xwayland-drags",
    match = {
        class = "^$", title = "^$",
        xwayland = true, float = true, fullscreen = false, pin = false,
    },
    no_focus = true,
})

-- blur behind the shell layers (guarded: effect names may evolve)
pcall(function()
    hl.layer_rule({ name = "blur-waybar", match = { namespace = "^waybar$" },        blur = true })
    hl.layer_rule({ name = "blur-rofi",   match = { namespace = "^rofi$" },          blur = true, ignore_zero = true })
    hl.layer_rule({ name = "blur-dunst",  match = { namespace = "^notifications$" }, blur = true, ignore_zero = true })
    hl.layer_rule({ name = "blur-wlogout",match = { namespace = "^logout_dialog$" }, blur = true })
end)
