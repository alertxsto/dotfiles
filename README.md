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

### Sway WM

| Key | Action |
|-----|--------|
| `Mod+Enter` | Launch terminal (Kitty) |
| `Mod+Q` | Close window |
| `Mod+D` | Spotlight launcher |
| `Mod+Shift+Escape` | Lock screen |
| `Mod+Shift+C` | Reload config |
| `Mod+Shift+E` | Exit Sway |

#### DMS Features (no Shift)

| Key | Action |
|-----|--------|
| `Mod+N` | Notifications toggle |
| `Mod+C` | Control Center |
| `Mod+X` | Power Menu |
| `Mod+Y` | Clipboard manager (yank) |
| `Mod+T` | Theme toggle |
| `Mod+I` | Inhibit idle |
| `Mod+M` | Night mode toggle |
| `Mod+Z` | Dashboard |
| `Mod+,` | DMS Settings |

#### Navigation

| Key | Action |
|-----|--------|
| `Mod+h/j/k/l` / arrows | Focus direction |
| `Mod+Shift+h/j/k/l` / Shift+arrows | Move window |
| `Mod+Space` | Toggle tiling/floating |
| `Mod+Shift+Space` | Floating toggle |
| `Mod+A` | Focus parent |
| `Mod+F` | Fullscreen |

#### Workspaces

| Key | Action |
|-----|--------|
| `Mod+1-0` | Switch workspace 1-10 |
| `Mod+Shift+1-0` | Move window to workspace |
| `Mod+Minus` | Scratchpad show |
| `Mod+Shift+Minus` | Send to scratchpad |

#### Layout

| Key | Action |
|-----|--------|
| `Mod+B` | Split horizontal |
| `Mod+V` | Split vertical |
| `Mod+S` | Stacking layout |
| `Mod+W` | Tabbed layout |
| `Mod+E` | Toggle split |
| `Mod+R` → `hjkl/arrows` | Resize mode (Enter/Escape to exit) |

#### Hardware Keys

| Key | Action |
|-----|--------|
| `XF86MonBrightnessUp/Down` | Brightness ±5% (DMS OSD) |
| `XF86AudioRaiseVolume/LowerVolume` | Volume ±5% (DMS OSD) |
| `XF86AudioMute/MicMute` | Mute audio/mic |
| `XF86AudioPlay/Stop/Next/Prev` | Media control (DMS MPRIS) |
| `PrtSc` | Flameshot GUI |
| `Mod+PrtSc` | Flameshot full screen |
| `Ctrl+PrtSc` | Flameshot current screen |

## Auto Theme Sync

When DMS changes theme (light/dark or wallpaper), the path watcher triggers a script that regenerates sway client colors and reloads the config. Terminal colors update on new terminal instances.
