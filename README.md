# alertxsto/dotfiles

DankMaterialShell (DMS) + Sway dotfiles for Fedora 44.

## What's Inside

| Component | What |
|-----------|------|
| **Sway** | WM config + DMS IPC keybinds, no waybar/swaync/swaylock/swayidle |
| **DMS** | Panel, control center, notifications, OSD, lockscreen, idle |
| **Alacritty** | Terminal with DMS Material You theme |
| **Kitty** | Terminal with DMS Material You theme |
| **flameshot** | Screenshots (PrtSc / Shift+PrtSc) |
| **Auto-theme** | Systemd path watcher syncs DMS colors to Sway client borders |

## Install

```bash
sudo dnf install -y git
git clone https://github.com/alertxsto/dotfiles ~/dotfiles
cd ~/dotfiles && ./install.sh
sudo systemctl reboot
```

On first login, run `dms run` once to generate theme files.

`install.sh` will:
- Enable DMS COPR, install `dms`, `accountsservice`, `flameshot`
- Install system matugen templates
- Symlink all configs
- Run `alacritty migrate` for TOML compat
- Generate sway client colors from current DMS theme
- Enable auto-theme sync via systemd path watcher
- Bind `dms.service` to `sway-session.target`

## Directory Structure

```
~/.config/
├── sway/
│   ├── config
│   └── config.d/
│       ├── 60-bindings-*.conf
│       ├── 90-bar.conf
│       └── 90-swayidle.conf
├── alacritty/
│   ├── alacritty.toml
│   └── dank-theme.toml       # DMS-generated (fallback shipped)
├── kitty/
│   ├── kitty.conf
│   └── dank-*.conf           # DMS-generated
├── dms/                       # Matugen templates
└── systemd/user/
    ├── dms-sway-colors.path
    └── dms-sway-colors.service
```

## Keybinds

| Key | Action |
|-----|--------|
| `Mod+Enter` | Launch terminal |
| `Mod+Space` | App launcher |
| `Mod+Q` | Close window |
| `Mod+D` | Control Center |
| `Mod+Shift+D` | Network menu |
| `Mod+1-9` | Switch workspace |
| `Mod+Shift+1-9` | Move window to workspace |
| `Mod+arrows/hjkl` | Focus direction |
| `Mod+Shift+arrows/hjkl` | Move window direction |
| `Mod+F` | Fullscreen |
| `Mod+Shift+F` | Toggle floating |
| `Mod+R` | Resize mode |
| `Mod+Shift+C` | Reload config |
| `Mod+Shift+E` | Exit Sway |
| `XF86MonBrightnessUp/Down` | Brightness (DMS OSD) |
| `XF86AudioRaiseLowerVolume` | Volume (DMS OSD) |
| `XF86AudioPlay/Next/Prev` | Media (DMS OSD) |
| `PrtSc` | Flameshot GUI |
| `Shift+PrtSc` | Flameshot fullscreen |

## Auto Theme Sync

When DMS changes theme (light/dark or wallpaper), the path watcher triggers a script that regenerates sway client colors and reloads the config. Terminal colors update on new terminal instances.
