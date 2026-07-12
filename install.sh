#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
#  hyprdark — one-shot post-install for Arch + Hyprland (≥ 0.55, Lua config)
#  Dark, polished Catppuccin Mocha desktop:
#  hyprland · waybar · rofi · alacritty · dunst · hyprlock · hypridle · wlogout
#  + firefox, thunderbird, dolphin, code, keepassxc, discord, spotify, pycharm
#
#  Detects laptop vs desktop (lid switch, battery, backlight, suspend-on-idle)
#  and NVIDIA GPUs, and adapts the configs accordingly.
#  Backs up your existing configs to ~/backups/ BEFORE touching anything.
#
#  Usage:  ./install.sh [options]
#    -y, --yes           non-interactive (assume yes everywhere)
#        --no-aur        skip AUR entirely (wlogout & extras won't install)
#        --no-shell      don't change the login shell to zsh
#        --no-autostart  don't add Hyprland autostart to ~/.zprofile (tty1)
#    -h, --help          show this help
# ═══════════════════════════════════════════════════════════════════════════
if [ -z "${BASH_VERSION:-}" ]; then exec bash "$0" "$@"; fi   # ran with sh? → bash
set -euo pipefail

# ── pretty output ───────────────────────────────────────────────────────────
C_MAUVE='\033[38;2;203;166;247m'; C_GREEN='\033[38;2;166;227;161m'
C_YELLOW='\033[38;2;249;226;175m'; C_RED='\033[38;2;243;139;168m'
C_BLUE='\033[38;2;137;180;250m'; C_DIM='\033[2m'; C_RST='\033[0m'
log()  { echo -e "${C_MAUVE}::${C_RST} $*"; }
ok()   { echo -e "${C_GREEN} ✓${C_RST} $*"; }
warn() { echo -e "${C_YELLOW} !${C_RST} $*"; }
die()  { echo -e "${C_RED} ✗ $*${C_RST}" >&2; exit 1; }

# ── options ─────────────────────────────────────────────────────────────────
ASSUME_YES=false; USE_AUR=true; SET_SHELL=true; AUTOSTART=true
while (( $# )); do
    case "$1" in
        -y|--yes)       ASSUME_YES=true ;;
        --no-aur)       USE_AUR=false ;;
        --no-shell)     SET_SHELL=false ;;
        --no-autostart) AUTOSTART=false ;;
        -h|--help)      grep -E '^#( |$)' "$0" | sed 's/^# \{0,2\}//'; exit 0 ;;
        *) die "unknown option: $1 (see --help)" ;;
    esac
    shift
done

ask() {  # ask "question" -> 0 = yes
    $ASSUME_YES && return 0
    local reply
    read -rp "$(echo -e "${C_BLUE}?${C_RST} $1 [Y/n] ")" reply
    [[ -z "$reply" || "$reply" =~ ^[Yy] ]]
}
ask_no() {  # like ask, but default No
    $ASSUME_YES && return 1
    local reply
    read -rp "$(echo -e "${C_BLUE}?${C_RST} $1 [y/N] ")" reply
    [[ "$reply" =~ ^[Yy] ]]
}

# ── sanity checks ───────────────────────────────────────────────────────────
[[ $EUID -eq 0 ]] && die "run as your normal user, not root (sudo is used where needed)"
command -v pacman >/dev/null || die "pacman not found — this script is for Arch Linux"
command -v sudo   >/dev/null || die "sudo is required"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -d "$SCRIPT_DIR/configs" ]] || die "configs/ not found next to install.sh — run from the extracted tarball"

# ── hardware detection ──────────────────────────────────────────────────────
IS_LAPTOP=false
if compgen -G "/sys/class/power_supply/BAT*" >/dev/null; then
    IS_LAPTOP=true
else
    chassis="$(cat /sys/class/dmi/id/chassis_type 2>/dev/null || echo 0)"
    case "$chassis" in 8|9|10|11|14|31|32) IS_LAPTOP=true ;; esac
    case "$(hostnamectl chassis 2>/dev/null || true)" in
        laptop|convertible|tablet) IS_LAPTOP=true ;;
    esac
