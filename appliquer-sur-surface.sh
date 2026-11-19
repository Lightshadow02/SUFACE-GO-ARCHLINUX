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
echo "== Secure Boot : outils (rien n'est activé, lance activer-secure-boot pour ça) =="
pacman -S --needed --noconfirm sbctl
install -Dm755 "$S/surface-grub-install" /usr/local/bin/surface-grub-install
install -Dm755 "$S/activer-secure-boot" /usr/local/bin/activer-secure-boot
rm -rf /usr/share/plasma/plasmoids/org.surface.majsysteme
cp -r "$S/plasmoid-maj" /usr/share/plasma/plasmoids/org.surface.majsysteme
su - "$U" -c '/usr/local/bin/surface-updates-check --silencieux' || true
systemctl --global enable surface-updates-check.timer

echo "== Applis : Falkon, Discord, Xournal++, Krita, Jellyfin, Spotify, Claude + décodage vidéo matériel =="
pacman -S --needed --noconfirm falkon discord xournalpp krita intel-media-driver
flatpak install -y --noninteractive flathub org.jellyfin.JellyfinDesktop com.spotify.Client || echo "Flatpak : échec (réseau ?)"
su - "$U" -c 'yay -S --needed claude-desktop' || echo "Claude : échec, réessaie avec : yay -S claude-desktop"

echo "== Discord : mises à jour laissées à pacman =="
H=$(getent passwd "$U" | cut -d: -f6)
F=$H/.config/discord/settings.json
if [[ ! -s $F ]]; then
  install -d -o "$U" -g "$U" "$H/.config/discord"
  printf '{\n  "SKIP_HOST_UPDATE": true\n}\n' > "$F"
  chown "$U:$U" "$F"
elif ! grep -q SKIP_HOST_UPDATE "$F"; then
  sed -i '0,/{/s//{\n  "SKIP_HOST_UPDATE": true,/' "$F"
fi

if pacman -Q firefox &>/dev/null; then
  echo "Firefox est encore installé (remplacé par Falkon). Pour le retirer : sudo pacman -Rns firefox firefox-i18n-fr"
fi

echo "== Portefeuille KDE : nom par défaut + ouverture auto à la connexion =="
pacman -S --needed --noconfirm kwallet-pam
su - "$U" -c 'kwriteconfig6 --file kwalletrc --group Wallet --key "Default Wallet" kdewallet'

echo
echo "Terminé. Déconnecte-toi puis reconnecte-toi pour activer la notification des mises à jour."
