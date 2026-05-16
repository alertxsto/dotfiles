#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
echo "==> Dotfiles installer"
echo "    Repo: $DOTFILES"

# ── Packages ──────────────────────────────────────────────
echo ""
echo "==> Installing packages..."

if ! command -v dms &>/dev/null; then
    echo "    Enabling DMS COPR..."
    sudo dnf copr enable -y avengemedia/dms
    sudo dnf install -y dms accountsservice flameshot
    sudo dnf copr enable -y avengemedia/danklinux
    echo "    DMS installed."
else
    echo "    DMS already installed, skipping."
fi

# ── System Matugen Templates (sudo) ──────────────────────
echo ""
echo "==> Installing system matugen templates (requires sudo)..."
sudo mkdir -p /usr/share/quickshell/dms/matugen/configs
sudo mkdir -p /usr/share/quickshell/dms/matugen/templates
sudo cp "$DOTFILES/.config/dms/matugen/configs/sway.toml" /usr/share/quickshell/dms/matugen/configs/sway.toml
sudo cp "$DOTFILES/.config/dms/matugen/templates/sway-colors.conf" /usr/share/quickshell/dms/matugen/templates/sway-colors.conf

# ── Directory Setup ──────────────────────────────────────
echo ""
echo "==> Setting up directories..."
mkdir -p "$HOME/.config/sway"
mkdir -p "$HOME/.config/systemd/user"
mkdir -p "$HOME/.config/dms"
mkdir -p "$HOME/.config/alacritty"
mkdir -p "$HOME/.config/kitty"
mkdir -p "$HOME/.local/bin"

# ── Symlinks ──────────────────────────────────────────────
echo ""
echo "==> Creating symlinks..."

link() {
    local src="$1" dst="$2"
    if [ -e "$dst" ] && [ ! -L "$dst" ]; then
        echo "    WARNING: $dst exists and is not a symlink, skipping"
        return
    fi
    ln -sf "$src" "$dst"
    echo "    $dst -> $src"
}

link "$DOTFILES/.config/sway"            "$HOME/.config/sway"
link "$DOTFILES/.config/systemd/user/dms-sway-colors.path"    "$HOME/.config/systemd/user/dms-sway-colors.path"
link "$DOTFILES/.config/systemd/user/dms-sway-colors.service" "$HOME/.config/systemd/user/dms-sway-colors.service"
link "$DOTFILES/.config/dms"             "$HOME/.config/dms"
link "$DOTFILES/.local/bin/dms-sway-colors" "$HOME/.local/bin/dms-sway-colors"

# Terminal configs (individual files so DMS can write its theme files alongside)
link "$DOTFILES/.config/alacritty/alacritty.toml"  "$HOME/.config/alacritty/alacritty.toml"
link "$DOTFILES/.config/kitty/kitty.conf"           "$HOME/.config/kitty/kitty.conf"
# Fallback theme for alacritty (will be overwritten by DMS matugen)
cp -n "$DOTFILES/.config/alacritty/dank-theme.toml" "$HOME/.config/alacritty/dank-theme.toml" 2>/dev/null || true

# ── DMS Color Watcher ────────────────────────────────────
echo ""
echo "==> Generating sway colors from current DMS theme..."
if [ -f "$HOME/.local/share/color-schemes/DankMatugenDark.colors" ]; then
    "$HOME/.local/bin/dms-sway-colors" \
        "$HOME/.local/share/color-schemes/DankMatugenDark.colors" \
        "$HOME/.config/sway/dms-colors.conf"
    echo "    Colors generated."
else
    echo "    WARNING: DMS theme colors not found (run DMS first to generate them)"
fi

# ── Systemd Services ─────────────────────────────────────
echo ""
echo "==> Enabling systemd services..."
systemctl --user daemon-reload
systemctl --user enable --now dms-sway-colors.path
# DMS is started via sway-session.target

echo ""
echo "==> Binding DMS to sway session..."
systemctl --user enable dms.service 2>/dev/null || true
systemctl --user add-wants sway-session.target dms 2>/dev/null || true

# ── Final ────────────────────────────────────────────────
echo ""
echo "==> Done!"
echo ""
echo "Next steps:"
echo "  1. Add to ~/.config/sway/config (already done if symlinked):"
echo "       exec dbus-update-activation-environment --systemd --all"
echo "       exec systemctl --user start sway-session.target"
echo "  2. Restart sway or run: swaymsg reload"
echo "  3. Run dms once to generate theme colors: dms run"
echo ""
echo "Or just reboot and enjoy DMS!"
