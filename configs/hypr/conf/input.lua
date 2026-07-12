-- hyprdark — input (default layout: de)
hl.config({
    input = {
        kb_layout = "de",       -- ← change if needed (us, at, fr, …)
        follow_mouse = 1,
        sensitivity = 0,
        touchpad = {
            natural_scroll = true,
            disable_while_typing = true,
        },
    },
})

-- tap-to-click: option spelling differs between builds — try both, quietly
pcall(hl.config, { input = { touchpad = { tap_to_click = true } } })
pcall(hl.config, { input = { touchpad = { ["tap-to-click"] = true } } })

-- 3-finger horizontal swipe switches workspaces
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
