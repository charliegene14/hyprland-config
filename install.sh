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

echo ">> Installation des paquets manquants"
pkgs=$(grep -vE '^\s*(#|$)' "$REPO/packages.txt" | awk '{print $1}')
sudo pacman -S --needed --noconfirm $pkgs

echo ">> Application de l'overlay dans $ML4W"
stamp=$(date +%Y%m%d-%H%M%S)
rsync -av --backup --suffix=".bak.$stamp" \
    "$REPO/.config/" "$ML4W/.config/"

echo ">> Permissions des scripts"
chmod +x "$ML4W/.config/hypr/scripts/dock-premium.sh" \
         "$ML4W/.config/hypr/scripts/dock-fullscreen-listener.sh"
find "$ML4W/.config/waybar/themes/premium/scripts" -type f -name '*.sh' \
    -exec chmod +x {} +

echo
echo "OK. Sauvegardes des fichiers remplacés: *.bak.$stamp dans $ML4W/.config/"
echo "Recharge Hyprland (SUPER+CTRL+R) ou relogue pour tout voir."
