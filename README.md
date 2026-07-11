# hyprdark

A one-shot post-install for a fresh **Arch Linux** that sets up a dark, polished
**Hyprland** desktop — Catppuccin Mocha everywhere, restrained animations, nothing
that burns your eyes.

```
tar xzf hyprdark.tar.gz
cd hyprdark
./install.sh
```

Run it as your normal user (it uses `sudo` where needed). Re-running is safe:
existing configs are backed up to `~/.config-backup-hyprdark-<timestamp>/` first.

## What it installs

| Piece | Tool |
|---|---|
| Compositor | hyprland (+ hyprpaper, hyprpolkitagent, portals) |
| Bar | waybar — floating rounded pills |
| Launcher | rofi (wayland-native since 2.0) |
| Terminal | alacritty |
| Notifications | dunst (with progress-bar OSD for volume/brightness) |
| Idle / lock | hypridle + hyprlock (blurred-screenshot lockscreen) |
| Power menu | wlogout (AUR — yay is bootstrapped automatically if missing) |
| Shell | zsh + oh-my-zsh, custom `hyprdark` prompt, autosuggestions, syntax highlighting, eza/bat/fzf |
| Extras | thunar, pipewire audio stack, cliphist clipboard history, grim/slurp screenshots, btop, Papirus icons, JetBrainsMono Nerd Font, GTK forced dark |

## The "smart" part

The installer probes your hardware and adapts:

- **Laptop detected** (battery / DMI chassis type / hostnamectl):
  - Lid-switch binds with **clamshell mode** — closing the lid with an external
    monitor attached just disables the internal panel; without one it locks and
    logind suspends. (`~/.config/hypr/scripts/lid.sh`, panel name overridable.)
  - Battery module in waybar, suspend-after-15-min idle listener in hypridle,
    `power-profiles-daemon` enabled.
- **Backlight detected**: brightness module in waybar + `XF86MonBrightness` keys.
- **Desktop**: all of the above is left out — no dead battery widget, no
  surprise suspends.
- **NVIDIA driver detected**: the recommended Wayland env vars and
  `no_hardware_cursors` are added to `~/.config/hypr/machine.conf`.

Everything machine-specific lands in `~/.config/hypr/machine.conf`, so the main
`hyprland.conf` stays portable. Monitor overrides go there too.

## Flags

```
./install.sh -y              # fully non-interactive
./install.sh --no-aur        # skip wlogout / AUR entirely
./install.sh --no-shell      # don't chsh to zsh
./install.sh --no-autostart  # don't add tty1 → Hyprland to ~/.zprofile
```

## Keybinds

| Keys | Action |
|---|---|
| `Super+Enter` | terminal (alacritty) |
| `Super+Space` | app launcher (rofi) |
| `Super+Tab` | window switcher |
| `Super+E` | file manager |
| `Super+Q` | close window |
| `Super+F` | fullscreen |
| `Super+Shift+Space` | toggle floating |
| `Super+arrows` / `+Shift` / `+Ctrl` | focus / move / resize |
| `Super+1..0`, `+Shift` | switch / move to workspace |
| `Super+S` | scratchpad |
| `Super+V` | clipboard history |
| `Super+Alt+L` | lock screen |
| `Super+Escape` | power menu (wlogout) |
| `Print` / `Shift+Print` / `Super+Shift+S` | screenshot area / full / area |
| media & brightness keys | volume/brightness with OSD popup |

## Customizing

- **Keyboard layout**: `~/.config/hypr/hyprland.conf` → `input { kb_layout = us }`.
- **Wallpaper**: replace `~/.config/hypr/wallpaper.png` (or edit `hyprpaper.conf`).
- **Accent color**: it's Catppuccin *mauve* (`#cba6f7`) — grep for it across
  `~/.config/{waybar,rofi,dunst,hypr,wlogout}` and swap in any Mocha accent
  (blue `#89b4fa`, green `#a6e3a1`, peach `#fab387`, …).
- **Idle timings**: `~/.config/hypr/hypridle.conf` (lock 5 min, screen off 8 min,
  laptop suspend 15 min).
- **Display manager**: none is installed — tty1 autologin-style start via
  `~/.zprofile` is offered instead. If you prefer one, `sudo pacman -S sddm &&
  sudo systemctl enable sddm` works fine with this setup.

## Uninstall / rollback

Your previous dotfiles are in `~/.config-backup-hyprdark-<timestamp>/` — move
them back and remove the packages you don't want. Nothing outside `~/.config`,
`~/.zshrc`, `~/.zprofile`, and `~/.oh-my-zsh` is touched.
