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
    printf "  ${DIM}dotfiles  ·  DMS + Sway  ·  Fedora 44${NC}\n\n"
}

# ── Clear screen + print banner ─────────────────────────────────────────────
[ -t 1 ] && printf '\033[2J\033[H'
banner "${CYAN}"

# ── Helpers ───────────────────────────────────────────────────────────────────
_step=0
step() {
    _step=$(( _step + 1 ))
    printf "\n${BOLD}${BLUE}[%d]${NC} ${BOLD}%s${NC}\n" "$_step" "$*"
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

if [ ! -f /etc/fedora-release ]; then
    die "This script only supports Fedora Linux."
fi

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
printf "${DIM}Repo: %s${NC}\n" "$DOTFILES"

# ── Interactive prompts ───────────────────────────────────────────────────────
CHOSEN_TERM="${CHOSEN_TERM:-}"
CHOSEN_FM="${CHOSEN_FM:-}"

if [ -z "$CHOSEN_TERM" ] && [ -t 0 ]; then
    printf "\n${BOLD}${BLUE}── Setup Options ──${NC}\n\n"

    printf "${BOLD}Terminal emulator:${NC}\n"
    printf "  ${CYAN}1${NC}) Alacritty\n"
    printf "  ${CYAN}2${NC}) Kitty\n"
    printf "  ${CYAN}3${NC}) Both ${DIM}(default)${NC}\n"
    printf "${BOLD}Choose [3]:${NC} "
    read -r choice
    case "${choice}" in
        1) CHOSEN_TERM="alacritty" ;;
        2) CHOSEN_TERM="kitty" ;;
        3|"") CHOSEN_TERM="both" ;;
        *) CHOSEN_TERM="both" ;;
    esac
    ok "Terminal: ${CHOSEN_TERM}"

    printf "\n${BOLD}File manager:${NC}\n"
    printf "  ${CYAN}1${NC}) Nautilus ${DIM}(default)${NC}\n"
    printf "  ${CYAN}2${NC}) Thunar\n"
    printf "  ${CYAN}3${NC}) None\n"
    printf "${BOLD}Choose [1]:${NC} "
    read -r choice
    case "${choice}" in
        1|"") CHOSEN_FM="nautilus" ;;
        2) CHOSEN_FM="thunar" ;;
        3) CHOSEN_FM="none" ;;
        *) CHOSEN_FM="nautilus" ;;
    esac
    ok "File manager: ${CHOSEN_FM}"
fi

# Defaults when non-interactive / env vars
CHOSEN_TERM="${CHOSEN_TERM:-both}"
CHOSEN_FM="${CHOSEN_FM:-nautilus}"

# ── Update sway default terminal ──────────────────────────────────────────────
SWAY_TERM="$CHOSEN_TERM"
case "$SWAY_TERM" in
    both|alacritty) SWAY_TERM="alacritty" ;;
esac
sed -i 's/^set \$term .*/set $term '"$SWAY_TERM"'/' "$DOTFILES/.config/sway/config"
ok "Sway \$term → ${SWAY_TERM}"

# ── Backup helper ─────────────────────────────────────────────────────────────
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
_backup_created=0

backup() {
    local target="$1"
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        if [ "$_backup_created" -eq 0 ]; then
            mkdir -p "$BACKUP_DIR"
            _backup_created=1
        fi
        local rel="${target#"$HOME/"}"
        local dst="$BACKUP_DIR/$rel"
        mkdir -p "$(dirname "$dst")"
        cp -r "$target" "$dst"
        warn "Backed up: ~/${rel} → $BACKUP_DIR/${rel}"
    fi
}

# ── Symlink helper ────────────────────────────────────────────────────────────
link() {
    local src="$1" dst="$2"
    backup "$dst"
    if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
        info "Already linked: $dst"
        return
    fi
    rm -rf "$dst"
    ln -sf "$src" "$dst"
    ok "Linked: $dst → $src"
}

# ═════════════════════════════════════════════════════════════════════════════
# [1] Packages
# ═════════════════════════════════════════════════════════════════════════════
step "Installing packages & remove packages"

