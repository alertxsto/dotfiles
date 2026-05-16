#!/usr/bin/env bash
set -euo pipefail

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# ── Scroll region ────────────────────────────────────────────────────────────
BANNER_HEIGHT=9

init_scroll() {
    [ -t 1 ] || return 0
    local lines
    lines=$(tput lines 2>/dev/null || echo 24)
    if [ "$lines" -gt "$BANNER_HEIGHT" ]; then
        tput csr "$BANNER_HEIGHT" $((lines - 1)) 2>/dev/null || true
    fi
    printf '\033[2J\033[H'
    printf "${RED}${BOLD}\n"
    cat << 'BANNER'
   █████╗ ██╗     ███████╗██████╗ ████████╗██╗  ██╗███████╗████████╗ ██████╗
  ██╔══██╗██║     ██╔════╝██╔══██╗╚══██╔══╝╚██╗██╔╝██╔════╝╚══██╔══╝██╔═══██╗
  ███████║██║     █████╗  ██████╔╝   ██║    ╚███╔╝ ███████╗   ██║   ██║   ██║
  ██╔══██║██║     ██╔══╝  ██╔══██╗   ██║    ██╔██╗ ╚════██║   ██║   ██║   ██║
  ██║  ██║███████╗███████╗██║  ██║   ██║   ██╔╝ ██╗███████║   ██║   ╚██████╔╝
  ╚═╝  ╚═╝╚══════╝╚══════╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚══════╝   ╚═╝    ╚═════╝
BANNER
    printf "${NC}"
    printf "  ${DIM}dotfiles  ·  UNINSTALL  ·  Fedora 44${NC}\n\n"
    printf '\033[%d;1H' $((BANNER_HEIGHT + 1))
}

reset_scroll() {
    [ -t 1 ] || return 0
    local lines
    lines=$(tput lines 2>/dev/null || echo 24)
    tput csr 0 $((lines - 1)) 2>/dev/null || true
}

# ── Init ─────────────────────────────────────────────────────────────────────
init_scroll

# ── Helpers ───────────────────────────────────────────────────────────────────
_step=0
step() {
    _step=$(( _step + 1 ))
    printf "\n${BOLD}${RED}[%d]${NC} ${BOLD}%s${NC}\n" "$_step" "$*"
}
ok()   { printf "    ${GREEN}✔${NC}  %s\n" "$*"; }
info() { printf "    ${CYAN}→${NC}  %s\n" "$*"; }
warn() { printf "    ${YELLOW}⚠${NC}  %s\n" "$*"; }
err()  { printf "    ${RED}✘${NC}  %s\n" "$*" >&2; }
die()  { err "$*"; exit 1; }

# ── Pre-flight checks ─────────────────────────────────────────────────────────
if [ "$(id -u)" -eq 0 ]; then
    die "Don't run this as root. sudo will be called when needed."
fi

if [ "$(uname)" != "Linux" ]; then
    die "This script only supports Linux."
fi

# ── Confirm ───────────────────────────────────────────────────────────────────
printf "\n${YELLOW}${BOLD}⚠ This will remove all symlinks, disable services, and clean up.${NC}\n"
printf "${YELLOW}Backups (if any) are at: ${DIM}~/.dotfiles-backup/<timestamp>/${NC}\n"
read -rp "Continue? [y/N] " confirm
if [[ ! "$confirm" =~ ^[yY]$ ]]; then
    echo "Aborted."
    exit 1
fi

# ════════════════════════════════════════════════════════════════════════════
# [1] Systemd services (reverse of install step 7)
# ════════════════════════════════════════════════════════════════════════════
step "Disabling systemd services"

systemctl --user disable --now dms-sway-colors.path 2>/dev/null \
    && ok "dms-sway-colors.path disabled" \
    || info "Not enabled, skipping."

systemctl --user disable dms.service 2>/dev/null || true

# Clean up the add-wants symlink too (created by install.sh step 7)
systemctl --user disable sway-session.target.wants/dms.service 2>/dev/null || true

systemctl --user daemon-reload
ok "Services disabled."

# ════════════════════════════════════════════════════════════════════════════
# [2] Remove system matugen templates (reverse of install step 2)
# ════════════════════════════════════════════════════════════════════════════
step "Removing system matugen templates (requires sudo)"

SYSMAT=/usr/share/quickshell/dms/matugen

if [ -f "$SYSMAT/configs/sway.toml" ] || [ -f "$SYSMAT/templates/sway-colors.conf" ]; then
    sudo rm -f "$SYSMAT/configs/sway.toml" "$SYSMAT/templates/sway-colors.conf"
    ok "System templates removed."
else
    info "Not found, skipping."
fi

# ════════════════════════════════════════════════════════════════════════════
# [3] Remove symlinks (reverse of install step 4)
# ════════════════════════════════════════════════════════════════════════════
step "Removing symlinks"

links=(
    "$HOME/.config/dms"
    "$HOME/.config/systemd/user/dms-sway-colors.path"
    "$HOME/.config/systemd/user/dms-sway-colors.service"
    "$HOME/.config/alacritty/alacritty.toml"
    "$HOME/.config/kitty/kitty.conf"
    "$HOME/.local/bin/dms-sway-colors"
)

for link in "${links[@]}"; do
    if [ -L "$link" ]; then
        rm "$link"
        ok "Removed symlink: $link"
    elif [ ! -e "$link" ]; then
        info "Already absent: $link"
    else
        info "Not a symlink, skipping: $link"
    fi
done

# ════════════════════════════════════════════════════════════════════════════
# [4] DMS-generated theme files (reverse of install step 4 — fallback + generated)
# ════════════════════════════════════════════════════════════════════════════
step "Cleaning up DMS-generated theme files"

dms_files=(
    "$HOME/.config/sway/dms-colors.conf"
    "$HOME/.config/kitty/dank-theme.conf"
    "$HOME/.config/kitty/dank-tabs.conf"
    "$HOME/.config/alacritty/dank-theme.toml"
)

for f in "${dms_files[@]}"; do
    if [ -f "$f" ] && [ ! -L "$f" ]; then
        rm "$f"
        ok "Removed: $f"
    fi
done

# ════════════════════════════════════════════════════════════════════════════
# Done
# ════════════════════════════════════════════════════════════════════════════
reset_scroll

printf "\n${BOLD}${GREEN}✔ Uninstalled.${NC}\n"
printf "\n${BOLD}Next steps:${NC}\n"
printf "  ${CYAN}1.${NC} Restore your original configs from backup:\n"
printf "         ${DIM}ls ~/.dotfiles-backup/  (pick a timestamp)${NC}\n"
printf "         ${DIM}cp -r ~/.dotfiles-backup/<timestamp>/.config/* ~/.config/${NC}\n"
printf "  ${CYAN}2.${NC} Or reinstall: ${DIM}cd ~/dotfiles && ./install.sh${NC}\n"
printf "  ${CYAN}3.${NC} Unused packages (optional): ${DIM}sudo dnf remove dms accountsservice flameshot${NC}\n\n"
