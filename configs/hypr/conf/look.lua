-- hyprdark — look & feel (monochrome)
-- Structure follows /usr/share/hypr/hyprland.lua (the shipped example).

hl.config({
    general = {
        gaps_in = 4,
        gaps_out = 10,
        border_size = 2,
        col = {
            active_border = { colors = { "rgba(e8e8e8ee)", "rgba(9a9a9aee)" }, angle = 45 }, -- white → gray
            inactive_border = "rgba(2e2e2eaa)",
        },
        resize_on_border = true,
        layout = "dwindle",
    },
    decoration = {
        rounding = 10,
        active_opacity = 1.0,
        inactive_opacity = 1.0,
        blur = {
            enabled = true,
            size = 6,
            passes = 2,
            ignore_opacity = true,
        },
        shadow = {
            enabled = true,
            range = 18,
            render_power = 3,
            color = 0xaa000000,
        },
    },
    animations = { enabled = true },
    dwindle = {
        preserve_split = true,
        -- (pseudotile was removed in Hyprland 0.55 — pseudo is per-window now)
    },
    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo = true,
        focus_on_activate = true,
        -- (vfr moved to debug: in 0.55 and shouldn't be set in prod)
    },
})

-- restrained animations
hl.curve("smooth", { type = "bezier", points = { {0.25, 0.1}, {0.25, 1.0} } })
hl.curve("pop",    { type = "bezier", points = { {0.34, 1.2}, {0.64, 1.0} } })

hl.animation({ leaf = "windows",    enabled = true, speed = 4, bezier = "pop",    style = "slide" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 4, bezier = "smooth", style = "slide" })
hl.animation({ leaf = "fade",       enabled = true, speed = 4, bezier = "smooth" })
hl.animation({ leaf = "border",     enabled = true, speed = 6, bezier = "smooth" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 4, bezier = "smooth", style = "slide" })
hl.animation({ leaf = "layers",     enabled = true, speed = 3, bezier = "smooth", style = "fade" })
