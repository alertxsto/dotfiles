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

# ── CLI flag ─────────────────────────────────────────────────────────────────
NO_UI=false
[ "${1:-}" = "--no-ui" ] && NO_UI=true

# ── Banner helper ────────────────────────────────────────────────────────────
banner() {
    local color="$1"
    printf "${color}${BOLD}\n"
    cat << 'BANNER'
   █████╗ ██╗     ███████╗██████╗ ████████╗██╗  ██╗███████╗████████╗ ██████╗
  ██╔══██╗██║     ██╔════╝██╔══██╗╚══██╔══╝╚██╗██╔╝██╔════╝╚══██╔══╝██╔═══██╗
  ███████║██║     █████╗  ██████╔╝   ██║    ╚███╔╝ ███████╗   ██║   ██║   ██║
  ██╔══██║██║     ██╔══╝  ██╔══██╗   ██║    ██╔██╗ ╚════██║   ██║   ██║   ██║
  ██║  ██║███████╗███████╗██║  ██║   ██║   ██╔╝ ██╗███████║   ██║   ╚██████╔╝
  ╚═╝  ╚═╝╚══════╝╚══════╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚══════╝   ╚═╝    ╚═════╝
BANNER
    printf "${NC}"
    printf "  ${DIM}dotfiles  ·  DOCTOR  ·  Fedora 44${NC}\n\n"
}

if ! $NO_UI && [ -t 1 ]; then
    printf '\033[2J\033[H'
    banner "${GREEN}"
fi

# ── Helpers ───────────────────────────────────────────────────────────────────
DOTFILES="$(cd "$(dirname "$0")" && pwd)"
OK=0
FAIL=0
WARN=0

pass() { OK=$((OK + 1)); printf "  ${GREEN}✔${NC}  %s\n" "$*"; }
fail() { FAIL=$((FAIL + 1)); printf "  ${RED}✘${NC}  %s\n" "$*"; }
warn() { WARN=$((WARN + 1)); printf "  ${YELLOW}⚠${NC}  %s\n" "$*"; }
info() { printf "  ${CYAN}→${NC}  %s\n" "$*"; }
die()  { printf "  ${RED}✘${NC}  %s\n" "$*" >&2; exit 1; }

check_cmd() {
    local pkg=$1 name=$2
    if command -v "$pkg" &>/dev/null; then
        pass "$name ($pkg)"
    else
        fail "$name ($pkg) — not installed"
    fi
}

check_rpm() {
    if rpm -q "$1" &>/dev/null; then
        pass "$1 (RPM)"
    else
        fail "$1 — not installed"
    fi
}

check_deployed() {
    local target=$1
    if [ -e "$target" ]; then
        pass "$(basename "$target") — deployed"
    else
        fail "$(basename "$target") — missing (run install.sh)"
    fi
}

check_service() {
    local svc=$1
    if systemctl --user is-enabled "$svc" &>/dev/null; then
        pass "$svc (enabled)"
    else
        fail "$svc — not enabled"
    fi
}

# ═════════════════════════════════════════════════════════════════════════════
printf "\n${BOLD}Running diagnostics...${NC}\n"

# ── 1. Repo integrity ─────────────────────────────────────────────────────────
printf "\n${CYAN}${BOLD}── Repo ──${NC}\n"

if [ -d "$DOTFILES/.git" ]; then
    pass "Git repo: $DOTFILES"
else
    fail "$DOTFILES is not a git repo"
fi

REMOTE=$(git -C "$DOTFILES" remote get-url origin 2>/dev/null || echo "")
if [ -n "$REMOTE" ]; then
    pass "Remote origin: $REMOTE"
else
    warn "No remote origin configured"
fi

# ── 2. Packages ────────────────────────────────────────────────────────────────
printf "\n${CYAN}${BOLD}── Packages ──${NC}\n"

check_cmd dms "DMS"
check_cmd sway "Sway WM"
check_cmd pane-fm "Pane-FM"
check_cmd alacritty "Alacritty"
check_cmd flameshot "Flameshot"
check_cmd python3 "Python 3"
check_rpm accountsservice
check_rpm swayfx

# ── 3. Font ────────────────────────────────────────────────────────────────────
printf "\n${CYAN}${BOLD}── Font ──${NC}\n"

FONT_FILE="$HOME/.local/share/fonts/JetBrainsMonoNerdFont-Regular.ttf"
if [ -f "$FONT_FILE" ]; then
    pass "JetBrainsMono Nerd Font (file check)"
elif fc-list 2>/dev/null | grep -qi "JetBrainsMono.*Nerd Font"; then
    pass "JetBrainsMono Nerd Font (fontconfig check)"
else
    fail "JetBrainsMono Nerd Font — not installed"
fi

# ── 4. Config files ──────────────────────────────────────────────────────────────────
printf "\n${CYAN}${BOLD}── Config files ──${NC}\n"

check_deployed "$HOME/.config/sway"
check_deployed "$HOME/.config/dms"
check_deployed "$HOME/.config/systemd/user/dms-sway-colors.path"
check_deployed "$HOME/.config/systemd/user/dms-sway-colors.service"
check_deployed "$HOME/.config/systemd/user/dms-pane-fm-theme.path"
check_deployed "$HOME/.config/systemd/user/dms-pane-fm-theme.service"
check_deployed "$HOME/.config/alacritty/alacritty.toml"
check_deployed "$HOME/.config/kitty/kitty.conf"
check_deployed "$HOME/.local/bin/dms-sway-colors"
check_deployed "$HOME/.local/bin/dms-pane-fm-theme"
check_deployed "$HOME/.local/bin/pane-fm"

