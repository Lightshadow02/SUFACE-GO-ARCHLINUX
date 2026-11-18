#!/bin/bash
# Applique les ajouts récents sur une Surface DÉJÀ installée (sans réinstaller).
# Sur la Surface, depuis le dossier du dépôt : sudo bash appliquer-sur-surface.sh
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Lance avec sudo : sudo bash appliquer-sur-surface.sh"; exit 1; }
U=${SUDO_USER:?lance avec sudo depuis ton compte, pas en root direct}
S=$(cd "$(dirname "$0")" && pwd)/overlay/airootfs/usr/share/surface

echo "== Mises à jour : maj, notification, hook GRUB =="
pacman -S --needed --noconfirm libnotify pacman-contrib
install -Dm755 "$S/maj" /usr/local/bin/maj
install -Dm755 "$S/surface-updates-check" /usr/local/bin/surface-updates-check
install -Dm644 "$S/maj.desktop" /usr/share/applications/maj.desktop
install -Dm644 "$S/surface-updates-check.service" /etc/systemd/user/surface-updates-check.service
install -Dm644 "$S/surface-updates-check.timer" /etc/systemd/user/surface-updates-check.timer
install -Dm644 "$S/95-grub-update.hook" /etc/pacman.d/hooks/95-grub-update.hook
systemctl --global enable surface-updates-check.timer

echo "== Applis : Firefox, Jellyfin, Spotify, Claude =="
pacman -S --needed --noconfirm firefox firefox-i18n-fr
flatpak install -y --noninteractive flathub org.jellyfin.JellyfinDesktop com.spotify.Client || echo "Flatpak : échec (réseau ?)"
su - "$U" -c 'yay -S --needed claude-desktop' || echo "Claude : échec, réessaie avec : yay -S claude-desktop"

echo
echo "Terminé. Déconnecte-toi puis reconnecte-toi pour activer la notification des mises à jour."
