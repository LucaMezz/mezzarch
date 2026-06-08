#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$ROOT_DIR"

echo "Updating package and service lists..."

echo "Writing pacman-packages.txt..."
pacman -Qqen > pacman-packages.txt

echo "Writing aur-packages.txt..."
pacman -Qqem > aur-packages.txt

if command -v flatpak >/dev/null 2>&1; then
    echo "Writing flatpak-apps.txt..."
    flatpak list --app --columns=application > flatpak-apps.txt
else
    echo "Flatpak not installed, writing empty flatpak-apps.txt..."
    : > flatpak-apps.txt
fi

echo "Writing enabled-system-services.txt..."
systemctl list-unit-files \
    --state=enabled \
    --type=service \
    --no-legend \
    --no-pager \
    | awk '{print $1}' \
    > enabled-system-services.txt

echo "Writing enabled-user-services.txt..."
if systemctl --user list-unit-files >/dev/null 2>&1; then
    systemctl --user list-unit-files \
        --state=enabled \
        --type=service \
        --no-legend \
        --no-pager \
        | awk '{print $1}' \
        > enabled-user-services.txt
else
    echo "User systemd is not available, writing empty enabled-user-services.txt..."
    : > enabled-user-services.txt
fi

echo "Writing npm-global-packages.txt..."
if command -v npm >/dev/null 2>&1; then
    npm ls -g --depth=0 --parseable 2>/dev/null \
        | sed '1d' \
        | xargs -r -n1 basename \
        > npm-global-packages.txt
else
    echo "npm not installed, writing empty npm-global-packages.txt..."
    : > npm-global-packages.txt
fi

echo "Writing pnpm-global-packages.txt..."
if command -v pnpm >/dev/null 2>&1; then
    pnpm list -g --depth=0 --parseable 2>/dev/null \
        | sed '1d' \
        | xargs -r -n1 basename \
        > pnpm-global-packages.txt
else
    echo "pnpm not installed, writing empty pnpm-global-packages.txt..."
    : > pnpm-global-packages.txt
fi

echo "Done."
