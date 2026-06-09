#!/usr/bin/env bash
# postinstall.sh — Arch Linux post-install setup (run as your regular user after first boot)

set -uo pipefail

# ── Constants ─────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_REPO="https://github.com/LucaMezz/dotfiles.git"
DOTFILES_DIR="$HOME/dotfiles"
WALLPAPERS_REPO="https://github.com/LucaMezz/wallpapers.git"
WALLPAPERS_DIR="${XDG_PICTURES_DIR:-$HOME/pictures}/wallpapers"
LATEX_TEMPLATES_REPO="https://github.com/LucaMezz/latex-templates.git"
LATEX_TEMPLATES_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/latex-templates"
LOG_FILE="/tmp/postinstall-$(date +%Y%m%d-%H%M%S).log"
ERRORS=0
SPINNER_PID=""
SUDO_PID=""
SPINNER_FRAMES=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')

# ── Styling ───────────────────────────────────────────────────────────────────
RS=$'\033[0m'; BD=$'\033[1m'; DM=$'\033[2m'
RD=$'\033[31m'; GR=$'\033[32m'; YL=$'\033[33m'; BL=$'\033[34m'; CY=$'\033[36m'

# ── Logging ───────────────────────────────────────────────────────────────────
: > "$LOG_FILE"
_log() { printf '[%s] %s\n' "$(date '+%H:%M:%S')" "$*" >> "$LOG_FILE"; }

# ── Display ───────────────────────────────────────────────────────────────────
banner() {
    clear
    printf "${BD}${CY}"
    echo "  ╭──────────────────────────────────────────────────────────╮"
    echo "  │                                                          │"
    echo "  │         Arch Linux Post-Install  ·  postinstall.sh       │"
    printf "  │  %-58s│\n" "  $(date '+%A, %d %B %Y')"
    echo "  │                                                          │"
    echo "  ╰──────────────────────────────────────────────────────────╯"
    printf "${RS}\n"
    printf "  ${DM}Log → %s${RS}\n" "$LOG_FILE"
}

section() {
    echo
    printf "  ${BD}${BL}┌─ ${CY}%s${RS}\n" "$1"
}

_row()  { printf "  ${DM}│${RS}  %s\n" "$1"; }
ok()    { _row "${GR}✓${RS} $1";          _log "OK:   $1"; }
fail()  { _row "${RD}✗${RS} $1";          _log "FAIL: $1"; ERRORS=$((ERRORS + 1)); }
warn()  { _row "${YL}⚠${RS} $1";          _log "WARN: $1"; }
info()  { _row "${CY}›${RS} ${DM}$1${RS}"; _log "INFO: $1"; }
skip()  { _row "${DM}− $1 (skipped)${RS}"; _log "SKIP: $1"; }

# ── Spinner ───────────────────────────────────────────────────────────────────
_spinner() {
    local msg="$1" i=0
    while true; do
        printf "\r  ${DM}│${RS}  ${CY}%s${RS} %s..." "${SPINNER_FRAMES[$i]}" "$msg"
        i=$(( (i + 1) % 10 ))
        sleep 0.08
    done
}

# spin_run <label> <command...>
# Runs a command with a spinner, logging all output. Tracks failures.
spin_run() {
    local msg="$1"; shift
    _spinner "$msg" &
    SPINNER_PID=$!
    local rc=0
    "$@" >> "$LOG_FILE" 2>&1 || rc=$?
    kill "$SPINNER_PID" 2>/dev/null
    wait "$SPINNER_PID" 2>/dev/null || true
    printf "\r\033[K"
    SPINNER_PID=""
    if [[ $rc -eq 0 ]]; then ok "$msg"; else fail "$msg"; fi
    return $rc
}

# ── Cleanup on exit ───────────────────────────────────────────────────────────
_cleanup() {
    [[ -n "$SPINNER_PID" ]] && { kill "$SPINNER_PID" 2>/dev/null; printf "\r\033[K"; } || true
    [[ -n "$SUDO_PID"    ]] && kill "$SUDO_PID"    2>/dev/null || true
}
trap '_cleanup' EXIT INT TERM

