#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

_step=0
step() {
    _step=$(( _step + 1 ))
    printf "\n${BOLD}${RED}[%d]${NC} ${BOLD}%s${NC}\n" "$_step" "$*"
}
ok()   { printf "    ${GREEN}✔${NC}  %s\n" "$*"; }
info() { printf "    ${CYAN}→${NC}  %s\n" "$*"; }
warn() { printf "    ${YELLOW}⚠${NC}  %s\n" "$*"; }

if [ "$(id -u)" -eq 0 ]; then
    die "Don't run this as root."
fi

printf "\n${RED}${BOLD}Uninstalling dotfiles...${NC}\n"
printf "${DIM}This will remove symlinks and disable services.${NC}\n\n"

# ── Confirm ──
printf "${YELLOW}Are you sure? This will NOT restore your original configs automatically.${NC}\n"
printf "Backups can be found in ${DIM}~/.dotfiles-backup/${NC}\n"
read -rp "Continue? [y/N] " confirm
if [[ ! "$confirm" =~ ^[yY]$ ]]; then
    echo "Aborted."
    exit 1
fi

# ══════════════════════════════════════════════════════════════════════════
# [1] Systemd services
# ══════════════════════════════════════════════════════════════════════════
step "Disabling systemd services"

systemctl --user disable --now dms-sway-colors.path 2>/dev/null && ok "dms-sway-colors.path disabled" || info "Not enabled, skipping"
systemctl --user disable dms.service 2>/dev/null || true
systemctl --user disable dms 2>/dev/null || true
systemctl --user daemon-reload
ok "Services disabled."

# ══════════════════════════════════════════════════════════════════════════
# [2] Remove symlinks
# ══════════════════════════════════════════════════════════════════════════
step "Removing symlinks"

links=(
    "$HOME/.config/sway"
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
        ok "Removed: $link"
    else
        info "Not a symlink, skipping: $link"
    fi
done

# ══════════════════════════════════════════════════════════════════════════
# [3] DMS-generated theme files (removable leftovers)
# ══════════════════════════════════════════════════════════════════════════
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

# ══════════════════════════════════════════════════════════════════════════
# [4] System matugen templates
# ══════════════════════════════════════════════════════════════════════════
step "Removing system matugen templates (requires sudo)"

if [ -f /usr/share/quickshell/dms/matugen/configs/sway.toml ] || \
   [ -f /usr/share/quickshell/dms/matugen/templates/sway-colors.conf ]; then
    sudo rm -f /usr/share/quickshell/dms/matugen/configs/sway.toml
    sudo rm -f /usr/share/quickshell/dms/matugen/templates/sway-colors.conf
    ok "System templates removed."
else
    info "Not found, skipping."
fi

# ══════════════════════════════════════════════════════════════════════════
# Done
# ══════════════════════════════════════════════════════════════════════════
printf "\n${BOLD}${GREEN}✔ Uninstalled.${NC}\n"
printf "\n${BOLD}What's next:${NC}\n"
printf "  ${CYAN}•${NC} Restore backup: ${DIM}cp -r ~/.dotfiles-backup/<timestamp>/* ~/.config/${NC}\n"
printf "  ${CYAN}•${NC} Remove packages: ${DIM}sudo dnf remove dms accountsservice flameshot${NC}\n"
printf "  ${CYAN}•${NC} Or reinstall: ${DIM}cd ~/dotfiles && ./install.sh${NC}\n\n"
