#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
systemctl list-unit-files --state=enabled --type=service --no-pager > enabled-system-services.txt

echo "Writing enabled-user-services.txt..."
systemctl --user list-unit-files --state=enabled --type=service --no-pager > enabled-user-services.txt

echo "Done."