# ── Parse package/service lists (strips blank lines and # comments) ───────────
read_list() { grep -v '^\s*#' "$1" 2>/dev/null | grep -v '^\s*$' || true; }

# ═══════════════════════════════════════════════════════════════════════════════
#  SECTIONS
# ═══════════════════════════════════════════════════════════════════════════════

do_preflight() {
    section "Pre-flight"

    if [[ $EUID -eq 0 ]]; then
        fail "Do not run this script as root — run as your regular user"
        exit 1
    fi
    ok "Running as user: ${BD}$USER${RS}"

    if [[ -f /etc/arch-release ]]; then
        ok "Arch Linux detected"
    else
        warn "Not detected as Arch Linux — proceeding anyway"
    fi

    info "Requesting sudo credentials (you will not be prompted again)"
    if ! sudo -v 2>/dev/null; then
        fail "sudo authentication failed"
        exit 1
    fi
    ok "Authenticated — sudo credentials cached"

    # Keep sudo alive in the background for the duration of the script
    ( while true; do sudo -v 2>/dev/null; sleep 50; done ) &
    SUDO_PID=$!
}

do_system_update() {
    section "System Update"
    spin_run "Refreshing package databases" sudo pacman -Sy --noconfirm
}

do_pacman_packages() {
    section "Official Packages"
    local list="$SCRIPT_DIR/lists/pacman-packages.txt"

    if [[ ! -f "$list" ]]; then
        fail "Package list not found: $list"
        return
    fi

    local pkgs
    mapfile -t pkgs < <(read_list "$list")
    info "${#pkgs[@]} packages listed — installing missing ones"

    spin_run "Installing official packages" \
        sudo pacman -S --needed --noconfirm "${pkgs[@]}"
}

do_aur_helper() {
    section "AUR Helper"

    if command -v yay &>/dev/null; then
        skip "yay already installed"
        return
    fi

    local tmp
    tmp=$(mktemp -d)

    spin_run "Cloning yay from AUR" \
        git clone https://aur.archlinux.org/yay.git "$tmp/yay"

    spin_run "Building and installing yay" \
        bash -c "cd '$tmp/yay' && makepkg -si --noconfirm"

    rm -rf "$tmp"
}

