#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
#  hyprdark — one-shot post-install for Arch + Hyprland
#  Dark, polished Catppuccin Mocha desktop:
#  hyprland · waybar · rofi · alacritty · dunst · hyprlock · hypridle · wlogout
#
#  Detects laptop vs desktop (lid switch, battery, backlight, suspend-on-idle)
#  and NVIDIA GPUs, and adapts the configs accordingly.
#
#  Usage:  ./install.sh [options]
#    -y, --yes         non-interactive (assume yes everywhere)
#        --no-aur      skip AUR entirely (wlogout won't be installed)
#        --no-shell    don't change the login shell to zsh
#        --no-autostart  don't add Hyprland autostart to ~/.zprofile (tty1)
#    -h, --help        show this help
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
      /____/_/        Arch + Hyprland, but pretty
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
ask "Install packages and deploy the hyprdark configs?" || die "aborted"

# ── packages ────────────────────────────────────────────────────────────────
PKGS=(
    # compositor + ecosystem
    hyprland hyprpaper hypridle hyprlock hyprpolkitagent
    xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
    qt5-wayland qt6-wayland
    # shell components
    waybar rofi alacritty dunst
    # audio
    pipewire pipewire-alsa pipewire-pulse wireplumber pavucontrol pamixer playerctl
    # tools used by binds/scripts
    brightnessctl grim slurp wl-clipboard cliphist jq btop
    # network / bluetooth
    networkmanager network-manager-applet bluez bluez-utils
    # files
    thunar thunar-volman tumbler gvfs
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

# ── wlogout (AUR) ───────────────────────────────────────────────────────────
install_wlogout() {
    if pacman -Qq wlogout &>/dev/null; then ok "wlogout already installed"; return; fi
    if pacman -Si wlogout &>/dev/null; then
        sudo pacman -S --needed "${NOCONFIRM[@]}" wlogout; return
    fi
    $USE_AUR || { warn "wlogout is AUR-only and --no-aur was set — skipping (power menu binds won't work)"; return; }

    local helper=""
    for h in yay paru; do command -v "$h" >/dev/null && helper="$h" && break; done
    if [[ -z "$helper" ]]; then
        log "No AUR helper found — bootstrapping yay-bin…"
        sudo pacman -S --needed "${NOCONFIRM[@]}" base-devel git
        local tmp; tmp="$(mktemp -d)"
        git clone --depth 1 https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"
        ( cd "$tmp/yay-bin" && makepkg -si "${NOCONFIRM[@]}" )
        rm -rf "$tmp"
        helper="yay"
    fi
    log "Installing wlogout from AUR via $helper…"
    "$helper" -S --needed "${NOCONFIRM[@]}" wlogout
    ok "wlogout installed"
}
install_wlogout

# ── backup old configs ──────────────────────────────────────────────────────
TS="$(date +%Y%m%d-%H%M%S)"
BACKUP="$HOME/.config-backup-hyprdark-$TS"
backup() {
    local p="$1"
    [[ -e "$p" ]] || return 0
    mkdir -p "$BACKUP"
    mv "$p" "$BACKUP/"
    warn "backed up $(basename "$p") → $BACKUP/"
}
for d in hypr waybar rofi alacritty dunst wlogout; do backup "$HOME/.config/$d"; done
backup "$HOME/.zshrc"

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

# machine.conf: the hardware-specific bits of hyprland.conf
MC="$HOME/.config/hypr/machine.conf"
{
    echo "# hyprdark — generated $(date) — machine-specific settings"
    echo "# Monitor overrides go here, e.g.:"
    echo "# monitor = DP-1, 2560x1440@144, 0x0, 1"
    echo
    if $IS_LAPTOP; then
        cat << 'EOF'
# ── Laptop: lid switch (clamshell-aware) ────────────────────────────────────
# Closing the lid with an external monitor attached disables the internal
# panel; without one it locks, then logind suspends (its default).
# If your panel isn't eDP-1, check `hyprctl monitors` and edit lid.sh.
bindl = , switch:on:Lid Switch,  exec, ~/.config/hypr/scripts/lid.sh close
bindl = , switch:off:Lid Switch, exec, ~/.config/hypr/scripts/lid.sh open
EOF
        echo
    fi
    if $HAS_NVIDIA; then
        cat << 'EOF'
# ── NVIDIA ──────────────────────────────────────────────────────────────────
env = LIBVA_DRIVER_NAME,nvidia
env = __GLX_VENDOR_LIBRARY_NAME,nvidia
env = NVD_BACKEND,direct
cursor {
    no_hardware_cursors = true
}
EOF
    fi
} > "$MC"
ok "Configs deployed (hardware profile: $($IS_LAPTOP && echo laptop || echo desktop))"

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
# best effort — needs a session bus, harmless if it fails now
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

# ── autostart on tty1 ───────────────────────────────────────────────────────
if $AUTOSTART && ! grep -q "hyprdark autostart" "$HOME/.zprofile" 2>/dev/null; then
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
ok "hyprdark installed!"
[[ -d "$BACKUP" ]] && echo -e "   ${C_DIM}old configs saved in $BACKUP${C_RST}"
echo "
   Log out and back in on tty1 (or run 'Hyprland').

   Essentials:
     Super+Enter      terminal        Super+Space   app launcher
     Super+Q          close window    Super+E       files
     Super+Alt+L      lock            Super+Escape  power menu
     Super+V          clipboard       Print         screenshot (area)
     Super+1..0       workspaces      Super+F       fullscreen

   Keyboard layout is 'us' — change it in ~/.config/hypr/hyprland.conf
   (input → kb_layout). Full list of binds in the README.
"
$HAS_NVIDIA && warn "NVIDIA: make sure nvidia-dkms (or nvidia-open-dkms) is installed & up to date."
exit 0