# ── 5. Script permissions ──────────────────────────────────────────────────────
printf "\n${CYAN}${BOLD}── Scripts ──${NC}\n"

if [ -x "$HOME/.local/bin/dms-sway-colors" ]; then
    pass "dms-sway-colors (executable)"
else
    fail "dms-sway-colors — not executable"
fi

if [ -x "$HOME/.local/bin/dms-pane-fm-theme" ]; then
    pass "dms-pane-fm-theme (executable)"
else
    fail "dms-pane-fm-theme — not executable"
fi

if [ -x "$HOME/.local/bin/pane-fm" ]; then
    pass "pane-fm binary (executable)"
else
    fail "pane-fm binary — not executable"
fi

# ── 6. Systemd ─────────────────────────────────────────────────────────────────
printf "\n${CYAN}${BOLD}── Systemd ──${NC}\n"

check_service dms-sway-colors.path
check_service dms-pane-fm-theme.path
check_service dms.service

SWAY_WANTS="$HOME/.config/systemd/user/sway-session.target.wants/dms.service"
if [ -L "$SWAY_WANTS" ]; then
    pass "dms.service wanted by sway-session.target"
else
    fail "dms.service NOT wanted by sway-session.target"
fi

# ── 7. DMS theme files ─────────────────────────────────────────────────────────
printf "\n${CYAN}${BOLD}── DMS theme ──${NC}\n"

DMS_COLORS="$HOME/.local/share/color-schemes/DankMatugenDark.colors"
if [ -f "$DMS_COLORS" ]; then
    pass "DMS theme colors: $DMS_COLORS"
else
    warn "DMS theme colors not found — run 'dms run' first"
fi

SWAY_COLORS="$HOME/.config/sway/dms-colors.conf"
if [ -f "$SWAY_COLORS" ]; then
    pass "Sway generated colors: $SWAY_COLORS"
else
    warn "Sway generated colors not found — run 'dms run' first"
fi

PANE_FM_THEME="$HOME/.config/pane-fm/themes/dms-frost.css"
if [ -f "$PANE_FM_THEME" ]; then
    pass "Pane-FM theme: $PANE_FM_THEME"
else
    warn "Pane-FM theme not found — run 'dms run' first"
fi

# ── 8. Sway config essentials ──────────────────────────────────────────────────
printf "\n${CYAN}${BOLD}── Sway config ──${NC}\n"

SWAY_CFG="$HOME/.config/sway/config"
if [ -f "$SWAY_CFG" ]; then
    pass "sway/config exists"
    grep -q "dbus-update-activation-environment" "$SWAY_CFG" \
        && pass "  dbus-update-activation-environment" \
        || warn "  dbus-update-activation-environment — missing"
    grep -q "start sway-session.target" "$SWAY_CFG" \
        && pass "  start sway-session.target" \
        || warn "  start sway-session.target — missing"
    grep -qE '^set \$term (alacritty|kitty|foot|wezterm)' "$SWAY_CFG" \
        && pass "  \$term set" \
        || warn "  \$term — not set to a known terminal"
else
    fail "sway/config — not found"
fi

# ── 9. System matugen templates ────────────────────────────────────────────────
printf "\n${CYAN}${BOLD}── System templates ──${NC}\n"

SYSMAT=/usr/share/quickshell/dms/matugen
if [ -f "$SYSMAT/configs/sway.toml" ]; then
    pass "matugen configs/sway.toml"
else
    warn "System matugen config not found — run install.sh"
fi
if [ -f "$SYSMAT/templates/sway-colors.conf" ]; then
    pass "matugen templates/sway-colors.conf"
else
    warn "System matugen template not found — run install.sh"
fi

# ── 10. Backups ────────────────────────────────────────────────────────────────
printf "\n${CYAN}${BOLD}── Backups ──${NC}\n"

BK_DIRS=$(ls -d "$HOME/.dotfiles-backup"/20* 2>/dev/null | head -5) || true
if [ -n "$BK_DIRS" ]; then
    for d in $BK_DIRS; do
        pass "Backup: $(basename "$d")"
    done
else
    info "No backups found at ~/.dotfiles-backup/"
fi

# ═════════════════════════════════════════════════════════════════════════════
# Summary
# ═════════════════════════════════════════════════════════════════════════════
printf "\n${BOLD}${GREEN}═════════════════════════════${NC}\n"
printf "${BOLD}Summary${NC}\n"
printf "  ${GREEN}✔${NC}  %d passed\n" "$OK"
[ "$WARN" -gt 0 ] && printf "  ${YELLOW}⚠${NC}  %d warnings\n" "$WARN"
[ "$FAIL" -gt 0 ] && printf "  ${RED}✘${NC}  %d failed\n" "$FAIL"
printf "${BOLD}${GREEN}═════════════════════════════${NC}\n"

if [ "$FAIL" -eq 0 ] && [ "$WARN" -eq 0 ]; then
    printf "\n${GREEN}Everything looks good!${NC}\n"
elif [ "$FAIL" -eq 0 ]; then
    printf "\n${YELLOW}Minor warnings — check items above.${NC}\n"
else
    printf "\n${RED}Some checks failed — review items above.${NC}\n"
    printf "${YELLOW}Tip: re-run ${DIM}./install.sh${NC}${YELLOW} to redeploy configs and fix services.${NC}\n"
fi

exit "$FAIL"
