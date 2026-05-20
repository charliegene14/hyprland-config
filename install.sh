#!/usr/bin/env bash
# Applique l'overlay custom par-dessus une install ML4W (stable) existante.
# Idempotent : relance après chaque `git pull` ou update ML4W.

set -euo pipefail

ML4W="$HOME/.mydotfiles/com.ml4w.dotfiles.stable"
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ ! -d "$ML4W/.config" ]]; then
    echo "ERREUR: ML4W introuvable dans $ML4W"
    echo "       Installe d'abord ML4W (https://github.com/mylinuxforwork/dotfiles), puis relance."
    exit 1
fi

read_pkgs() { grep -vE '^\s*(#|$)' "$1" | awk '{print $1}'; }

echo ">> Paquets pacman"
pkg_pacman=$(read_pkgs "$REPO/packages-pacman.txt")
sudo pacman -S --needed --noconfirm $pkg_pacman

if [[ -s "$REPO/packages-aur.txt" ]]; then
    echo ">> Paquets AUR"
    if ! command -v yay >/dev/null 2>&1; then
        echo "ERREUR: 'yay' requis pour les paquets AUR. Installe-le d'abord :"
        echo "  sudo pacman -S --needed git base-devel"
        echo "  git clone https://aur.archlinux.org/yay.git /tmp/yay && cd /tmp/yay && makepkg -si"
        exit 1
    fi
    pkg_aur=$(read_pkgs "$REPO/packages-aur.txt")
    yay -S --needed --noconfirm $pkg_aur
fi

echo ">> Application de l'overlay dans $ML4W"
stamp=$(date +%Y%m%d-%H%M%S)
rsync -av --backup --suffix=".bak.$stamp" \
    "$REPO/.config/" "$ML4W/.config/"

echo ">> Permissions des scripts"
chmod +x "$ML4W/.config/hypr/scripts/dock-premium.sh"
find "$ML4W/.config/waybar/themes/premium/scripts" -type f -name '*.sh' \
    -exec chmod +x {} +

echo
echo "OK. Sauvegardes des fichiers remplacés: *.bak.$stamp dans $ML4W/.config/"
echo "Recharge Hyprland (SUPER+CTRL+R) ou relogue pour tout voir."
