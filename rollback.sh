#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
#  hyprdark — rollback tool
#
#  Restores configs from ~/backups/ (written by install.sh before it touched
#  anything). Before restoring, your current configs are saved again to
#  ~/backups/pre-rollback-<timestamp>/, so this itself is undoable.
#
#  Usage:  ./rollback.sh [--list] [--all] [--dry-run]
#          Without flags: interactive picker.
# ═══════════════════════════════════════════════════════════════════════════
if [ -z "${BASH_VERSION:-}" ]; then exec bash "$0" "$@"; fi
set -euo pipefail

C_M='\033[38;2;232;232;232m'; C_G='\033[38;2;160;220;160m'
C_Y='\033[38;2;220;220;140m'; C_R='\033[38;2;255;140;140m'
C_D='\033[2m'; C_X='\033[0m'
log()  { echo -e "${C_M}::${C_X} $*"; }
ok()   { echo -e "${C_G} ✓${C_X} $*"; }
warn() { echo -e "${C_Y} !${C_X} $*"; }
die()  { echo -e "${C_R} ✗ $*${C_X}" >&2; exit 1; }

BR="$HOME/backups"
[[ -d "$BR" ]] || die "no backups directory at $BR — nothing to roll back"

LIST=false; ALL=false; DRY=false
for a in "$@"; do
    case "$a" in
        --list)    LIST=true ;;
        --all)     ALL=true  ;;
        --dry-run) DRY=true  ;;
        -h|--help) grep -E '^#( |$)' "$0" | sed 's/^# \{0,2\}//'; exit 0 ;;
        *) die "unknown flag: $a" ;;
    esac
done

# What we may restore. Only files/dirs that hyprdark itself installs.
CANDIDATES=(
    ".config/hypr" ".config/waybar" ".config/rofi" ".config/alacritty"
    ".config/dunst" ".config/wlogout"
    ".config/gtk-3.0" ".config/gtk-4.0"
    ".zshrc" ".zprofile"
)

# find all available backups per candidate (base + .old-* siblings)
declare -A HAS
for c in "${CANDIDATES[@]}"; do
    matches=()
    for m in "$BR/$c" "$BR/${c}.old-"*; do
        [[ -e "$m" ]] && matches+=("$m")
    done
    (( ${#matches[@]} )) && HAS[$c]="${matches[*]}"
done

if [[ ${#HAS[@]} -eq 0 ]]; then die "nothing in $BR matches hyprdark's install list"; fi

if $LIST; then
    log "Backups found in ~/backups:"
    for c in "${!HAS[@]}"; do
        printf "  %-24s  " "$c"
        echo -e "${C_D}${HAS[$c]//$HOME/\~}${C_X}"
    done
    exit 0
fi

# selection
declare -a SELECTED
if $ALL; then
    log "Rolling back ALL detected candidates."
    SELECTED=("${!HAS[@]}")
else
    log "Detected backups (space-separated numbers, ENTER for all):"
    keys=("${!HAS[@]}")
    for i in "${!keys[@]}"; do
        latest="${HAS[${keys[$i]}]##* }"
        printf "  ${C_D}%2d)${C_X} %-24s  ← %s\n" "$((i+1))" "${keys[$i]}" "${latest/#$HOME/\~}"
    done
    read -rp "> " picks
    if [[ -z "${picks// /}" ]]; then
        SELECTED=("${keys[@]}")
    else
        for n in $picks; do
            [[ "$n" =~ ^[0-9]+$ ]] || die "not a number: $n"
            (( n >= 1 && n <= ${#keys[@]} )) || die "out of range: $n"
            SELECTED+=("${keys[$((n-1))]}")
        done
    fi
fi

# double-save current state before overwriting
TS="$(date +%Y%m%d-%H%M%S)"
PRE="$BR/pre-rollback-$TS"
$DRY || mkdir -p "$PRE"

log "Current state → $PRE/"
for rel in "${SELECTED[@]}"; do
    src="$HOME/$rel"
    [[ -e "$src" ]] || { echo "   ${rel} (nothing to save)"; continue; }
    if $DRY; then
        echo "   would save ~/$rel"
    else
        mkdir -p "$(dirname "$PRE/$rel")"
        cp -a "$src" "$PRE/$rel"
        echo "   saved ~/$rel"
    fi
done

# restore (use latest backup per candidate — the one without .old-* suffix,
# else the newest .old-*)
log "Restoring…"
for rel in "${SELECTED[@]}"; do
    IFS=' ' read -r -a arr <<< "${HAS[$rel]}"
    src="${arr[0]}"                         # prefer plain path
    if [[ ! -e "$BR/$rel" ]]; then          # only .old-* siblings exist
        src="$(printf '%s\n' "${arr[@]}" | sort | tail -1)"
    fi
    dst="$HOME/$rel"
    if $DRY; then
        echo "   would restore ~/$rel  ←  ${src/#$HOME/\~}"
    else
        rm -rf "$dst"
        mkdir -p "$(dirname "$dst")"
        cp -a "$src" "$dst"
        ok "restored ~/$rel"
    fi
done

echo
if $DRY; then
    warn "dry run — nothing changed."
else
    ok "Rollback complete. Reload hyprland (Super+Shift+R) or log out & back in."
    echo -e "   ${C_D}Undo this rollback: move files from $PRE/ back into place.${C_X}"
fi
