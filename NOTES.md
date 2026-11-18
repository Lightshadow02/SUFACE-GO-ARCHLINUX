# Notes du projet Surface Go 2 (Arch + KDE Plasma) : 12/11/2026

## 1. Où on en est
- Matériel : Surface Go 2, 4 Go de RAM, eMMC interne 58 Go (`/dev/mmcblk0`). Windows a été effacé.
- Première install faite avec l'ISO v1 + un patch à chaud dans le live. **Le système démarre et fonctionne.**
- Ce zip contient déjà toutes les corrections. **À faire un jour : rebuild une ISO propre avec ce zip, puis réinstaller la Surface proprement.**
- Réseau pendant l'install : adaptateur USB-RJ45 sur le hub, reconnu directement.
- Clé de boot : SSD/clé Ventoy (`/dev/sda`, 238 Go).

Patch appliqué à chaud sur le live (déjà intégré dans ce zip, rien à refaire) :
```bash
sed -i 's/ libwacom-surface//; s/ maliit-keyboard/ plasma-keyboard/; /InputMethod=\/usr\/share\/applications\/com.github.maliit/d' /usr/local/bin/install-surface
```

## 2. Corrections déjà dans ce zip (par rapport à l'ISO v1)
1. `libwacom-surface` retiré (n'existe plus, intégré à libwacom upstream).
2. `maliit-keyboard` remplacé par `plasma-keyboard` (maliit n'est plus dans les dépôts officiels).
3. Détection du disque de l'ISO corrigée pour Ventoy (la clé/SSD n'était pas exclue de la liste).
4. Entrées `mmcblk0boot0/1` et `rpmb` masquées, affichage `usb` pour les disques externes.
5. Nom d'utilisateur et nom de machine passés automatiquement en minuscules.
6. Ajout de Discover, Flatpak (Flathub), `yay` (AUR), base-devel, git.
7. Écran de connexion : thème SDDM forcé sur Breeze (avant : thème SDDM par défaut). Paquets `breeze` et `sddm-kcm` ajoutés.
8. Moniteur système : `plasma-systemmonitor` et `btop`.
9. Clavier virtuel Plasma Keyboard préactivé (`kwinrc` : `InputMethod=/usr/share/applications/org.kde.plasma.keyboard.desktop`, nom vérifié dans le paquet Arch).

## 3. Fix à chaud pour le système DÉJÀ installé (la v1 ne les a pas)
```bash
# Écran de connexion Breeze
sudo pacman -S --needed breeze sddm-kcm
printf '[Theme]\nCurrent=breeze\nCursorTheme=breeze_cursors\n' | sudo tee /etc/sddm.conf.d/20-theme.conf

# Moniteur système
sudo pacman -S plasma-systemmonitor btop

# Clavier virtuel (aussi possible via Paramètres > Clavier > Clavier virtuel), puis se reconnecter
kwriteconfig6 --file kwinrc --group Wayland --key InputMethod /usr/share/applications/org.kde.plasma.keyboard.desktop
```
Retour du 12/11 : une fois le clavier virtuel activé à la main, tout marche.

## 4. TOUT CE QU'IL RESTE À REVOIR
1. **RAM : 2,1 Go utilisés au repos** (sur 4 Go), plus que prévu. Analyser : `ps aux --sort=-%mem | head -15` ou Moniteur système. Pistes : navigateur ouvert, notificateur de Discover (désactiver dans Démarrage automatique), Baloo (`balooctl6 status`), service bluetooth si inutile, effets de bureau. Cible : ~1,2 à 1,6 Go. Envisager de retirer Discover du kit, ou un bureau plus léger (XFCE/LXQt) en dernier recours.
2. **Clavier virtuel** : vérifier à la réinstall qu'il s'ouvre au toucher d'un champ texte sans rien configurer. Il n'y a **pas de clavier virtuel sur l'écran de connexion SDDM** : mot de passe impossible en tablette seule sans clavier. À étudier.
3. **Wi-Fi** sous le système installé : à tester (saisie du mot de passe avec le clavier virtuel). `linux-firmware-marvell` si absent.
4. **Tactile (iptsd), rotation auto, mode tablette, gestes** : à tester.
5. **Type Cover** (clavier de la Surface) : à tester avec le noyau linux-surface.
6. **Écran de connexion** : thème Breeze forcé dans le zip, à vérifier visuellement.
7. **yay (AUR) et Flathub** : vérifier qu'ils se sont bien installés (leur échec est non bloquant et silencieux).
8. **`--surface-live`** (noyau linux-surface dans le live) : jamais testé.
9. **`copytoram=y`** : utile si la clé doit être retirée (peu de ports USB). Pas testé.
10. **Log d'installation** : ajouter `/var/log/install-surface.log` pour retrouver les erreurs.
11. **Logiciels de base à ajouter ?** `kate`, `ark`, `spectacle`, `kinfocenter` proposés, pas encore décidés.
12. **Réinstaller proprement** avec une ISO reconstruite depuis ce zip.

## 5. SSH temporaire pour gérer la tablette à distance (NON inclus dans l'ISO)
Sur la Surface :
```bash
sudo pacman -S openssh
sudo systemctl enable --now sshd
ip -4 addr        # noter l'adresse 192.168.x.x
```
Depuis le portable CachyOS : `ssh light@192.168.x.x` (ou `ssh-copy-id light@192.168.x.x` pour une clé).

Règles : réseau local seulement, ne jamais ouvrir le port 22 sur la box/Internet.

**À SUPPRIMER quand on a fini :**
```bash
sudo systemctl disable --now sshd
sudo pacman -Rns openssh
```
(et retirer la clé du portable dans `~/.ssh/authorized_keys` de la Surface si elle y est.)

## 6. Rappels pratiques
- Avant le build sur CachyOS : `sudo pacman -Syu` (sinon erreur de signature "Pierre Schmitz").
- Build : `sudo bash build.sh`, puis flasher avec `dd` (bien vérifier `/dev/sdX`) ou Ventoy.
- Boot Surface : UEFI = Volume Haut + Power (Secure Boot Disabled) ; boot USB = Volume Bas + Power.
- À l'install : disque **mmcblk0**, jamais `sda` (SSD Ventoy). Nom d'utilisateur en minuscules.
- Session au login : **Plasma (Wayland)** (le clavier virtuel ne marche qu'en Wayland).

## 7. Corrections du 12/11 (après analyse à distance de la Surface)
Constaté sur la tablette : tactile/stylet = ELAN9038 en HID (pas d'IPTS : `iptsd` inutile), Wi-Fi = Intel AX200 (`linux-firmware-marvell` inutile), capteurs de rotation OK, Flathub et yay OK, **thème SDDM Breeze absent** (le fix du §3 n'avait pas été appliqué), pas de `power-profiles-daemon` (KDE ne pouvait pas changer de profil d'énergie, CPU en `balance_performance`, ~6 W à l'écran pleine luminosité).

Intégré dans `install-surface` :
- RAM : zram avec `vm.swappiness=180` et `page-cluster=0` ; autostart coupés (notificateur Discover, kaccess, menu global GTK) ; recherche de fichiers KRunner coupée ; Firefox à 2 processus de contenu, onglets déchargés si la RAM manque, télémétrie et Pocket coupés.
- Énergie : `power-profiles-daemon` + `thermald` activés.
- Écran de connexion : clavier virtuel lancé par KWin (`--inputmethod /usr/bin/plasma-keyboard` dans CompositorCommand ; qtvirtualkeyboard ne marche pas sous KWin) ; le thème Breeze était déjà dans le script. **À vérifier en tablette seule.**
- Log : `/var/log/install-surface.log`.
- Retirés : `iptsd`, `linux-firmware-marvell`. Ajoutés : `inetutils` (commande `hostname`), `kate ark spectacle kinfocenter`.

Pour le système DÉJÀ installé : `sudo bash ~/surface-reglages.sh` (posé dans le dossier de `light`), puis redémarrer.

Reste à tester : Type Cover (pas branchée pendant l'analyse), mode tablette/gestes, `--surface-live`, `copytoram=y`.

## 8. Validé sur la Surface le 12/11 (soir)
- **Clavier virtuel sur l'écran de connexion : OK.** Ce qui marche : `/var/lib/sddm/.config/kwinrc` avec `[Wayland] InputMethod=/usr/share/applications/org.kde.plasma.keyboard.desktop` (KWin du compte sddm lance Plasma Keyboard) + `InputMethod=` vide dans SDDM. SDDM **ignore** l'option `--inputmethod` de `CompositorCommand`, et `qtvirtualkeyboard` côté écran de connexion ne marche pas sous KWin. Le thème Breeze a aussi un bouton « Clavier virtuel » en bas à gauche.
- **RAM au repos après connexion : 1,53 Go** (contre 2,1 Go), dans la cible.
  - `kaccess` et le menu global GTK sont des **services systemd** sous Plasma 6 : un `Hidden=true` dans l'autostart ne les coupe pas. Solution : `systemctl --global mask plasma-kaccess.service plasma-gmenudbusmenuproxy.service`.
  - Modules kded coupés (`kded6rc`, `autoload=false`) : screenreader, wpad_detector, lookandfeelautoswitcher, appmenu, baloosearchmodule, kded_accounts, donationmessage, remotenotifier, smbwatcher.
- Tout est reporté dans `install-surface`.

## 9. Ajouts (12/11, soir)
- **Énergie** : avec power-profiles-daemon, le CPU passe en `balance_power` ; consommation mesurée **1,2 W** écran tamisé (environ 6 W avant, écran à fond).
- **Pare-feu ufw** activé : tout refusé en entrée, réglable dans Paramètres > Pare-feu (plasma-firewall). Sur la Surface actuelle, une règle temporaire autorise SSH depuis 192.168.0.0/24 : **à supprimer avec sshd** (`sudo ufw delete allow from 192.168.0.0/24 to any port 22 proto tcp`).
- **TRIM** hebdomadaire de l'eMMC (`fstrim.timer`, l'eMMC le supporte) et **cache pacman** limité à 2 versions (`paccache.timer`, pacman-contrib, qui apporte aussi `checkupdates`).
- **Moniteur système sans stockage** : limite de KDE. ksystemstats n'affiche que les disques de type `HardDisk`, et l'eMMC est classée `SdMmc` (plugins/disks/disks.cpp). Rien à régler ; utiliser btop, Dolphin ou Filelight. À signaler sur bugs.kde.org (ksystemstats).
- **Attention** : le disque système de la Surface est `mmcblk1` (et non `mmcblk0`).
- Bluetooth : `Failed to set mode` au démarrage (sans gravité). Si le Bluetooth ne sert pas, `sudo systemctl disable --now bluetooth` libère un peu de RAM et de batterie.

## 10. Dernière série (12/11, nuit) — tout est dans install-surface
- **Moniteur système > stockage : corrigé.** Cause : ksystemstats n'affiche que les disques `HardDisk`, et udisks étiquetait l'eMMC « flash_mmc » (donc `SdMmc` pour KDE). Règle `/etc/udev/rules.d/81-emmc-disque.rules` : retire l'étiquette pour l'eMMC interne (MMC_TYPE=MMC). Les zones de démarrage 4 Mo (boot0/boot1) peuvent encore apparaître comme petits disques bruts (même lecteur udisks), sans gravité.
- **Clavier AZERTY** pour l'interface graphique et SDDM (`/etc/X11/xorg.conf.d/00-keyboard.conf`) + `kxkbrc` de la session.
- **Firefox en français** (`firefox-i18n-fr`, `RequestedLocales`), uBlock Origin forcé.
- **24 effets KWin coupés** (gardés : vue d'ensemble, vue des fenêtres, bords d'écran, kscreen).
- **GRUB** : thème Breeze (`breeze-grub`), menu 3 s, `transparent_hugepage=madvise`. `MALLOC_ARENA_MAX=2` pour la session.
- **Terminal façon CachyOS, en bleu** : fish + fastfetch (logo et clés en bleu) + eza (icônes) + bat (man en couleur), police MesloLGS Nerd Font, profil Konsole « Surface » avec le schéma « Arch bleu ». fish uniquement dans Konsole (bash reste le shell système). Fichiers dans `overlay/airootfs/usr/share/surface/`.
- **Batterie en % dans la barre** : réglé à la main sur la Surface (le panneau est créé à la 1re connexion, pas d'équivalent fiable dans le skel). Batterie « Stylus » à 0 % barrée : batterie du stylet ELAN, UPower 1.91 n'offre pas d'option pour la masquer.
- **Applis** (installées à la main, pas dans l'ISO) : Jellyfin Desktop et Collabora Office (Flatpak), Claude (AUR `claude-desktop`, audité : `.deb` officiel Anthropic, SHA256 identique au dépôt apt d'Anthropic ; `menuBarEnabled=false` pour que fermer la fenêtre quitte l'appli). Client Nextcloud retiré (usage web).
- RAM au repos : ~1,55 Go après connexion. Le reste (plasmashell, KWin, clavier virtuel) est l'incompressible du bureau KDE.

## 11. Mises à jour + stylet (18/11)
- **Stylet Milikilo F97** : protocole MPP, pas de Bluetooth (il s'allume par appui long 1 s sur le bouton du haut). Rien à appairer. **Batterie du stylet dans KDE : impossible avec ce stylet.** L'entrée « Stylus 0 % » vue avant était fantôme : le digitizer ELAN de la Surface Go 2 déclare à tort une batterie de stylet, et le noyau l'ignore depuis 2022 (quirk `HID_BATTERY_QUIRK_IGNORE`), d'où sa disparition. Le voyant du stylet est le seul indicateur.
- **Boutons du stylet : ne répondent pas (18/11), à diagnostiquer sur la Surface.** `sudo libinput debug-events` puis appuyer sur chaque bouton : si des `TABLET_TOOL_BUTTON` apparaissent, le noyau les voit et le souci est côté KWin/Plasma (comportement connu sous Wayland, remappage KCM parfois sans effet) ; sinon c'est côté stylet/noyau.
- **Notification de mises à jour** : `surface-updates-check` (timer utilisateur, 1×/jour, 10 min après la connexion) compte `checkupdates` + `flatpak remote-ls --updates` et envoie une notification Plasma. Aucun téléchargement. Remplace le notificateur Discover (coupé pour la RAM). Paquet ajouté : `libnotify`.
- **`maj`** : pacman -Syu, puis yay -Sua, puis flatpak update, avec message si le noyau a changé (redémarrer). Lanceur dans le menu : « Mettre à jour le système ». L'alias fish `update` existe toujours.
- **Hook pacman `95-grub-update.hook`** : relance grub-install (entrée Arch + removable) et grub-mkconfig quand `grub` est mis à jour, sinon le GRUB installé reste sur l'ancienne version.
- **Pas fait volontairement** : mise à jour automatique sans surveillance (risque de casse sur Arch).
- **À tester sur la Surface** : la notification s'affiche bien ; `maj` depuis le lanceur ; le hook (simuler avec `sudo pacman -S grub` si une réinstallation est possible).
- **Incohérence relevée** : §10 dit « uBlock Origin forcé » mais `policies.json` ne contient pas encore la règle ExtensionSettings.
- **Applis dans l'ISO** : Jellyfin Desktop (`org.jellyfin.JellyfinDesktop`) et Spotify (`com.spotify.Client`) en Flatpak, Claude via `yay -S claude-desktop` (pendant le sudo temporaire de l'install). Firefox était déjà là. Collabora Office reste à la main.
- **`appliquer-sur-surface.sh`** : pose tout ça sur la Surface déjà installée, sans réinstaller.
- **Discord** : paquet `discord` du dépôt officiel Arch (extra), mis à jour par pacman/`maj`.
