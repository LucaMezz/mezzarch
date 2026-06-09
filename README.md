<div align="center">

# mezzarch

**A fully automated Arch Linux installation and post-install setup for my personal desktop environment.**

<br>

[![Arch Linux](https://img.shields.io/badge/Arch_Linux-1793D1?style=for-the-badge&logo=arch-linux&logoColor=white)](https://archlinux.org)
[![Hyprland](https://img.shields.io/badge/Hyprland-58E1FF?style=for-the-badge&logo=hyprland&logoColor=black)](https://hyprland.org)
[![Wayland](https://img.shields.io/badge/Wayland-FFBC00?style=for-the-badge&logo=wayland&logoColor=black)](https://wayland.freedesktop.org)
[![NVIDIA](https://img.shields.io/badge/NVIDIA_Open-76B900?style=for-the-badge&logo=nvidia&logoColor=white)](https://github.com/NVIDIA/open-gpu-kernel-modules)
[![Shell](https://img.shields.io/badge/Bash-4EAA25?style=for-the-badge&logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash)
[![Neovim](https://img.shields.io/badge/Neovim-57A143?style=for-the-badge&logo=neovim&logoColor=white)](https://neovim.io)

</div>

---

## Overview

`mezzarch` is my personal Arch Linux bootstrapper. Clone it onto a live ISO, run `install.sh` to lay down the base system, reboot, then run `postinstall.sh` to install all packages, enable services, set the default shell, and pull in dotfiles, wallpapers, and LaTeX templates — a full desktop environment in two commands.

**What gets set up:**

- Hyprland Wayland compositor with SDDM, Waybar, AGS (Aylurs GTK Shell), Dunst, Rofi/Walker
- Neovim, Kitty, Zsh with autosuggestions and syntax highlighting
- Full development toolchain — Rust, Java, Node (nvm), Docker, CMake, Git tooling
- LaTeX typesetting suite via TexLive
- System hardening — UFW firewall, zram swap, NTP
- Dotfiles managed via GNU Stow, pulled from a dedicated repo

---

## System Profile

| Property | Value |
|---|---|
| **Kernel** | `linux` |
| **Bootloader** | GRUB (UKI enabled) |
| **Compositor** | Hyprland |
| **Display Manager** | SDDM |
| **GPU Driver** | NVIDIA Open (Turing+) |
| **Audio** | PipeWire + WirePlumber |
| **Network** | NetworkManager |
| **Shell** | Zsh |
| **Terminal** | Kitty |
| **Swap** | zram (zstd) |
| **Timezone** | Australia/Melbourne |
| **Locale** | en\_AU / UTF-8 |

---

## Prerequisites

- A bare Arch Linux live ISO (USB or PXE)
- Internet connection
- Target disk on `/dev/sda` — **the disk will be wiped entirely**
- `archinstall` available (included on the official Arch ISO since 2021)

> The partition layout targets `/dev/sda` with a 1 GiB FAT32 EFI partition, a 50 GiB ext4 root, and the remainder as ext4 `/home`. Edit `archinstall-configs/user_configuration.json` before running if your setup differs.

---

## Installation

Installation is split into two phases: one from the live ISO and one from the freshly booted system.

### Phase 1 — Base system (live ISO, as root)

Boot the Arch ISO, connect to the internet, then:

```bash
git clone https://github.com/LucaMezz/mezzarch.git
cd mezzarch
bash install.sh
```

`install.sh` runs pre-flight checks (root, internet, archinstall present, config found), prints a summary of the target disk, prompts for confirmation, then hands off to `archinstall` with the bundled config. When it finishes, reboot into the new system.

### Phase 2 — Post-install setup (new system, as your regular user)

Log in, clone the repo again (or copy it from the ISO), then:

```bash
cd mezzarch
bash postinstall.sh
```

`postinstall.sh` runs the following steps in order:

| Step | What it does |
|---|---|
| **Pre-flight** | Confirms non-root user, Arch detected, caches sudo |
| **System update** | `pacman -Sy` to refresh databases |
| **Official packages** | Installs everything in `lists/pacman-packages.txt` |
| **AUR helper** | Builds and installs `yay` if not present |
| **AUR packages** | Installs everything in `lists/aur-packages.txt` |
| **Flatpak** | Adds Flathub, installs apps from `lists/flatpak-apps.txt` |
| **System services** | Enables services listed in `lists/enabled-system-services.txt` |
| **User services** | Enables user-level services from `lists/enabled-user-services.txt`, enables linger |
| **Default shell** | Sets Zsh as the login shell |
| **Dotfiles** | Clones [`LucaMezz/dotfiles`](https://github.com/LucaMezz/dotfiles) and runs its install script |
| **Wallpapers** | Clones [`LucaMezz/wallpapers`](https://github.com/LucaMezz/wallpapers) into `~/pictures/wallpapers` |
| **LaTeX templates** | Clones [`LucaMezz/latex-templates`](https://github.com/LucaMezz/latex-templates) into `~/.local/share/latex-templates` |

All output is logged to `/tmp/postinstall-<timestamp>.log`. A spinner runs for each step; the final summary reports how many errors occurred and where to find the log.

---

## What's Included

### Official packages (`lists/pacman-packages.txt`)

<details>
<summary>Desktop environment</summary>

| Package | Purpose |
|---|---|
| `hyprland` | Wayland compositor |
| `uwsm` | Universal Wayland session manager |
| `sddm` | Display manager |
| `waybar` | Status bar |
| `dunst` | Notification daemon |
| `rofi` / `wofi` | Application launchers |
| `hyprpaper` | Wallpaper daemon |
| `grim` / `slurp` | Screenshot tools |
| `wl-clipboard` | Wayland clipboard |
| `xdg-desktop-portal-hyprland` | XDG portal for Hyprland |
| `xdg-utils` | XDG utilities |
| `qt5-wayland` / `qt6-wayland` | Qt Wayland backends |
| `polkit-kde-agent` | Polkit authentication agent |
| `network-manager-applet` | NetworkManager tray applet |
| `pavucontrol` | PulseAudio/PipeWire volume control |

</details>

<details>
<summary>Audio</summary>

| Package | Purpose |
|---|---|
| `wireplumber` | PipeWire session manager |
| `pipewire-pulse` | PulseAudio compatibility layer |
| `pipewire-alsa` | ALSA compatibility layer |

</details>

<details>
<summary>Terminal & shell</summary>

| Package | Purpose |
|---|---|
| `kitty` | GPU-accelerated terminal |
| `zsh` | Shell |
| `zsh-autosuggestions` | Fish-style autosuggestions |
| `zsh-syntax-highlighting` | Syntax highlighting |
| `zoxide` | Smarter `cd` |
| `thefuck` | Command correction |
| `keychain` | SSH/GPG key manager |

</details>

<details>
<summary>Editors</summary>

| Package | Purpose |
|---|---|
| `neovim` | Primary editor |
| `vim` | Fallback editor |
| `nano` | Minimal fallback |

</details>

<details>
<summary>CLI utilities</summary>

| Package | Purpose |
|---|---|
| `bat` | `cat` with syntax highlighting |
| `eza` | Modern `ls` |
| `fd` | Fast `find` |
| `fzf` | Fuzzy finder |
| `procs` | Modern `ps` |
| `btop` / `htop` | System monitors |
| `duf` | Modern `df` |
| `tree` | Directory tree |
| `fastfetch` | System info display |
| `glow` | Terminal Markdown renderer |
| `httpie` | User-friendly HTTP client |
| `jq` / `yq` | JSON/YAML processors |
| `imagemagick` | Image manipulation |
| `tealdeer` | Fast `tldr` client |
| `smartmontools` | Disk health monitoring |
| `stow` | Symlink manager (dotfiles) |
| `unzip` / `wget` | Extraction and download |
| `matugen` | Material You colour generator |

</details>

<details>
<summary>Development</summary>

| Package | Purpose |
|---|---|
| `git` / `lazygit` / `git-delta` | Git and its tooling |
| `github-cli` | GitHub CLI |
| `rustup` | Rust toolchain manager |
| `jdk-openjdk` | Java development kit |
| `nvm` | Node version manager |
| `docker` / `docker-compose` | Container runtime |
| `cmake` / `ninja` | Build systems |
| `postgresql-libs` | PostgreSQL client libraries |

</details>

<details>
<summary>File manager & document viewing</summary>

| Package | Purpose |
|---|---|
| `dolphin` | GUI file manager |
| `yazi` | Terminal file manager |
| `zathura` + `zathura-pdf-mupdf` | Minimal PDF viewer |

</details>

<details>
<summary>LaTeX</summary>

`texlive-basic`, `texlive-binextra`, `texlive-fontsrecommended`, `texlive-latex`, `texlive-latexextra`, `texlive-latexrecommended`, `texlive-mathscience`, `texlive-pictures`

</details>

<details>
<summary>Fonts & GPU</summary>

| Package | Purpose |
|---|---|
| `ttf-jetbrains-mono-nerd` | Primary font (Nerd Font patched) |
| `nvidia-open` | NVIDIA open kernel module |
| `libva-nvidia-driver` | NVIDIA VA-API driver |

</details>

### AUR packages (`lists/aur-packages.txt`)

| Package | Purpose |
|---|---|
| `yay` | AUR helper (bootstrapped separately) |
| `aylurs-gtk-shell-git` | AGS v2 — desktop shell framework |
| `libastal-gjs-git` / `libastal-hyprland-git` / `libastal-meta` | Astal libraries for AGS |
| `walker` | Application launcher |
| `elephant` / `elephant-desktopapplications` | Desktop application framework |

### Flatpak apps (`lists/flatpak-apps.txt`)

| App ID | App |
|---|---|
| `app.zen_browser.zen` | Zen Browser |

### System services (`lists/enabled-system-services.txt`)

`docker`, `NetworkManager` (+ dispatcher + wait-online), `ollama`, `sddm`, `systemd-timesyncd`, `ufw`

### User services (`lists/enabled-user-services.txt`)

`pipewire`, `pipewire-pulse`, `wireplumber`

---

## Repository Structure

```
mezzarch/
├── archinstall-configs/
│   └── user_configuration.json     # archinstall profile (disk, locale, bootloader, GPU, etc.)
├── lists/
│   ├── pacman-packages.txt          # Official repository packages
│   ├── aur-packages.txt             # AUR packages
│   ├── flatpak-apps.txt             # Flatpak application IDs
│   ├── enabled-system-services.txt  # systemctl system-level services to enable
│   ├── enabled-user-services.txt    # systemctl user-level services to enable
│   ├── npm-global-packages.txt      # Global npm packages (reference snapshot)
│   └── pnpm-global-packages.txt     # Global pnpm packages (reference snapshot)
├── scripts/
│   └── update-lists.sh             # Snapshots installed packages/services to lists/
├── install.sh                       # Phase 1: run from live ISO as root
├── postinstall.sh                   # Phase 2: run after first boot as regular user
├── post-install-notes.md            # Manual steps and reminders
└── LICENSE
```

---

## Keeping Lists Up to Date

After changing packages or services on a running system, update the snapshot lists by running:

```bash
bash scripts/update-lists.sh
```

This overwrites all files in `lists/` with the current state of the system: `pacman -Qqen`, `pacman -Qqem`, `flatpak list`, enabled system and user services, and global npm/pnpm packages. Commit the result to keep the repo in sync.

---

## Related Repositories

| Repository | Purpose |
|---|---|
| [`LucaMezz/dotfiles`](https://github.com/LucaMezz/dotfiles) | All configuration files, managed with GNU Stow |
| [`LucaMezz/wallpapers`](https://github.com/LucaMezz/wallpapers) | Wallpaper collection, cloned to `~/pictures/wallpapers` |
| [`LucaMezz/latex-templates`](https://github.com/LucaMezz/latex-templates) | LaTeX document templates, cloned to `~/.local/share/latex-templates` |

---

## License

This repository is released under the [MIT License](LICENSE). It is a personal configuration — use it freely as a reference or starting point for your own setup.
