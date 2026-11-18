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
- **Stylet Milikilo F97** : protocole MPP, pas de Bluetooth (il s'allume par appui long 1 s sur le bouton du haut). Rien à appairer.
- **Batterie du stylet bloquée à 1 % (18/11)** : écran `ELAN9038:00 04F3:2A1C`. Le noyau masquait cette fausse batterie (quirk `HID_BATTERY_QUIRK_IGNORE` dédié à la Go 2), mais le noyau récent a retiré cette entrée au profit d'une règle générale ELAN (`HID_BATTERY_QUIRK_DYNAMIC` : batterie affichée dès que le stylet donne signe de vie). D'où le 1 % dès qu'on utilise le stylet. Rien de propre à faire côté ISO (ni UPower ni Plasma ne permettent de masquer un appareil). Signalement prêt dans `docs/signalement-batterie-stylet.md`, à poster sur l'issue tracker de linux-surface. Le voyant du stylet reste le seul indicateur fiable.
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

## 12. CE QUI MANQUE ENCORE (à jour au 18/11)
Stylet
1. **Boutons du stylet sans effet.** Diagnostic : `sudo pacman -S libinput-tools` puis `sudo libinput debug-events`, stylet posé, appuyer sur chaque bouton. Des lignes `TABLET_TOOL_BUTTON` → souci KWin/Plasma (remappage possible) ; rien → souci stylet/noyau.
2. **Batterie du stylet à 1 %.** Vient du noyau (officiel et linux-surface 7.1 à 7.3 vérifiés), pas de l'ISO. Poster `docs/signalement-batterie-stylet.md` sur l'issue tracker linux-surface. Envisager `libinput-tools` dans l'ISO pour le diagnostic.

À tester sur la Surface
3. Notification quotidienne des mises à jour, commande `maj` et son lanceur, hook GRUB.
4. Installation dans le chroot de Jellyfin/Spotify (Flatpak), Claude (yay) et Discord.
5. `appliquer-sur-surface.sh` sur la tablette déjà installée.
6. Type Cover, mode tablette et gestes, `--surface-live`, `copytoram=y` (jamais testés).

À corriger / nettoyer
7. ~~uBlock Origin absent de `policies.json`~~ : sans objet, Firefox remplacé par Falkon (§19).
8. Retirer sshd et la règle ufw temporaire (§5 et §9) quand l'administration à distance est finie.
9. Réinstaller proprement la Surface avec une ISO reconstruite depuis la branche fusionnée.

## 13. Applis qui ne se mettent pas à jour (18/11)
- **Discord** (paquet Arch) bloque au démarrage quand le dépôt a un temps de retard sur Discord. Corrigé : `"SKIP_HOST_UPDATE": true` dans `~/.config/discord/settings.json` (skel de l'ISO + `appliquer-sur-surface.sh`), pacman fait les mises à jour.
- **Claude** (AUR) : Discover ne gère pas l'AUR, seul `yay` (donc `maj`) le met à jour. La notification compte maintenant aussi l'AUR (`yay -Qua`).
- Jellyfin/Spotify (Flatpak) : mis à jour par Discover ou `maj`. Si l'un d'eux ne se met toujours pas à jour, noter lequel et le message.

## 14. Icône « Mises à jour » dans la barre (18/11)
- Widget Plasma maison `org.surface.majsysteme` (`overlay/.../surface/plasmoid-maj`, installé dans `/usr/share/plasma/plasmoids/`). Tourne dans plasmashell : aucun processus en plus.
- `surface-updates-check` écrit le total dans `~/.cache/surface-updates` ; l'icône relit ce fichier chaque minute. Visible (ActiveStatus) s'il y a des mises à jour, rangée dans les entrées masquées sinon. Un clic : `konsole -e maj`. `maj` remet le compteur à jour à la fin (`--silencieux`), l'icône disparaît.
- **Pas testé sur la Surface.** Si l'icône n'apparaît pas : clic droit sur la flèche de la zone de notification > Configurer > Entrées > « Mises à jour » sur « Toujours affiché » ou « Afficher si utile ». Après install, se déconnecter/reconnecter (ou `plasmashell --replace &`).

## 15. Build depuis la Surface (18/11)
- `build.sh` travaille désormais dans `/var/tmp/surface-iso-work` (avant : `/tmp`, en RAM sur Arch, trop petit avec 4 Go). Avertissement si moins de 10 Go libres. Modifiable : `sudo env WORK=/autre/dossier ./build.sh`.
- Ne pas flasher la clé sur l'eMMC par erreur : vérifier `/dev/sdX` avec `lsblk` (l'eMMC est `mmcblk1`).

## 16. Checklist du prochain rebuild (18/11)
Ce que l'ISO installe d'office (tout est dans `install-surface`, rien à faire à la main) :
- **Système** : Arch + noyau linux-surface, **GRUB** (thème Breeze, entrée Arch + entrée de secours removable), zram, pare-feu ufw.
- **Bureau** : **KDE Plasma** (plasma-desktop, SDDM en Wayland avec clavier virtuel, Konsole, Dolphin, Kate, Ark, Spectacle, Moniteur système).
- **Applis** : Firefox, Discord, Jellyfin Desktop, Spotify, Claude.
- **Mises à jour** : icône dans la barre, notification quotidienne, `maj`, hook GRUB.
- **Logiciels** : Discover + Flatpak (Flathub), yay (AUR).

Étapes : fusionner la PR #1 → `sudo pacman -Syu` → `git checkout initial && git pull` → `sudo ./build.sh` → flasher la clé (vérifier `/dev/sdX` avec `lsblk`, jamais `mmcblk1`) → booter la Surface dessus → `install-surface` sur `mmcblk1`.
Attention : la réinstallation efface toute l'eMMC. Sauvegarder avant ce qui n'est pas sur GitHub ou dans le cloud.

## 17. Secure Boot (18/11) — PAS TESTÉ
- Méthode : **sbctl**, clés perso + clés Microsoft (`enroll-keys --microsoft`, recommandé par sbctl pour ne pas casser le matériel). Pas de shim.
- Sur les Surface, Secure Boot désactivé dans l'UEFI = mode configuration (doc lanzaboote, testé Surface Book 3 et Go 3). Sur la Surface Go **1** l'UEFI est différent et ça a coincé (issue sbctl #295) ; la Go 2 a l'UEFI Surface, donc normalement OK, à confirmer.
- `surface-grub-install` : GRUB avec modules intégrés (`--modules=…`, thème Breeze compris) et `--disable-shim-lock`, entrée Arch + removable, re-signe si des clés sbctl existent. Utilisé par l'install, le hook GRUB et `activer-secure-boot`. Noms de modules vérifiés dans les sources GRUB (`efifwsetup`, pas `fwsetup`).
- Re-signature auto : hook pacman de sbctl (noyau, fichiers de /boot) + notre hook GRUB.
- `activer-secure-boot` n'est **pas** lancé pendant l'install : il faut de toute façon passer par l'UEFI pour activer Secure Boot.
- Retour arrière : désactiver Secure Boot dans l'UEFI. Ne jamais supprimer `/var/lib/sbctl` (clés).

## 18. Réponses du 18/11 et ajouts
- **Release** : v1.0.0 publiée directement après un build GitHub réussi (choix de Light).
- **Chiffrement** : en option dans `install-surface` (LUKS2, phrase de passe = mot de passe de session si laissée vide). Initramfs passé en hooks systemd (`sd-encrypt`, `sd-vconsole` pour l'AZERTY, `keyboard` avant `autodetect` pour le Type Cover / clavier USB), `rd.luks.name=UUID=root`, `rd.luks.options=discard` (TRIM gardé). /boot (partition EFI) reste en clair. **Pas testé.** Limite : pas de clavier tactile au déverrouillage (piste future : unl0kr). À vérifier : le Type Cover marche-t-il à l'écran de déverrouillage ?
- **Btrfs + Snapper** : non pour l'instant (peut-être plus tard, avec une carte SD).
- **Usage** : multimédia, notes/dessin au stylet, Discord, Claude, navigateur léger. Ajoutés : Xournal++, Krita, `intel-media-driver` (VA-API). Firefox gardé (déjà allégé : 2 processus, onglets déchargés).

## 19. Deuxième série de réponses (18/11)
- **Navigateur : Falkon remplace Firefox** (navigateur KDE, QtWebEngine, AdBlock intégré à activer dans ses extensions). Paquets `firefox`, `firefox-i18n-fr` et les policies Firefox retirés de l'ISO. Sur la Surface actuelle, `appliquer-sur-surface.sh` installe Falkon mais ne désinstalle pas Firefox (`sudo pacman -Rns firefox firefox-i18n-fr` pour le faire).
- **Bluetooth** : gardé actif (sert sur la Surface).
- **Boutons du stylet** : mapping à décider après le diagnostic libinput.
- **install-surface** : valeurs par défaut neutres gardées (ISO partageable).
- Releases : la session Claude ne peut pas créer de tags/releases (bloqué par le proxy). Publier : Actions > « Construire l'ISO » > Run workflow > version (ex. `1.1.0`). Une release `1.0.0` existe déjà (ISO du 12/11) → prochaine version `1.1.0`.

## 20. Premier test de la 1.1.0 sur la Surface (18/11)
- OK : timer et compteur des mises à jour, Falkon, Discord (+ SKIP_HOST_UPDATE), Xournal++, Krita, intel-media-driver, Claude, Jellyfin.
- **Spotify (Flatpak) absent** après l'install. Corrigé pour 1.1.1 : les Flatpak s'installent un par un.
- **Journal d'install perdu** : il était écrit dans le live (/var/log en RAM). Corrigé : copié dans `/var/log/install-surface.log` du système installé.
- Secure Boot : `sbctl status` → Setup Mode **Enabled** sur la Go 2, l'inscription des clés devrait marcher. `activer-secure-boot` pas encore lancé.
- RAM 2,87 Go / 3,69 Go à 18 min de démarrage : à regarder (`psmem`).

- Clavier Bluetooth (pavé vu comme une souris, 093a:2860) : clic gauche OK après la réinstallation 1.1.0.
- **Secure Boot, 1er essai (18/11)** : Secure Boot activé dans l'UEFI avant le script → « Security boot fail » (normal, rien de signé). Après le script : noyau + grubx64.efi + BOOTX64.EFI signés, mais `Setup Mode` toujours Enabled et `Vendor Keys: none` → clés **pas inscrites**. Bug du script : l'inscription n'était faite qu'à la création des clés (un 2e lancement la sautait). Corrigé : inscription dès que l'UEFI est en mode configuration + arrêt avec erreur si l'inscription n'a pas pris. Reste à voir si l'UEFI de la Go 2 accepte `sbctl enroll-keys --microsoft`.
- **Secure Boot, 2e essai (18/11)** : `enroll-keys --microsoft` à la main → Setup Mode Disabled, Vendor Keys microsoft. Puis Secure Boot activé dans le menu UEFI → encore « Security boot fail ». Cause probable : sur Surface, le réglage du menu remet la config « Microsoft uniquement » (doc lanzaboote : laisser Secure Boot désactivé dans l'UEFI, il s'active seul après l'inscription ; retour Surface Laptop 5 : « custom key configuration »). Script et README corrigés : redémarrer sans toucher à l'UEFI. Plan B si ça ne marche pas : shim + option « Microsoft & 3rd party CA » de l'UEFI.

