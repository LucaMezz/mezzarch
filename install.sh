#!/usr/bin/env bash
# install.sh — Arch Linux installer wrapper (run from the live ISO as root)

set -uo pipefail

# ── Styling ───────────────────────────────────────────────────────────────────
RS=$'\033[0m'; BD=$'\033[1m'; DM=$'\033[2m'
RD=$'\033[31m'; GR=$'\033[32m'; YL=$'\033[33m'; BL=$'\033[34m'; CY=$'\033[36m'

# ── Paths ─────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="$SCRIPT_DIR/archinstall-configs/user_configuration.json"

# ── Helpers ───────────────────────────────────────────────────────────────────
banner() {
    clear
    printf "${BD}${CY}"
    echo "  ╭──────────────────────────────────────────────────────────╮"
    echo "  │                                                          │"
    echo "  │           Arch Linux Installation  ·  install.sh         │"
    echo "  │                                                          │"
    echo "  ╰──────────────────────────────────────────────────────────╯"
    printf "${RS}\n"
}

section() {
    echo
    printf "  ${BD}${BL}┌─ ${RS}${BD}%s${RS}\n" "$1"
}

_row() { printf "  ${DM}│${RS}  %s\n" "$1"; }

ok()   { _row "${GR}✓${RS} $1"; }
fail() { _row "${RD}✗${RS} $1"; }
warn() { _row "${YL}⚠${RS} $1"; }
info() { _row "${CY}›${RS} ${DM}$1${RS}"; }

die() {
    fail "$1"
    echo
    exit 1
}

# ── Pre-flight checks ─────────────────────────────────────────────────────────
banner

section "Pre-flight Checks"

[[ $EUID -eq 0 ]] \
    && ok "Running as root" \
    || die "Must run as root — boot from the Arch live ISO"

command -v archinstall &>/dev/null \
    && ok "archinstall found" \
    || die "archinstall not found — are you on the Arch ISO?"

if ping -c1 -W2 archlinux.org &>/dev/null; then
    ok "Internet connection available"
else
    die "No internet connection — connect before running this script"
fi

[[ -f "$CONFIG" ]] \
    && ok "Config found: $CONFIG" \
    || die "Config not found at: $CONFIG"

# ── Config summary ────────────────────────────────────────────────────────────
section "Configuration Summary"

if command -v jq &>/dev/null; then
    HOSTNAME=$(jq -r '.hostname'                                   "$CONFIG")
    TIMEZONE=$(jq -r '.timezone'                                   "$CONFIG")
    KERNEL=$(jq -r   '.kernels[0]'                                 "$CONFIG")
    BOOTLDR=$(jq -r  '.bootloader_config.bootloader'               "$CONFIG")
    TARGET=$(jq -r   '.disk_config.device_modifications[0].device' "$CONFIG")

    info "Hostname   : ${BD}$HOSTNAME${RS}"
    info "Timezone   : ${BD}$TIMEZONE${RS}"
    info "Kernel     : ${BD}$KERNEL${RS}"
    info "Bootloader : ${BD}$BOOTLDR${RS}"
    info "Target disk: ${BD}${RD}$TARGET${RS}"
else
    warn "jq not installed — skipping config summary"
fi

echo
warn "The config targets ${BD}/dev/sda${RS}${YL} and will ${RD}${BD}ERASE IT ENTIRELY${RS}"
warn "Verify this is correct before proceeding"

echo
_row "Available block devices:"
lsblk -d -o NAME,SIZE,TYPE,MODEL --noheadings 2>/dev/null \
    | awk '/disk/ { printf "  \033[2m│\033[0m    \033[1m%-8s\033[0m  %-8s  %s\n", $1, $2, $4 }'

# ── Confirmation ──────────────────────────────────────────────────────────────
echo
printf "  Type ${BD}yes${RS} to continue or anything else to abort: "
read -r CONFIRM
[[ "$CONFIRM" == "yes" ]] || { printf "\n  ${DM}Aborted.${RS}\n\n"; exit 0; }

# ── Run archinstall ───────────────────────────────────────────────────────────
section "Running archinstall"
info "Handing off to archinstall — follow any remaining prompts"
echo

archinstall --config "$CONFIG"

# ── Done ──────────────────────────────────────────────────────────────────────
echo
printf "${BD}${GR}"
echo "  ╭──────────────────────────────────────────────────────────╮"
echo "  │                                                          │"
echo "  │   Installation complete!                                 │"
echo "  │                                                          │"
echo "  │   Next steps:                                            │"
echo "  │     1.  Reboot into your new Arch system                 │"
echo "  │     2.  Log in as your user                              │"
echo "  │     3.  Clone or copy this repo to your home directory   │"
echo "  │     4.  Run: bash postinstall.sh                         │"
echo "  │                                                          │"
echo "  ╰──────────────────────────────────────────────────────────╯"
printf "${RS}\n"