if ! command -v dms &>/dev/null; then
    info "Enabling DMS COPR..."
    sudo dnf copr enable -y avengemedia/dms
    sudo dnf copr enable -y avengemedia/danklinux

    PKGS=(dms accountsservice flameshot sway jetbrains-mono-fonts-all unzip)
    case "$CHOSEN_TERM" in
        alacritty|both) PKGS+=(alacritty) ;;
    esac
    case "$CHOSEN_TERM" in
        kitty|both) PKGS+=(kitty) ;;
    esac
    case "$CHOSEN_FM" in
        nautilus) PKGS+=(nautilus) ;;
        thunar)   PKGS+=(thunar) ;;
    esac

    sudo dnf install -y "${PKGS[@]}"

    REMOVE=(rofi)
    case "$CHOSEN_FM" in
        nautilus) REMOVE+=(Thunar) ;;
        thunar)   REMOVE+=(nautilus) ;;
    esac
    sudo dnf remove -y "${REMOVE[@]}"

    ok "Packages installed."
else
    ok "DMS already installed — skipping package install."

    case "$CHOSEN_TERM" in
        alacritty|both)
            if ! command -v alacritty &>/dev/null; then
                sudo dnf install -y alacritty
            fi
            ;;
    esac
    case "$CHOSEN_TERM" in
        kitty|both)
            if ! command -v kitty &>/dev/null; then
                sudo dnf install -y kitty
            fi
            ;;
    esac
    if ! command -v unzip &>/dev/null; then
        sudo dnf install -y unzip
    fi
    if ! fc-list 2>/dev/null | grep -qi "jetbrains.mono"; then
        sudo dnf install -y jetbrains-mono-fonts-all
    fi
fi

# ── JetBrainsMono Nerd Font (Nerd Font variant with icons) ─────────────────
step "Installing JetBrainsMono Nerd Font"

NERD_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
FONT_DIR="$HOME/.local/share/fonts"
FONT_MARKER="$FONT_DIR/JetBrainsMonoNerdFont-Regular.ttf"

if [ -f "$FONT_MARKER" ]; then
    ok "JetBrainsMono Nerd Font already installed."
elif fc-list 2>/dev/null | grep -qi "JetBrainsMono.*Nerd Font"; then
    ok "JetBrainsMono Nerd Font already installed (fontconfig)."
else
    info "Downloading JetBrainsMono Nerd Font (~123MB) from GitHub..."
    mkdir -p "$FONT_DIR"
    if curl -fSL --retry 3 --retry-delay 5 -o /tmp/JetBrainsMono.zip "$NERD_URL"; then
        info "Extracting to $FONT_DIR ..."
        unzip -q -o /tmp/JetBrainsMono.zip -d "$FONT_DIR"
        rm -f /tmp/JetBrainsMono.zip
        info "Updating font cache..."
        fc-cache -f 2>/dev/null || warn "Font cache update failed (non-fatal)"
        if [ -f "$FONT_MARKER" ]; then
            ok "JetBrainsMono Nerd Font installed."
        else
            warn "Font extracted but not detected. Try: fc-cache -f && fc-list | grep -i jetbrain"
        fi
    else
        warn "Download failed (check network)."
        info "Manual: https://www.nerdfonts.com/font-downloads"
    fi
fi

# ═════════════════════════════════════════════════════════════════════════════
# [2] System matugen templates
# ═════════════════════════════════════════════════════════════════════════════
step "Installing system matugen templates (requires sudo)"

SYSMAT=/usr/share/quickshell/dms/matugen

if [ -f "$SYSMAT/configs/sway.toml" ]; then
    ok "System matugen templates already installed — skipping."
else
    sudo mkdir -p "$SYSMAT/configs" "$SYSMAT/templates"
    sudo cp "$DOTFILES/.config/dms/matugen/configs/sway.toml"          "$SYSMAT/configs/sway.toml"
    sudo cp "$DOTFILES/.config/dms/matugen/templates/sway-colors.conf" "$SYSMAT/templates/sway-colors.conf"
    ok "System templates installed."
fi

# ═════════════════════════════════════════════════════════════════════════════
# [3] Directory setup
# ═════════════════════════════════════════════════════════════════════════════
step "Setting up directories"

dirs=(
    "$HOME/.config/systemd/user"
    "$HOME/.local/bin"
    "$HOME/Pictures/Screenshots"
)
case "$CHOSEN_TERM" in
    alacritty|both) dirs+=("$HOME/.config/alacritty") ;;
esac
case "$CHOSEN_TERM" in
    kitty|both) dirs+=("$HOME/.config/kitty") ;;
esac

for d in "${dirs[@]}"; do
    mkdir -p "$d"
done
ok "Directories ready."

# ═════════════════════════════════════════════════════════════════════════════
# [4] Symlinks
# ═════════════════════════════════════════════════════════════════════════════
step "Creating symlinks"

