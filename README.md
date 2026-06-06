# alertxsto/dotfiles

DankMaterialShell (DMS) + SwayFX dotfiles for Fedora 44.

## What's Inside

| Component | What |
|-----------|------|
| **SwayFX** | WM config with blur, shadows, rounded corners + DMS IPC keybinds |
| **DMS** | Panel, control center, notifications, OSD, lockscreen, idle |
| **Alacritty** | Terminal with DMS Material You theme |
| **Kitty** | Terminal with DMS Material You theme |
| **Pane-FM** | WebKit-based file manager with blur and DMS auto-theme |
| **flameshot** | Screenshots (PrtSc / Shift+PrtSc) |
| **Auto-theme** | Systemd path watchers sync DMS colors to Sway, pane-FM, and terminals |

## Install

```bash
sudo dnf install -y git
git clone https://github.com/alertxsto/dotfiles ~/dotfiles
cd ~/dotfiles && ./install.sh
sudo systemctl reboot
```

On first login, run `dms run` once to generate theme files.

### install.sh Options

`install.sh` will prompt for:

- **Terminal**: Alacritty, Kitty, or Both (default)
- **Window manager**: Sway (vanilla) or SwayFX with blur/shadows/corners (recommended)
- **File manager**: Nautilus, Thunar, or Pane-FM with 65% transparent DMS theme (recommended)

### What the Script Does

- Enables DMS and SwayFX COPRs, installs all packages (handles `sway` ↔ `swayfx` conflict)
- Installs system matugen templates for sway color generation
- Symlinks all configs from dotfiles repo
- Generates sway client colors and pane-FM theme from current DMS theme
- Enables systemd path watchers for auto-theme sync
- Binds `dms.service` to `sway-session.target`

## Directory Structure

```
~/.config/
├── sway/                         # Base sway config + DMS IPC keybinds
│   ├── config
│   └── config.d/
│       ├── 60-bindings-*.conf
│       ├── 90-bar.conf
│       └── 90-swayidle.conf
├── swayfx/
│   └── config                    # SwayFX effects: blur, shadows, corners
├── pane-fm/
│   ├── config.toml
│   └── themes/
│       └── dms-frost.css         # DMS-generated theme (65% opacity)
├── alacritty/
│   ├── alacritty.toml
│   └── dank-theme.toml           # DMS-generated (fallback shipped)
├── kitty/
│   ├── kitty.conf
│   └── dank-*.conf               # DMS-generated
├── dms/                          # Matugen templates (sway, pane-fm)
└── systemd/user/
    ├── dms-sway-colors.path      # Watches DMS theme → regenerates sway colors
    ├── dms-sway-colors.service
    ├── dms-pane-fm-theme.path    # Watches DMS theme → regenerates pane-FM CSS
    └── dms-pane-fm-theme.service
~/.local/bin/
├── dms-sway-colors               # Python: .colors → sway dms-colors.conf
├── dms-pane-fm-theme             # Python: .colors → pane-FM dms-frost.css
└── pane-fm                       # pane-FM binary
```

## Window Manager: SwayFX

SwayFX is a drop-in replacement for Sway with compositor effects enabled.

### Visual Effects

| Feature | Setting |
|---------|---------|
| **Blur** | 2 passes, radius 3, noise 0.1 |
| **Corners** | Smart corner radius 4px |
| **Shadows** | Enabled, blur radius 20, offset 0x5 |
| **Inactive dim** | Disabled (0.0) |

Per-window rules: blur disabled for Brave, Firefox, mpv, imv. Pixel borders for Nautilus, Thunar, pane-FM.

## File Manager: Pane-FM

Pane-FM is a WebKit-based file manager with native blur/transparency support and CSS hot-reload.

- **Theme**: `dms-frost.css` auto-generated from DMS with 65% `--bg-opacity` for visible blur
- **Hot-reload**: Changes to `dms-frost.css` apply instantly — no restart needed
- **Auto-sync**: Systemd path watcher regenerates theme whenever DMS changes colors

### DMS Pane-FM Theme Generator

```
~/.local/bin/dms-pane-fm-theme <DankMatugenDark.colors> <dms-frost.css>
```

| DMS `.colors` key | pane-FM CSS var |
|---|---|
| `Colors:Window/BackgroundNormal` | `--bg-primary` |
| `+10%` | `--bg-secondary` |
| `+5%` | `--bg-surface` |
| `+20%` | `--bg-hover` |
| `Colors:Window/ForegroundNormal` + darken | `--text-primary`, `--text-secondary`, `--text-muted` |
| `Colors:Selection/BackgroundNormal` | `--accent`, `--accent-hover` |
| `Colors:Window/DecorationFocus` | `--border` |
| `Colors:Window/ForegroundNegative` | `--danger` |
| Static | `--bg-opacity: 65%`, `--radius: 4px`, fonts, shadows |

## Keybinds

### Sway WM

| Key | Action |
|-----|--------|
| `Mod+Enter` | Launch terminal (Kitty) |
| `Mod+O` | Launch pane-FM file manager |
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

Three systemd path watchers keep everything in sync when DMS changes theme (light/dark or wallpaper):

| Watcher | Trigger | Action |
|---------|---------|--------|
| `dms-sway-colors.path` | `.colors` file modified | Regenerates sway client borders + `swaymsg reload` |
| `dms-pane-fm-theme.path` | `.colors` file modified | Regenerates `dms-frost.css` — pane-FM hot-reloads instantly |
| `dms.service` | Session start | Applies DMS theme on login |

Terminal themes (Alacritty, Kitty) update on new terminal instances.
