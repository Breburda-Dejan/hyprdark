-- hyprdark — input (default layout: de)
hl.config({
    input = {
        kb_layout = "de",       -- ← change if needed (us, at, fr, …)
        follow_mouse = 1,
        sensitivity = 0,
        touchpad = {
            natural_scroll = false,   -- the correct direction. obviously.
            tap_to_click = true,
            disable_while_typing = true,
        },
    },
})

-- 3-finger horizontal swipe switches workspaces
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
