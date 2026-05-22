# GRUB theme

Variante customisée du thème [Elegant-grub2-themes](https://github.com/vinceliuice/Elegant-grub2-themes) (vinceliuice), basée sur `wave-window-right-dark` en 1080p.

## Overrides versionnés

| Fichier | Customisation |
|---|---|
| `theme/background.jpg` | Wallpaper composé : fond flouté + vignette nette (créature, glyphes lumineux), carte centrée arrondie `#22202B`, ombre carte, ombre vignette discrète, vignette avec marges symétriques. Version éclaircie (+35 %) pour compenser le boot dim. |
| `theme/background.dim.jpg` | Même composition, version originale non éclaircie. |
| `theme/assets-other-1080p/select_*-wave-dark.png` | Pixmaps de focus : échantillon réel du blur du fond + assombrissement 55 % + teinte warm→cool sampée sur la palette, plus ombre interne soft au bas du bar. Effet "verre dépoli". |
| `theme/config/theme-window-right-dark-1080p.txt` | `theme.txt` sans le bloc `+ image { file = "logo.png" }` (vignette plus propre). |

## Install

```sh
./grub/install-grub-theme.sh
```

Le script :
1. Clone `vinceliuice/Elegant-grub2-themes` dans `$(mktemp -d)`
2. Écrase les fichiers livrés par nos overrides
3. Backup `/etc/default/grub` → `/etc/default/grub.bak.<timestamp>`
4. `sudo ./install.sh -t wave -p window -i right -c dark -s 1080p`
5. Copie les `.pf2` du thème dans `/boot/grub/fonts/` (sinon GRUB n'utilise pas les polices Terminus/Unifont)
6. `sudo grub-mkconfig -o /boot/grub/grub.cfg`

## Rollback

Le script imprime à la fin une ligne `sudo cp …grub.bak.<stamp>… && grub-mkconfig` à exécuter. Les fichiers du thème dans `/usr/share/grub/themes/Elegant-wave-window-right-dark/` peuvent être supprimés avec `sudo rm -rf`.

## Refaire le wallpaper avec une autre image source

La composition est faite à la main avec ImageMagick. Recette résumée :

```sh
SRC=mon-image.jpg
W=1920 H=1080
CARD_W=1280 CARD_H=800 CARD_X=320 CARD_Y=140 CARD_R=28
CARD_COLOR='#22202B'
INSET_W=620 INSET_H=760 INSET_X=960 INSET_Y=160 INSET_R=22

# Fond plein écran flouté
magick "$SRC" -resize "${W}x${H}^" -gravity center -extent "${W}x${H}" \
       -blur 0x28 -modulate 85,90,100 base.png

# Carte centrale + ombre
magick -size "${CARD_W}x${CARD_H}" xc:none -fill "$CARD_COLOR" \
       -draw "roundrectangle 0,0 $((CARD_W-1)),$((CARD_H-1)) ${CARD_R},${CARD_R}" \
       card.png
magick card.png -bordercolor none -border 28x28 \
       \( +clone -background black -shadow 55x14+0+8 \) +swap -composite \
       card_sh.png

# Vignette = crop de la zone d'intérêt de la source + coins arrondis + ombre douce
# (adapter le crop selon la zone à mettre en avant)
magick "$SRC" -crop "${SRC_CROP}" +repage \
       -resize "${INSET_W}x${INSET_H}^" -gravity center -extent "${INSET_W}x${INSET_H}" \
       inset_raw.png
magick -size "${INSET_W}x${INSET_H}" xc:none -fill white \
       -draw "roundrectangle 0,0 $((INSET_W-1)),$((INSET_H-1)) ${INSET_R},${INSET_R}" \
       mask.png
magick inset_raw.png mask.png -alpha off -compose CopyOpacity -composite inset.png
magick inset.png -bordercolor none -border 12x12 \
       \( +clone -background black -shadow 25x5+0+3 \) +swap -composite \
       inset_sh.png

# Composition finale
magick base.png \
       card_sh.png  -geometry "+$((CARD_X-28))+$((CARD_Y-28))"   -composite \
       inset_sh.png -geometry "+$((INSET_X-12))+$((INSET_Y-12))" -composite \
       -modulate 135,110,100 \
       background.jpg
```

Pour refaire les pixmaps de focus (sample du blur + teinte + ombre interne), voir le commit qui les a produits dans l'historique de ce repo.
