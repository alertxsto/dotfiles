# alertxsto/dotfiles

DankMaterialShell (DMS) + Sway dotfiles for Fedora 44.

---

## What's inside

| Component | Role |
|-----------|------|
| **Sway** | Window manager config + DMS IPC keybinds |
| **DMS** | Panel, control center, notifications, OSD, lockscreen, idle |
| **Alacritty** | Terminal with DMS Material You theme |
| **Kitty** | Terminal with DMS Material You theme |
| **flameshot** | Screenshot tool (PrtSc / Shift+PrtSc) |
| **Auto-theme** | Systemd path watcher syncs DMS colors to Sway client borders |

No waybar, swaync, swaylock, or swayidle — DMS handles all of that.

---

## Install

```bash
sudo dnf install -y git
git clone https://github.com/alertxsto/dotfiles ~/dotfiles
cd ~/dotfiles && ./install.sh
sudo systemctl reboot
```

On first login, run `dms run` once to generate theme files.

### What the installer does

- Enables DMS COPR and installs `dms`, `accountsservice`, `flameshot`, `sway`
- Installs system matugen templates to `/usr/share/quickshell/dms/matugen/`
- Creates all necessary config directories
- Symlinks configs (backs up any existing non-symlink files before touching them)
- Runs `alacritty migrate` for TOML compatibility
- Generates initial sway client border colors from the current DMS theme
- Enables `dms-sway-colors.path` for automatic theme sync
- Binds `dms.service` to `sway-session.target`

### Requirements

- Fedora 44 (Workstation Edition recommended)
- `JetBrainsMono Nerd Font` — install via `sudo dnf install jetbrains-mono-fonts-all` or from [nerdfonts.com](https://www.nerdfonts.com/font-downloads)

### Backups

If any of your existing configs are plain files (not symlinks), the installer backs them up to `~/.dotfiles-backup/<timestamp>/` before replacing them. Nothing is silently overwritten.

---

## Directory structure

```
~/dotfiles/
├── install.sh
├── .config/
│   ├── sway/
│   │   ├── config                  # Main sway config
│   │   ├── dms-colors.conf         # Auto-generated client border colors (gitignored)
│   │   └── config.d/
│   │       ├── 60-bindings-brightness.conf
│   │       ├── 60-bindings-media.conf
│   │       ├── 60-bindings-screenshot.conf
│   │       ├── 60-bindings-volume.conf
│   │       ├── 90-bar.conf         # Reserved for bar config (DMS-managed)
│   │       └── 90-swayidle.conf    # Reserved for idle config (DMS-managed)
│   ├── alacritty/
│   │   ├── alacritty.toml
│   │   └── dank-theme.toml         # DMS-generated (fallback shipped)
│   ├── kitty/
│   │   ├── kitty.conf
│   │   ├── dank-theme.conf         # DMS-generated (gitignored)
│   │   └── dank-tabs.conf          # DMS-generated (gitignored)
│   ├── dms/
│   │   └── matugen/
│   │       ├── configs/sway.toml
│   │       └── templates/sway-colors.conf
│   └── systemd/user/
│       ├── dms-sway-colors.path
│       └── dms-sway-colors.service
└── .local/bin/
    └── dms-sway-colors             # Color sync script (Python)
```

---

## Auto theme sync

When DMS changes theme (wallpaper or light/dark toggle), a systemd path watcher detects the change and triggers `dms-sway-colors`, which reads the new KDE color scheme file and writes fresh client border colors to `~/.config/sway/dms-colors.conf`, then reloads Sway. Terminal colors update on new instances automatically via the included config files.

---

## Keybinds

| Key | Action |
|-----|--------|
| `Mod+Enter` | Launch terminal |
| `Mod+Space` | App launcher |
| `Mod+Q` | Close window |
| `Mod+D` | Control center |
| `Mod+Shift+D` | Network menu |
| `Mod+1–9` | Switch workspace |
| `Mod+Shift+1–9` | Move window to workspace |
| `Mod+arrows / hjkl` | Focus direction |
| `Mod+Shift+arrows / hjkl` | Move window |
| `Mod+F` | Fullscreen |
| `Mod+Shift+F` | Toggle floating |
| `Mod+R` | Resize mode |
| `Mod+Shift+C` | Reload config |
| `Mod+Shift+E` | Exit Sway |
| `XF86MonBrightnessUp/Down` | Brightness (DMS OSD) |
| `XF86AudioRaiseVolume/LowerVolume` | Volume (DMS OSD) |
| `XF86AudioMute` | Mute (DMS OSD) |
| `XF86AudioPlay/Next/Prev` | Media controls (DMS OSD) |
| `PrtSc` | Flameshot GUI |
| `Shift+PrtSc` | Flameshot fullscreen capture |

---

## Sway session setup

The sway config requires these two lines to properly initialize DMS via systemd. They should already be present if you're using the symlinked config:

```
exec dbus-update-activation-environment --systemd --all
exec systemctl --user start sway-session.target
```

---

## Related

- [DankLinux / DankMaterialShell](https://danklinux.com) — the shell powering this setup
- [dankinstall](https://danklinux.com/docs/1.5/dankinstall) — official DMS installer
