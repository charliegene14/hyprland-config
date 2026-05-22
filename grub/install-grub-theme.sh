#!/usr/bin/env bash
# Installe une variante customisée du thème Elegant-grub2-themes (vinceliuice).
#
# Variante : wave / window / right / dark / 1080p
# Customisations versionnées dans ce repo (grub/theme/) :
#   - background.jpg          : wallpaper composé (flou + vignette + ombres + marges)
#   - assets-other-1080p/     : pixmaps de focus (select_*-wave-dark.png)
#                               → blur sample teinté warm→cool + ombre interne douce
#   - config/                 : theme.txt sans le bloc + image logo.png
#
# Ce que fait le script :
#   1. Clone vinceliuice/Elegant-grub2-themes dans un dossier temp
#   2. Écrase les fichiers livrés par nos overrides
#   3. Lance sudo ./install.sh avec les bons flags
#   4. Copie les .pf2 dans /boot/grub/fonts/ pour que grub-mkconfig les charge
#   5. Régénère /boot/grub/grub.cfg
#
# Usage : ./grub/install-grub-theme.sh

set -euo pipefail

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
OVERRIDES="$SCRIPT_DIR/theme"

info() { printf '\033[1;34m::\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }
err()  { printf '\033[1;31m!!\033[0m %s\n' "$*" >&2; exit 1; }

# ─── 0. Sanity ────────────────────────────────────────────────
command -v git           >/dev/null || err "git requis"
command -v grub-mkconfig >/dev/null || err "grub-mkconfig requis"
[ -d /boot/grub ] || err "/boot/grub absent (configuration GRUB non standard)"

# ─── 1. Clone upstream ────────────────────────────────────────
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

info "Clone vinceliuice/Elegant-grub2-themes dans $TMP"
git clone --depth=1 https://github.com/vinceliuice/Elegant-grub2-themes.git "$TMP/elegant" >/dev/null

# ─── 2. Apply overrides ───────────────────────────────────────
info "Application des overrides depuis $OVERRIDES"

# Wallpaper personnalisé à la racine du repo upstream → détecté par install.sh
cp "$OVERRIDES/background.jpg" "$TMP/elegant/background.jpg"

# Pixmaps de focus customisés
for f in select_c-wave-dark.png select_w-wave-dark.png select_e-wave-dark.png; do
    cp "$OVERRIDES/assets-other-1080p/$f" \
       "$TMP/elegant/assets/assets-other/other-1080p/$f"
done

# theme.txt sans logo
cp "$OVERRIDES/config/theme-window-right-dark-1080p.txt" \
   "$TMP/elegant/config/theme-window-right-dark-1080p.txt"

# ─── 3. Run installer ─────────────────────────────────────────
info "Backup /etc/default/grub"
STAMP=$(date +%Y%m%d_%H%M%S)
sudo cp /etc/default/grub "/etc/default/grub.bak.$STAMP"

info "sudo ./install.sh -t wave -p window -i right -c dark -s 1080p"
(cd "$TMP/elegant" && sudo ./install.sh -t wave -p window -i right -c dark -s 1080p)

# ─── 4. Fonts pour que GRUB les charge ────────────────────────
THEME_DIR=/usr/share/grub/themes/Elegant-wave-window-right-dark
if compgen -G "$THEME_DIR/*.pf2" > /dev/null; then
    info "Copie des .pf2 dans /boot/grub/fonts/ (loadfont auto via grub-mkconfig)"
    sudo cp "$THEME_DIR"/*.pf2 /boot/grub/fonts/
else
    warn "Aucun .pf2 dans $THEME_DIR — polices custom indisponibles"
fi

# ─── 5. Régénération grub.cfg ─────────────────────────────────
info "Régénération /boot/grub/grub.cfg"
sudo grub-mkconfig -o /boot/grub/grub.cfg

info "OK. Reboot pour voir le résultat."
info "Rollback : sudo cp /etc/default/grub.bak.$STAMP /etc/default/grub && sudo grub-mkconfig -o /boot/grub/grub.cfg"