# Sway (whole directory)
link "$DOTFILES/.config/sway"  "$HOME/.config/sway"

# DMS matugen configs
link "$DOTFILES/.config/dms"   "$HOME/.config/dms"

# Systemd units
link "$DOTFILES/.config/systemd/user/dms-sway-colors.path"    \
     "$HOME/.config/systemd/user/dms-sway-colors.path"
link "$DOTFILES/.config/systemd/user/dms-sway-colors.service" \
     "$HOME/.config/systemd/user/dms-sway-colors.service"

# Script
link "$DOTFILES/.local/bin/dms-sway-colors" \
     "$HOME/.local/bin/dms-sway-colors"
chmod +x "$DOTFILES/.local/bin/dms-sway-colors"

# Terminal configs
case "$CHOSEN_TERM" in
    alacritty|both)
        link "$DOTFILES/.config/alacritty/alacritty.toml" \
             "$HOME/.config/alacritty/alacritty.toml"

        # Fallback alacritty theme
        DANK_THEME="$HOME/.config/alacritty/dank-theme.toml"
        if [ ! -f "$DANK_THEME" ]; then
            cp "$DOTFILES/.config/alacritty/dank-theme.toml" "$DANK_THEME"
            ok "Deployed fallback alacritty theme."
        else
            info "Fallback alacritty theme already present — skipping."
        fi
        ;;
    kitty)
        link "$DOTFILES/.config/kitty/kitty.conf" \
             "$HOME/.config/kitty/kitty.conf"
        ;;
esac

# ═════════════════════════════════════════════════════════════════════════════
# [5] Alacritty TOML migration
# ═════════════════════════════════════════════════════════════════════════════
step "Alacritty TOML compatibility"

case "$CHOSEN_TERM" in
    alacritty|both)
        if command -v alacritty &>/dev/null; then
            alacritty migrate 2>/dev/null && ok "alacritty migrate ran OK." || true
        fi
        ;;
    *)
        info "Alacritty not installed — skipping migration."
        ;;
esac

# ═════════════════════════════════════════════════════════════════════════════
# [6] Generate initial sway colors
# ═════════════════════════════════════════════════════════════════════════════
step "Generating sway colors from current DMS theme"

DMS_COLORS="$HOME/.local/share/color-schemes/DankMatugenDark.colors"
SWAY_COLORS="$HOME/.config/sway/dms-colors.conf"

if [ -f "$DMS_COLORS" ]; then
    "$HOME/.local/bin/dms-sway-colors" "$DMS_COLORS" "$SWAY_COLORS"
    ok "Colors generated: $SWAY_COLORS"
else
    warn "DMS theme colors not found yet."
    info "Run 'dms run' after first login to generate them."
fi

# ═════════════════════════════════════════════════════════════════════════════
# [7] Systemd services
# ═════════════════════════════════════════════════════════════════════════════
step "Enabling systemd services"

systemctl --user daemon-reload
systemctl --user enable --now dms-sway-colors.path
ok "dms-sway-colors.path enabled."

step "Binding DMS to sway-session.target"

systemctl --user enable dms.service            2>/dev/null || true
systemctl --user add-wants sway-session.target dms 2>/dev/null || true
ok "DMS bound to sway-session.target."

# ═════════════════════════════════════════════════════════════════════════════
# [8] Doctor — verify everything
# ═════════════════════════════════════════════════════════════════════════════
step "Running diagnostics"

"$DOTFILES/dotfiles-doctor.sh" --no-ui && ok "All checks passed." || warn "Some checks failed — review above."

# ═════════════════════════════════════════════════════════════════════════════
# Done
# ═════════════════════════════════════════════════════════════════════════════

if [ "$_backup_created" -eq 1 ]; then
    printf "\n${DIM}Backups saved to: %s${NC}\n" "$BACKUP_DIR"
fi

# Fresh screen with banner
[ -t 1 ] && printf '\033[2J\033[H'
banner "${CYAN}"

printf "${BOLD}${GREEN}✔ Done!${NC}\n"
printf "\n${BOLD}Next steps:${NC}\n"
printf "  ${CYAN}1.${NC} Reboot, or run: ${DIM}swaymsg reload${NC}\n"
printf "  ${CYAN}2.${NC} On first login: ${DIM}dms run${NC} (generates theme colors)\n"
printf "\n${DIM}Or just reboot and enjoy DMS!${NC}\n"
