# ISO Arch + KDE Plasma pour Surface Go 2

## Construire l'ISO (sur le portable CachyOS)

```bash
tar xzf surface-iso.tar.gz && cd surface-iso
sudo ./build.sh
```

Option expérimentale (noyau linux-surface aussi dans le live, pour avoir clavier/tactile dès l'installateur) :

```bash
sudo ./build.sh --surface-live
```

L'ISO sort dans `out/`. Flashe-la (Rufus en mode DD, Etcher, ou `dd`).

## Installer sur la Surface

1. UEFI (Volume Haut + Power) : Secure Boot = Disabled.
2. Boot sur la clé : Volume Bas + Power.
3. Internet : Ethernet via hub, ou `iwctl` pour le Wi-Fi.
4. Tape `install-surface`, choisis le disque, tape OUI, renseigne user + mot de passe.
5. `reboot`, retire la clé, choisis la session **Plasma (Wayland)** au login.

## Ce que ça installe

- Arch minimal + KDE Plasma (plasma-desktop, sddm, konsole, dolphin, firefox) + NetworkManager
- Noyau `linux-surface`, GRUB (tactile et stylet ELAN de la Go 2 gérés nativement, sans `iptsd`)
- zram zstd réglé (swappiness 180), Baloo et recherche de fichiers KRunner désactivés, animations instantanées, flou désactivé
- Pas de notificateur Discover, d'accessibilité (kaccess) ni de menu global GTK au démarrage ; Firefox limité à 2 processus
- Gestion d'énergie : power-profiles-daemon (profils batterie de KDE) + thermald
- Clavier virtuel aussi sur l'écran de connexion (Plasma Keyboard lancé par KWin)
- Kate, Ark, Spectacle, Centre d'informations
- Applis : Firefox (fr), Jellyfin Desktop et Spotify (Flatpak), Claude (AUR `claude-desktop`, appli officielle). Échec non bloquant si le réseau coince
- Mises à jour : notification quotidienne (timer léger, sans Discover), commande `maj` (pacman + AUR + Flatpak) et lanceur « Mettre à jour le système » dans le menu ; un hook pacman réinstalle GRUB quand `grub` est mis à jour
- Stylet MPP (Milikilo F97 et équivalents) : aucun appairage, pas de Bluetooth, donc pas de batterie du stylet dans KDE. Appui long sur le bouton du haut 1 s pour l'allumer (voyant vert). Pointeur et pression passent par le tactile ELAN ; les boutons du stylet sont encore à diagnostiquer (voir NOTES.md §11)
- Journal de l'installation : `/var/log/install-surface.log`
- Moniteur système KDE (plasma-systemmonitor) + btop
- Installer des logiciels : **Discover** (store KDE, pacman + Flatpak/Flathub), `yay -S nom` pour l'AUR, `sudo pacman -S nom`
- Clavier virtuel Plasma Keyboard (préactivé), rotation auto (iio-sensor-proxy)
- Fuseau Europe/Paris, locale fr_FR, clavier fr, root verrouillé (sudo pour l'utilisateur)

## Surface déjà installée

Pour récupérer les ajouts sans réinstaller : clone le dépôt sur la Surface puis `sudo bash appliquer-sur-surface.sh`.

## Si ça coince

- Wi-Fi : la Go 2 testée a une puce Intel AX200 (`iwlwifi`, dans `linux-firmware`), rien à ajouter
- Clavier virtuel qui n'apparaît pas : Paramètres > Clavier > Clavier virtuel > choisir Plasma Keyboard
- Wiki : https://github.com/linux-surface/linux-surface/wiki
