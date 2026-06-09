#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LISTS_DIR="$ROOT_DIR/lists"

mkdir -p "$LISTS_DIR"

echo "Updating package and service lists..."

echo "Writing pacman-packages.txt..."
pacman -Qqen > "$LISTS_DIR/pacman-packages.txt"

echo "Writing aur-packages.txt..."
pacman -Qqem > "$LISTS_DIR/aur-packages.txt"

if command -v flatpak >/dev/null 2>&1; then
    echo "Writing flatpak-apps.txt..."
    flatpak list --app --columns=application > "$LISTS_DIR/flatpak-apps.txt"
else
    echo "Flatpak not installed, writing empty flatpak-apps.txt..."
    : > "$LISTS_DIR/flatpak-apps.txt"
fi

echo "Writing enabled-system-services.txt..."
systemctl list-unit-files \
    --state=enabled \
    --type=service \
    --no-legend \
    --no-pager \
    | awk '{print $1}' \
    > "$LISTS_DIR/enabled-system-services.txt"

echo "Writing enabled-user-services.txt..."
if systemctl --user list-unit-files >/dev/null 2>&1; then
    systemctl --user list-unit-files \
        --state=enabled \
        --type=service \
        --no-legend \
        --no-pager \
        | awk '{print $1}' \
        > "$LISTS_DIR/enabled-user-services.txt"
else
    echo "User systemd is not available, writing empty enabled-user-services.txt..."
    : > "$LISTS_DIR/enabled-user-services.txt"
fi

echo "Writing npm-global-packages.txt..."
if command -v npm >/dev/null 2>&1; then
    npm ls -g --depth=0 --parseable 2>/dev/null \
        | sed '1d' \
        | xargs -r -n1 basename \
        > "$LISTS_DIR/npm-global-packages.txt"
else
    echo "npm not installed, writing empty npm-global-packages.txt..."
    : > "$LISTS_DIR/npm-global-packages.txt"
fi

echo "Writing pnpm-global-packages.txt..."
if command -v pnpm >/dev/null 2>&1; then
    pnpm list -g --depth=0 --parseable 2>/dev/null \
        | sed '1d' \
        | xargs -r -n1 basename \
        > "$LISTS_DIR/pnpm-global-packages.txt"
else
    echo "pnpm not installed, writing empty pnpm-global-packages.txt..."
    : > "$LISTS_DIR/pnpm-global-packages.txt"
fi

echo "Done."