fi

HAS_BACKLIGHT=false
compgen -G "/sys/class/backlight/*" >/dev/null && HAS_BACKLIGHT=true

HAS_NVIDIA=false
if lsmod 2>/dev/null | grep -q '^nvidia' || pacman -Qq nvidia-utils &>/dev/null; then
    HAS_NVIDIA=true
fi

echo -e "${C_MAUVE}"
cat << 'BANNER'
    __                          __           __
   / /_  __  ______  _________/ /___ ______/ /__
  / __ \/ / / / __ \/ ___/ __  / __ `/ ___/ //_/
 / / / / /_/ / /_/ / /  / /_/ / /_/ / /  / ,<
/_/ /_/\__, / .___/_/   \__,_/\__,_/_/  /_/|_|
      /____/_/     Arch + Hyprland (Lua), but pretty
BANNER
echo -e "${C_RST}"
log "Detected machine profile:"
if $IS_LAPTOP; then
    ok "Laptop  →  lid-switch handling, battery module, suspend on idle"
else
    ok "Desktop →  no battery/lid extras"
fi
$HAS_BACKLIGHT && ok "Backlight found  →  brightness module + keys enabled" \
               || echo -e "${C_DIM}   no backlight device (brightness module skipped)${C_RST}"
$HAS_NVIDIA && warn "NVIDIA driver detected  →  adding Wayland env vars for it"
echo
ask "Back up existing configs, install packages, deploy hyprdark?" || die "aborted"

# ── backups FIRST — mirror of \$HOME under ~/backups ────────────────────────
TS="$(date +%Y%m%d-%H%M%S)"
BACKUP_ROOT="$HOME/backups"
did_backup=false
backup() {  # backup <path-under-home>   e.g. .config/hypr  or  .zshrc
    local rel="$1" src="$HOME/$1"
    [[ -e "$src" ]] || return 0
    local dst="$BACKUP_ROOT/$rel"
    mkdir -p "$(dirname "$dst")"
    [[ -e "$dst" ]] && dst="$dst.old-$TS"     # don't clobber earlier backups
    mv "$src" "$dst"
    warn "backed up ~/$rel → ${dst/#$HOME/\~}"
    did_backup=true
}
log "Backing up existing configs to ~/backups/ …"
for d in hypr waybar rofi alacritty dunst wlogout; do backup ".config/$d"; done
backup ".zshrc"
$did_backup || echo -e "${C_DIM}   nothing to back up${C_RST}"

# ── packages ────────────────────────────────────────────────────────────────
PKGS=(
    # compositor + ecosystem
    hyprland hyprpaper hypridle hyprlock hyprpolkitagent
    xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
    qt5-wayland qt6-wayland
    # shell components
    waybar rofi alacritty dunst
    # login screen
    sddm
    # audio
    pipewire pipewire-alsa pipewire-pulse wireplumber pavucontrol pamixer playerctl
    # tools used by binds/scripts
    brightnessctl grim slurp wl-clipboard cliphist jq btop xdotool
    # network / bluetooth
    networkmanager network-manager-applet bluez bluez-utils
    # apps wired to your keybinds
    firefox thunderbird dolphin ark
    code keepassxc discord spotify-launcher pycharm-community-edition
    # shell & cli niceties
    zsh git curl fzf eza bat
    # fonts & theming
    ttf-jetbrains-mono-nerd noto-fonts noto-fonts-emoji
    papirus-icon-theme gnome-themes-extra
)
$IS_LAPTOP && PKGS+=(power-profiles-daemon)

NOCONFIRM=(); $ASSUME_YES && NOCONFIRM=(--noconfirm)
log "Installing packages (pacman -Syu --needed)…"
sudo pacman -Syu --needed "${NOCONFIRM[@]}" "${PKGS[@]}"
ok "Repo packages installed"

# ── steam (optional: needs the multilib repo) ───────────────────────────────
if ask_no "Install Steam? (enables the [multilib] repo in /etc/pacman.conf)"; then
    if ! grep -q '^\[multilib\]' /etc/pacman.conf; then
        sudo sed -i '/^#\[multilib\]/,/^#Include/ s/^#//' /etc/pacman.conf
    fi
    if grep -q '^\[multilib\]' /etc/pacman.conf; then
        sudo pacman -Sy --needed "${NOCONFIRM[@]}" steam && ok "Steam installed"
    else
        warn "couldn't enable [multilib] automatically — enable it in /etc/pacman.conf, then: sudo pacman -S steam"
    fi
fi

# ── AUR: wlogout + optional extras ──────────────────────────────────────────
AUR_HELPER=""
ensure_aur_helper() {
    [[ -n "$AUR_HELPER" ]] && return 0
    for h in yay paru; do command -v "$h" >/dev/null && AUR_HELPER="$h" && return 0; done
    log "No AUR helper found — bootstrapping yay-bin…"
    sudo pacman -S --needed "${NOCONFIRM[@]}" base-devel git
    local tmp; tmp="$(mktemp -d)"
    git clone --depth 1 https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"
    ( cd "$tmp/yay-bin" && makepkg -si "${NOCONFIRM[@]}" )
    rm -rf "$tmp"
    AUR_HELPER="yay"
}

if pacman -Si wlogout &>/dev/null; then
    sudo pacman -S --needed "${NOCONFIRM[@]}" wlogout
elif $USE_AUR; then
    ensure_aur_helper
    "$AUR_HELPER" -S --needed "${NOCONFIRM[@]}" wlogout && ok "wlogout installed (AUR)"
else
    warn "wlogout is AUR-only and --no-aur was set — skipping (SUPER+Backspace won't work)"
fi

# apps from your binds that only exist in the AUR — install what succeeds,
# skip what doesn't; the keybinds are there either way
OPTIONAL_AUR=(notion-app-electron modrinth-app localsend-bin)
if $USE_AUR && ask_no "Install optional AUR apps (${OPTIONAL_AUR[*]})?"; then
    ensure_aur_helper
    for pkg in "${OPTIONAL_AUR[@]}"; do
        if "$AUR_HELPER" -S --needed "${NOCONFIRM[@]}" "$pkg"; then
            ok "$pkg"
        else
            warn "$pkg failed to build/install — skipped"
        fi
    done
fi

# ── deploy configs ──────────────────────────────────────────────────────────
log "Deploying configs…"
mkdir -p "$HOME/.config"
cp -r "$SCRIPT_DIR/configs/hypr"      "$HOME/.config/hypr"
cp -r "$SCRIPT_DIR/configs/waybar"    "$HOME/.config/waybar"
cp -r "$SCRIPT_DIR/configs/rofi"      "$HOME/.config/rofi"
cp -r "$SCRIPT_DIR/configs/alacritty" "$HOME/.config/alacritty"
cp -r "$SCRIPT_DIR/configs/dunst"     "$HOME/.config/dunst"
cp -r "$SCRIPT_DIR/configs/wlogout"   "$HOME/.config/wlogout"
cp    "$SCRIPT_DIR/wallpapers/hyprdark.png" "$HOME/.config/hypr/wallpaper.png"
chmod +x "$HOME/.config/hypr/scripts/"*.sh

# wlogout: resolve icon dir to an absolute path (GTK CSS needs it)
sed -i "s|ICONDIR|$HOME/.config/wlogout/icons|g" "$HOME/.config/wlogout/style.css"

# waybar: inject the right modules for this machine
WB="$HOME/.config/waybar/config.jsonc"
LAPTOP_MODS=""
$HAS_BACKLIGHT && LAPTOP_MODS+='"backlight", '
$IS_LAPTOP     && LAPTOP_MODS+='"battery", '
if [[ -n "$LAPTOP_MODS" ]]; then
    sed -i "s|\"__LAPTOP_MODULES__\",|${LAPTOP_MODS}|" "$WB"
else
    sed -i '/__LAPTOP_MODULES__/d' "$WB"
fi

# hypridle: suspend on idle only makes sense on battery-powered machines
HL="$HOME/.config/hypr/hypridle.conf"
if $IS_LAPTOP; then
    cat >> "$HL" << 'EOF'

listener {
    timeout = 900                               # 15 min → suspend
    on-timeout = systemctl suspend
}
EOF
fi
sed -i '/__SUSPEND_LISTENER__/d' "$HL"

# hyprlock: show battery state on laptops
HLK="$HOME/.config/hypr/hyprlock.conf"
if $IS_LAPTOP; then
    cat >> "$HLK" << 'EOF'

# Battery (laptop)
label {
    monitor =
    text = cmd[update:30000] ~/.config/hypr/scripts/battery-status.sh
    color = rgba(154, 154, 154, 1.0)
    font_size = 14
    font_family = JetBrainsMono Nerd Font
    position = 0, -215
    halign = center
    valign = center
}
EOF
fi
sed -i '/__BATTERY_LABEL__/d' "$HLK"

# machine.lua: the hardware-specific bits of the Hyprland Lua config
MC="$HOME/.config/hypr/machine.lua"
{
    echo "-- hyprdark — machine.lua (generated $(date)) — machine-specific settings"
    cat << 'EOF'
-- Monitor default; add overrides below, e.g.:
--   hl.monitor({ output = "DP-1", mode = "2560x1440@144", position = "0x0", scale = 1 })
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })
EOF
    if $IS_LAPTOP; then
        cat << 'EOF'

-- ── Laptop: lid switch (clamshell-aware) ────────────────────────────────────
-- Closing the lid with an external monitor attached disables the internal
-- panel; without one it locks, then logind suspends (its default).
-- If your panel isn't eDP-1, check `hyprctl monitors` and edit lid.sh.
local lid = os.getenv("HOME") .. "/.config/hypr/scripts/lid.sh"
hl.bind("switch:on:Lid Switch",  hl.dsp.exec_cmd(lid .. " close"), { locked = true })
hl.bind("switch:off:Lid Switch", hl.dsp.exec_cmd(lid .. " open"),  { locked = true })
EOF
    fi
    if $HAS_NVIDIA; then
        cat << 'EOF'

-- ── NVIDIA ──────────────────────────────────────────────────────────────────
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("NVD_BACKEND", "direct")
hl.config({ cursor = { no_hardware_cursors = true } })
EOF
    fi
} > "$MC"
ok "Configs deployed (hardware profile: $($IS_LAPTOP && echo laptop || echo desktop), layout: de)"

# ── GTK dark theme ──────────────────────────────────────────────────────────
log "Setting dark GTK theme (Adwaita-dark + Papirus-Dark)…"
for v in gtk-3.0 gtk-4.0; do
    mkdir -p "$HOME/.config/$v"
    cat > "$HOME/.config/$v/settings.ini" << 'EOF'
[Settings]
gtk-theme-name = Adwaita-dark
gtk-application-prefer-dark-theme = 1
gtk-icon-theme-name = Papirus-Dark
gtk-cursor-theme-name = Adwaita
gtk-cursor-theme-size = 24
gtk-font-name = Noto Sans 10.5
EOF
done
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'   2>/dev/null || true
gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'  2>/dev/null || true
ok "GTK set to dark"

# ── zsh + oh-my-zsh ─────────────────────────────────────────────────────────
log "Setting up zsh + oh-my-zsh…"
OMZ="$HOME/.oh-my-zsh"
if [[ ! -d "$OMZ" ]]; then
    git clone --depth 1 https://github.com/ohmyzsh/ohmyzsh.git "$OMZ"
fi
ZC="${ZSH_CUSTOM:-$OMZ/custom}"
[[ -d "$ZC/plugins/zsh-autosuggestions" ]] || \
    git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions "$ZC/plugins/zsh-autosuggestions"
[[ -d "$ZC/plugins/zsh-syntax-highlighting" ]] || \
    git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting "$ZC/plugins/zsh-syntax-highlighting"
[[ -d "$ZC/plugins/zsh-completions" ]] || \
    git clone --depth 1 https://github.com/zsh-users/zsh-completions "$ZC/plugins/zsh-completions"
mkdir -p "$ZC/themes"
cp "$SCRIPT_DIR/configs/zsh/hyprdark.zsh-theme" "$ZC/themes/"
cp "$SCRIPT_DIR/configs/zsh/zshrc" "$HOME/.zshrc"

if $SET_SHELL && [[ "$(getent passwd "$USER" | cut -d: -f7)" != "$(command -v zsh)" ]]; then
    if ask "Make zsh your login shell?"; then
        sudo chsh -s "$(command -v zsh)" "$USER" && ok "login shell → zsh"
    fi
fi
ok "oh-my-zsh ready (theme: hyprdark)"

# ── services ────────────────────────────────────────────────────────────────
log "Enabling services…"
sudo systemctl enable --now NetworkManager.service 2>/dev/null || true
sudo systemctl enable --now bluetooth.service      2>/dev/null || true
$IS_LAPTOP && { sudo systemctl enable --now power-profiles-daemon.service 2>/dev/null || true; }
ok "Services enabled"

# ── SDDM login screen ───────────────────────────────────────────────────────
SDDM_ENABLED=false
if ask "Enable the SDDM login screen (hyprdark theme)?"; then
    log "Installing the hyprdark SDDM theme…"
    sudo mkdir -p /usr/share/sddm/themes /etc/sddm.conf.d
    sudo cp -r "$SCRIPT_DIR/configs/sddm/hyprdark-sddm" /usr/share/sddm/themes/
    sudo cp "$SCRIPT_DIR/wallpapers/hyprdark.png" /usr/share/sddm/themes/hyprdark-sddm/background.png
    printf '[Theme]\nCurrent=hyprdark-sddm\n' | sudo tee /etc/sddm.conf.d/10-hyprdark.conf >/dev/null
    sudo systemctl enable sddm.service 2>/dev/null || true
    SDDM_ENABLED=true
    ok "SDDM enabled with the hyprdark theme"
fi

# ── autostart on tty1 (only without SDDM) ───────────────────────────────────
if ! $SDDM_ENABLED && $AUTOSTART && ! grep -q "hyprdark autostart" "$HOME/.zprofile" 2>/dev/null; then
    if ask "Start Hyprland automatically after login on tty1?"; then
        cat >> "$HOME/.zprofile" << 'EOF'
# hyprdark autostart — launch Hyprland on tty1
if [[ -z "$DISPLAY" && -z "$WAYLAND_DISPLAY" && "$(tty)" == "/dev/tty1" ]]; then
    exec Hyprland
fi
EOF
        ok "Hyprland will start on tty1 login"
    fi
fi

# ── done ────────────────────────────────────────────────────────────────────
echo
echo -e "${C_GREEN}═══════════════════════════════════════════════════════${C_RST}"
ok "hyprdark installed!  (config: ~/.config/hypr/hyprland.lua — edits reload live)"
$did_backup && echo -e "   ${C_DIM}old configs saved under ~/backups/${C_RST}"
echo "
   Reboot — SDDM greets you if you enabled it; otherwise log in on tty1.

   Essentials (your scheme):
     Super+T / Super+Enter   terminal      Super+A          app launcher
     Super+Q / Alt+F4        close         Super+E          dolphin
     Super+F firefox · +C code · +D discord · +S spotify · +K keepassxc
     Super+L lock · Super+Backspace power menu · Super+V clipboard
     Super+Shift+S area shot · Alt+Return fullscreen · Super+W float
     Super+G group · Super+Alt+H/L cycle group · Super+1..0 workspaces

   Keyboard layout is 'de' — change in ~/.config/hypr/conf/input.lua.
   Full bind list: ~/.config/hypr/conf/keybindings.lua (and the README).
"
$HAS_NVIDIA && warn "NVIDIA: make sure nvidia-dkms (or nvidia-open-dkms) is installed & up to date."
warn "Binds for chatterino / whatsapp / virtualbox / wallpaperengine-gui exist but those apps aren't auto-installed — see README."
exit 0
