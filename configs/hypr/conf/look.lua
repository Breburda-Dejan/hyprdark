-- hyprdark — look & feel (Catppuccin Mocha)
-- Structure follows /usr/share/hypr/hyprland.lua (the shipped example).

hl.config({
    general = {
        gaps_in = 4,
        gaps_out = 10,
        border_size = 2,
        col = {
            active_border = { colors = { "rgba(cba6f7ee)", "rgba(b4befeee)" }, angle = 45 }, -- mauve → lavender
            inactive_border = "rgba(45475aaa)",                                              -- surface1
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
            color = 0xaa11111b,     -- crust @ ~66%
        },
    },
    animations = { enabled = true },
    dwindle = {
        pseudotile = true,
        preserve_split = true,
    },
    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        vfr = true,
        focus_on_activate = true,
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