do_aur_packages() {
    section "AUR Packages"
    local list="$SCRIPT_DIR/lists/aur-packages.txt"

    if [[ ! -f "$list" ]]; then
        warn "AUR package list not found: $list"
        return
    fi

    # Exclude yay itself — already handled above
    local pkgs
    mapfile -t pkgs < <(read_list "$list" | grep -vxE 'yay|yay-debug')

    if [[ ${#pkgs[@]} -eq 0 ]]; then
        ok "No additional AUR packages to install"
        return
    fi

    info "${#pkgs[@]} AUR packages listed — installing missing ones"
    spin_run "Installing AUR packages" \
        yay -S --needed --noconfirm "${pkgs[@]}"
}

do_flatpak() {
    section "Flatpak"

    spin_run "Adding Flathub remote" \
        sudo flatpak remote-add --if-not-exists flathub \
            https://dl.flathub.org/repo/flathub.flatpakrepo

    local list="$SCRIPT_DIR/lists/flatpak-apps.txt"
    if [[ ! -f "$list" ]]; then
        warn "Flatpak app list not found: $list"
        return
    fi

    while IFS= read -r app; do
        if flatpak info "$app" &>/dev/null; then
            skip "$app"
        else
            spin_run "Installing $app" \
                flatpak install --noninteractive flathub "$app" || true
        fi
    done < <(read_list "$list")
}

do_system_services() {
    section "System Services"
    local list="$SCRIPT_DIR/lists/enabled-system-services.txt"

    if [[ ! -f "$list" ]]; then
        warn "System services list not found: $list"
        return
    fi

    while IFS= read -r svc; do
        spin_run "Enabling $svc" sudo systemctl enable "$svc" || true
    done < <(read_list "$list")
}

do_user_services() {
    section "User Services"
    local list="$SCRIPT_DIR/lists/enabled-user-services.txt"

    if [[ ! -f "$list" ]]; then
        warn "User services list not found: $list"
        return
    fi

    local uid
    uid=$(id -u)

    # Enable linger so user services can run without an active login session.
    sudo loginctl enable-linger "$USER" >> "$LOG_FILE" 2>&1 || true

    if [[ ! -d "/run/user/$uid" ]]; then
        warn "No active user systemd session detected — user services may only start after next login"
    fi

    while IFS= read -r svc; do
        spin_run "Enabling $svc" \
            env XDG_RUNTIME_DIR="/run/user/$uid" systemctl --user enable "$svc" || true
    done < <(read_list "$list")
}

do_shell() {
    section "Default Shell"

    local zsh_path
    zsh_path=$(command -v zsh 2>/dev/null || true)

    if [[ -z "$zsh_path" ]]; then
        fail "zsh not found — skipping shell configuration"
        return
    fi

    if [[ "${SHELL:-}" == "$zsh_path" ]]; then
        skip "zsh is already the default shell"
    else
        spin_run "Setting zsh as default shell for $USER" \
            sudo chsh -s "$zsh_path" "$USER"
    fi
}

do_dotfiles() {
    section "Dotfiles"

    if [[ -d "$DOTFILES_DIR/.git" ]]; then
        skip "Dotfiles repo already exists at $DOTFILES_DIR"
        spin_run "Pulling latest dotfiles" git -C "$DOTFILES_DIR" pull || true
    else
        spin_run "Cloning dotfiles from GitHub" \
            git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
    fi

    local install_script="$DOTFILES_DIR/scripts/install.sh"
    if [[ -f "$install_script" ]]; then
        chmod +x "$install_script"
        spin_run "Running dotfiles install script" bash "$install_script"
    else
        warn "Install script not found at $DOTFILES_DIR/scripts/install.sh"
    fi
}

do_wallpapers() {
    section "Wallpapers"

    if [[ -d "$WALLPAPERS_DIR/.git" ]]; then
        skip "Wallpapers repo already exists at $WALLPAPERS_DIR"
        spin_run "Pulling latest wallpapers" git -C "$WALLPAPERS_DIR" pull || true
    else
        mkdir -p "$(dirname "$WALLPAPERS_DIR")"
        spin_run "Cloning wallpapers from GitHub" \
            git clone "$WALLPAPERS_REPO" "$WALLPAPERS_DIR"
    fi
}

do_latex_templates() {
    section "LaTeX Templates"

    if [[ -d "$LATEX_TEMPLATES_DIR/.git" ]]; then
        skip "LaTeX templates repo already exists at $LATEX_TEMPLATES_DIR"
        spin_run "Pulling latest LaTeX templates" git -C "$LATEX_TEMPLATES_DIR" pull || true
    else
        mkdir -p "$LATEX_TEMPLATES_DIR"
        spin_run "Cloning LaTeX templates from GitHub" \
            git clone "$LATEX_TEMPLATES_REPO" "$LATEX_TEMPLATES_DIR"
    fi
}

do_summary() {
    echo
    if [[ $ERRORS -eq 0 ]]; then
        printf "${BD}${GR}"
        echo "  ╭──────────────────────────────────────────────────────────╮"
        echo "  │                                                          │"
        echo "  │   All done — no errors detected!                         │"
        echo "  │   Reboot to apply all changes.                           │"
        echo "  │                                                          │"
        echo "  ╰──────────────────────────────────────────────────────────╯"
        printf "${RS}\n"
    else
        printf "${BD}${YL}"
        echo "  ╭──────────────────────────────────────────────────────────╮"
        printf "  │  %-58s│\n" ""
        printf "  │  %-58s│\n" "  Completed with $ERRORS error(s)"
        printf "  │  %-58s│\n" "  Check the log for details:"
        printf "  │  %-58s│\n" "  $LOG_FILE"
        printf "  │  %-58s│\n" ""
        echo "  ╰──────────────────────────────────────────────────────────╯"
        printf "${RS}\n"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
#  MAIN
# ═══════════════════════════════════════════════════════════════════════════════
main() {
    banner
    do_preflight
    do_system_update
    do_pacman_packages
    do_aur_helper
    do_aur_packages
    do_flatpak
    do_system_services
    do_user_services
    do_shell
    do_dotfiles
    do_wallpapers
    do_latex_templates
    do_summary
}

main "$@"
