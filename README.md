# ISO Arch + KDE Plasma pour Surface Go 2

## Construire l'ISO (sur le portable CachyOS ou directement sur la Surface)

```bash
tar xzf surface-iso.tar.gz && cd surface-iso
sudo ./build.sh
```

Option expérimentale (noyau linux-surface aussi dans le live, pour avoir clavier/tactile dès l'installateur) :

```bash
sudo ./build.sh --surface-live
```

Avant le build : `sudo pacman -Syu`. Il faut environ 10 Go libres ; le travail se fait dans `/var/tmp` (pas `/tmp`, qui est en RAM). Sur la Surface le build est plus long qu'à partir du portable.

L'ISO sort dans `out/`. Flashe-la (Rufus en mode DD, Etcher, ou `dd`).

## Télécharger l'ISO toute prête

Les versions publiées sont dans les **Releases** du dépôt (ISO + `SHA256SUMS`). Vérifier : `sha256sum -c SHA256SUMS`.
Elles sont construites automatiquement par GitHub (`.github/workflows/build-iso.yml`). Pour publier : onglet **Actions** > « Construire l'ISO » > **Run workflow**, remplis « version » (ex. `1.2.0`). Autre possibilité : pousser un tag de version (`1.2.0`) publie une release, un tag avec tiret (`1.2.0-beta1`) une pré-release.

## Installer sur la Surface

1. UEFI (Volume Haut + Power) : Secure Boot = Disabled.
2. Boot sur la clé : Volume Bas + Power.
3. Internet : Ethernet via hub, ou `iwctl` pour le Wi-Fi.
4. Tape `install-surface`, choisis le disque, tape OUI, renseigne user + mot de passe, puis réponds à la question du chiffrement (optionnel : il faudra alors le Type Cover ou un clavier USB à chaque démarrage).
5. `reboot`, retire la clé, choisis la session **Plasma (Wayland)** au login.

## Ce que ça installe

- Arch minimal + KDE Plasma (plasma-desktop, sddm, konsole, dolphin, Falkon) + NetworkManager
- Noyau `linux-surface`, GRUB (tactile et stylet ELAN de la Go 2 gérés nativement, sans `iptsd`)
- zram zstd réglé (swappiness 180), Baloo et recherche de fichiers KRunner désactivés, animations instantanées, flou désactivé
- Pas de notificateur Discover, d'accessibilité (kaccess) ni de menu global GTK au démarrage
- Gestion d'énergie : power-profiles-daemon (profils batterie de KDE) + thermald
- Clavier virtuel aussi sur l'écran de connexion (Plasma Keyboard lancé par KWin)
- Kate, Ark, Spectacle, Centre d'informations
- Décodage vidéo matériel Intel (`intel-media-driver`, VA-API) pour Falkon et les vidéos
- Chiffrement LUKS2 du disque en option à l'installation
- Applis : Falkon (navigateur KDE léger, bloqueur de pub intégré), Discord (dépôt Arch), Xournal++ (notes au stylet), Krita (dessin), Jellyfin Desktop et Spotify (Flatpak), Claude (AUR `claude-desktop`, appli officielle). Échec non bloquant si le réseau coince
- Mises à jour : icône dans la zone de notification qui n'apparaît que s'il y a des mises à jour (un clic lance `maj`), notification quotidienne (timer léger, sans Discover), commande `maj` (pacman + AUR + Flatpak) et lanceur « Mettre à jour le système » dans le menu ; un hook pacman réinstalle GRUB quand `grub` est mis à jour
- Stylet MPP (Milikilo F97 et équivalents) : aucun appairage, pas de Bluetooth, donc pas de batterie du stylet dans KDE. Appui long sur le bouton du haut 1 s pour l'allumer (voyant vert). Pointeur et pression passent par le tactile ELAN ; les boutons du stylet sont encore à diagnostiquer (voir NOTES.md §11)
- Journal de l'installation : `/var/log/install-surface.log`
- Moniteur système KDE (plasma-systemmonitor) + btop
- Installer des logiciels : **Discover** (store KDE, pacman + Flatpak/Flathub), `yay -S nom` pour l'AUR, `sudo pacman -S nom`
- Clavier virtuel Plasma Keyboard (préactivé), rotation auto (iio-sensor-proxy)
- Fuseau Europe/Paris, locale fr_FR, clavier fr, root verrouillé (sudo pour l'utilisateur)

## Secure Boot (optionnel)

GRUB est installé prêt pour Secure Boot. Pour l'activer, après l'installation :

1. Laisse Secure Boot **désactivé** dans l'UEFI (sur Surface, c'est le mode qui permet d'inscrire des clés).
2. Lance `activer-secure-boot` : il crée tes clés, les inscrit avec celles de Microsoft, signe GRUB et le noyau.
3. UEFI (Volume Haut + Power) > Sécurité > active Secure Boot, redémarre.

Les mises à jour re-signent tout automatiquement (hook sbctl). Si la tablette refuse de démarrer, désactive Secure Boot dans l'UEFI. Ne supprime jamais `/var/lib/sbctl`.

## Surface déjà installée

Pour récupérer les ajouts sans réinstaller : clone le dépôt sur la Surface puis `sudo bash appliquer-sur-surface.sh`.

## Si ça coince

- Wi-Fi : la Go 2 testée a une puce Intel AX200 (`iwlwifi`, dans `linux-firmware`), rien à ajouter
- Clavier virtuel qui n'apparaît pas : Paramètres > Clavier > Clavier virtuel > choisir Plasma Keyboard
- Wiki : https://github.com/linux-surface/linux-surface/wiki
