# Terminal « façon CachyOS » pour la Surface (fish + fastfetch + eza + bat)

# Message d'accueil : logo et infos système
function fish_greeting
    fastfetch
end

# Pages de manuel colorées
set -x MANROFFOPT "-c"
set -x MANPAGER "sh -c 'col -bx | bat -l man -p'"

# Dossiers d'exécutables personnels
fish_add_path ~/.local/bin

# !! (dernière commande) et !$ (dernier argument), comme dans bash
function __derniere_commande
    switch (commandline -t)
        case "!"
            commandline -t $history[1]; commandline -f repaint
        case "*"
            commandline -i !
    end
end
function __dernier_argument
    switch (commandline -t)
        case "!"
            commandline -t ""
            commandline -f history-token-search-backward
        case "*"
            commandline -i '$'
    end
end
bind ! __derniere_commande
bind '$' __dernier_argument

# Historique avec la date
function history
    builtin history --show-time='%F %T ' $argv
end

# Listes de fichiers avec couleurs et icônes
alias ls='eza -al --color=always --group-directories-first --icons=always'
alias la='eza -a --color=always --group-directories-first --icons=always'
alias ll='eza -l --color=always --group-directories-first --icons=always'
alias lt='eza -aT --color=always --group-directories-first --icons=always'

# Raccourcis pratiques
alias ..='cd ..'
alias ...='cd ../..'
alias grep='grep --color=auto'
alias update='sudo pacman -Syu && yay -Sua && flatpak update'
alias cleanup='sudo pacman -Rns (pacman -Qtdq)'
alias fixpacman='sudo rm /var/lib/pacman/db.lck'
alias grubup='sudo grub-mkconfig -o /boot/grub/grub.cfg'
alias jctl='journalctl -p 3 -xb'
alias psmem='ps auxf | sort -nr -k 4 | head -15'
alias big="expac -H M '%m\t%n' | sort -h | nl"
alias rip="expac --timefmt='%Y-%m-%d %T' '%l\t%n %v' | sort | tail -50 | nl"
