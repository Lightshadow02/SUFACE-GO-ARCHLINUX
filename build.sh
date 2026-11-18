#!/bin/bash
# Construit l'ISO Arch pour Surface Go 2 (à lancer sur Arch/CachyOS, en root).
#   sudo ./build.sh                 -> ISO standard (noyau Arch dans le live)
#   sudo ./build.sh --surface-live  -> (expérimental) noyau linux-surface aussi dans le live
# Le système INSTALLÉ utilise toujours linux-surface.
set -euo pipefail

SURFACE_LIVE=0
[[ ${1:-} == --surface-live ]] && SURFACE_LIVE=1

[[ $EUID -eq 0 ]] || { echo "Lance avec sudo : sudo ./build.sh"; exit 1; }

HERE=$(cd "$(dirname "$0")" && pwd)
PROFILE=$HERE/build/profile
# Dossier de travail sur le disque (/tmp est en RAM sur Arch : trop petit avec 4 Go)
# Changeable : sudo env WORK=/autre/dossier ./build.sh
WORK=${WORK:-/var/tmp/surface-iso-work}
OUT=$HERE/out
KEY_ID=56C464BAAC421453
KEY_URL=https://raw.githubusercontent.com/linux-surface/linux-surface/master/pkg/keys/surface.asc

command -v mkarchiso >/dev/null || pacman -S --needed --noconfirm archiso

# Place libre : il faut environ 10 Go pour le dossier de travail + l'ISO
mkdir -p "$(dirname "$WORK")"
LIBRE=$(df --output=avail -BG "$(dirname "$WORK")" | tail -1 | tr -dc 0-9)
(( LIBRE >= 10 )) || echo "ATTENTION : seulement ${LIBRE} Go libres pour $WORK, le build risque d'échouer."
[[ -d /usr/share/archiso/configs/releng ]] || { echo "Profil releng introuvable (paquet archiso)."; exit 1; }

rm -rf "$HERE/build" "$WORK"
mkdir -p "$HERE/build" "$OUT"
cp -r /usr/share/archiso/configs/releng "$PROFILE"

# --- Overlay (installateur, motd, clavier fr) ---
cp -r "$HERE/overlay/airootfs/." "$PROFILE/airootfs/"
mkdir -p "$PROFILE/airootfs/usr/share/surface"
curl -fsSL "$KEY_URL" -o "$PROFILE/airootfs/usr/share/surface/surface.asc"

cat >> "$PROFILE/packages.x86_64" <<'EOF'
gptfdisk
dosfstools
e2fsprogs
arch-install-scripts
EOF

sed -i 's/^iso_name=.*/iso_name="arch-surface"/' "$PROFILE/profiledef.sh"
echo 'file_permissions+=(["/usr/local/bin/install-surface"]="0:0:755")' >> "$PROFILE/profiledef.sh"

# --- Option : noyau linux-surface dans le live (clavier/tactile dès l'installateur) ---
if (( SURFACE_LIVE )); then
  echo "== Mode live linux-surface (expérimental) =="
  pacman-key --add "$PROFILE/airootfs/usr/share/surface/surface.asc"
  pacman-key --lsign-key "$KEY_ID"
  printf '\n[linux-surface]\nServer = https://pkg.surfacelinux.com/arch/\n' >> "$PROFILE/pacman.conf"

  sed -i '/^linux$/d' "$PROFILE/packages.x86_64"
  echo linux-surface >> "$PROFILE/packages.x86_64"

  PRESET_DIR=$PROFILE/airootfs/etc/mkinitcpio.d
  sed 's/vmlinuz-linux/vmlinuz-linux-surface/g; s/initramfs-linux/initramfs-linux-surface/g' \
    "$PRESET_DIR/linux.preset" > "$PRESET_DIR/linux-surface.preset"
  rm -f "$PRESET_DIR/linux.preset"

  grep -rlE 'vmlinuz-linux|initramfs-linux' "$PROFILE"/{syslinux,grub,efiboot} 2>/dev/null | while read -r f; do
    sed -i 's/vmlinuz-linux\b/vmlinuz-linux-surface/g; s/initramfs-linux\.img/initramfs-linux-surface.img/g' "$f"
  done
fi

# --- Build ---
mkarchiso -v -w "$WORK" -o "$OUT" "$PROFILE"
rm -rf "$WORK"

echo
echo "ISO prête :"
ls -lh "$OUT"/*.iso
echo "Flashe-la avec : sudo dd if=$OUT/arch-surface-*.iso of=/dev/sdX bs=4M status=progress oflag=sync"
echo "(vérifie bien /dev/sdX avec lsblk avant !)"
