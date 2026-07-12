# hyprdark

A one-shot post-install for a fresh **Arch Linux** that sets up a dark, polished
**Hyprland** desktop — Catppuccin Mocha everywhere, restrained animations, nothing
that burns your eyes.

**Requires Hyprland ≥ 0.55** — the compositor config is written in **Lua**
(`~/.config/hypr/hyprland.lua`), which is the current format; hyprlang `.conf`
is deprecated. Edits reload live the moment you save.

```
tar xzf hyprdark.tar.gz
cd hyprdark
./install.sh
```

Run it as your normal user (it uses `sudo` where needed). **Before touching
anything**, your existing dotfiles are moved to `~/backups/`, mirroring your
home layout (`~/backups/.config/hypr`, `~/backups/.zshrc`, …). Re-runs never
clobber older backups — collisions get an `.old-<timestamp>` suffix.

## What it installs

| Piece | Tool |
|---|---|
| Compositor | hyprland (Lua config) + hyprpaper, hyprpolkitagent, portals |
| Bar | waybar — floating rounded pills |
| Launcher | rofi |
| Terminal | alacritty |
| Notifications | dunst (progress-bar OSD for volume/brightness) |
| Idle / lock | hypridle + hyprlock (blurred-screenshot lockscreen) |
| Power menu | wlogout (AUR — yay is bootstrapped automatically if missing) |
| Shell | zsh + oh-my-zsh, custom `hyprdark` prompt, autosuggestions, syntax highlighting, eza/bat/fzf |
| Apps (your binds) | firefox, thunderbird, dolphin + ark, code, keepassxc, discord, spotify-launcher, pycharm-community |
| Extras | pipewire stack, cliphist history, grim/slurp screenshots, btop, xdotool, Papirus icons, JetBrainsMono Nerd Font, GTK forced dark |

Optional prompts during install: **Steam** (auto-enables the `[multilib]`
repo) and AUR extras (**notion-app-electron, modrinth-app, localsend-bin**).
Binds for chatterino, whatsapp-linux-desktop, virtualbox and your
wallpaperengine GUI exist but those aren't auto-installed — install them
yourself and the keys just start working.

## The "smart" part

The installer probes your hardware and writes the result to
`~/.config/hypr/machine.lua` so the main config stays portable:

- **Laptop** (battery / DMI chassis / hostnamectl): lid-switch binds with
  **clamshell mode** — lid closed + external monitor = internal panel off;
  no external monitor = lock, then logind suspends. Battery module in waybar,
  suspend-after-15-min idle, `power-profiles-daemon`.
- **Backlight**: brightness waybar module + `XF86MonBrightness` keys.
- **Desktop**: none of the above — no dead battery widget, no surprise suspends.
- **NVIDIA**: recommended Wayland env vars + `no_hardware_cursors`.

Monitor overrides go in `machine.lua` too:
`hl.monitor({ output = "DP-1", mode = "2560x1440@144", position = "0x0", scale = 1 })`

## Config layout

```
~/.config/hypr/
├── hyprland.lua          entry point — just require()s the modules below
├── machine.lua           generated: monitors, lid switch, NVIDIA
├── conf/
│   ├── env.lua           environment variables
│   ├── look.lua          colors, blur, shadows, animations
│   ├── input.lua         keyboard (de), touchpad, gestures
│   ├── windowrules.lua   window & layer rules
│   ├── keybindings.lua   ← all keybinds live here
│   └── autostart.lua     bar, wallpaper, daemons (hyprland.start hook)
├── scripts/              volume/brightness OSD, screenshots, clipboard,
│                         lid clamshell, dontkillsteam
├── hypridle.conf · hyprlock.conf · hyprpaper.conf   (separate tools,
│                                                     still hyprlang)
└── wallpaper.png
```

Each `require()` is error-isolated by Hyprland: a mistake in one module pops
a notification instead of taking down your session.

## Keybinds (your scheme)

| Keys | Action |
|---|---|
| `Super+T` / `Super+Enter` | terminal (alacritty) |
| `Super+A` | app launcher · `Super+Tab` window switcher · `Super+Shift+E` file browser (rofi) |
| `Super+Q` / `Alt+F4` | close window (hides Steam instead of killing it) |
| `Super+W` | toggle floating · `Alt+Return` fullscreen |
| `Super+G` | toggle group · `Super+Alt+H` / `Super+Alt+L` prev/next in group |
| `Super+L` | lock · `Super+Backspace` power menu |
| `Super+E` dolphin · `+F` firefox · `+C` code · `+D` discord · `+K` keepassxc | apps |
| `Super+S` spotify · `+M` modrinth · `+N` notion · `+P` pycharm · `+Alt+M` thunderbird | more apps |
| `Super+Alt+S` steam · `Super+Ctrl+V` virtualbox · `Super+Ctrl+W` Windows VM | gaming/VM |
| `Super+Ctrl+L` | localsend (moved off Super+Alt+L, which is group-next) |
| `Super+arrows` | focus · `+Shift` resize · `+Shift+Ctrl` move (floating-aware) |
| `Super+Z` / `Super+X` | drag / resize with mouse (also `Super+LMB/RMB`) |
| `Super+1..0` | workspace · `+Shift` move & follow · `+Alt` move silently |
| `Super+Ctrl+←/→/↓` | workspace prev / next / first empty |
| `Super+Shift+S` area · `Super+Ctrl+S` frozen area · `Super+Alt+Shift+S` monitor · `Print` all | screenshots |
| `Super+V` / `Super+Shift+V` | clipboard: pick & copy / pick & delete |
| `F10/F11/F12`, media & brightness keys | volume/brightness with OSD popup |

Full list: `~/.config/hypr/conf/keybindings.lua` — edit and save, it reloads live.

## Customizing

- **Keyboard layout**: default is **de** — `conf/input.lua` → `kb_layout`.
- **Wallpaper**: replace `~/.config/hypr/wallpaper.png`.
- **Accent**: Catppuccin *mauve* (`#cba6f7`) — grep it across
  `~/.config/{hypr,waybar,rofi,dunst,wlogout}` and swap any Mocha accent in.
- **Idle timings**: `hypridle.conf` (lock 5 min, screen off 8 min, laptop
  suspend 15 min).
- **Display manager**: none installed — tty1 autostart via `~/.zprofile` is
  offered instead; `sudo pacman -S sddm && sudo systemctl enable sddm` also works.

## Flags

```
./install.sh -y              # fully non-interactive
./install.sh --no-aur        # skip wlogout / AUR entirely
./install.sh --no-shell      # don't chsh to zsh
./install.sh --no-autostart  # don't add tty1 → Hyprland to ~/.zprofile
```

## Uninstall / rollback

Everything replaced lives in `~/backups/` — move it back and remove packages
you don't want. Nothing outside `~/.config`, `~/.zshrc`, `~/.zprofile`,
`~/.oh-my-zsh` and (if you opted into Steam) `/etc/pacman.conf` is touched.
