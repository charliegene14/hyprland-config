# dotfiles-custom

Overlay de mes customisations par-dessus [ML4W dotfiles](https://github.com/mylinuxforwork/dotfiles) (stable).

## Contenu

- `.config/hypr/conf/custom.conf` — keybindings AZERTY (workspaces via `code:10..19`), env NVIDIA/Intel hybride, blur premium, exec dock + applets tray, bind `SUPER+V` cliphist
- `.config/hypr/scripts/dock-premium.sh` — lance `nwg-dock-hyprland` avec config "AnkurAlpha" + thème premium
- `.config/hypr/scripts/dock-fullscreen-listener.sh` — auto-hide du dock en fullscreen (IPC Hyprland via `socat`)
- `.config/nwg-dock-hyprland/themes/premium/style.css` — thème dock
- `.config/waybar/themes/premium/` — thème waybar (config + scripts associés)

## Install (nouvelle machine)

```bash
# 1. Installer ML4W d'abord (suivre leur README)
# 2. Puis :
git clone <ce-repo> ~/dotfiles-custom
cd ~/dotfiles-custom
./install.sh
```

Le script :
1. Installe les paquets de `packages.txt` (`pacman -S --needed`)
2. Copie l'overlay dans `~/.mydotfiles/com.ml4w.dotfiles.stable/.config/` avec backup `*.bak.<date>` de tout fichier ML4W remplacé
3. Rend les scripts exécutables

## Workflow update ML4W

ML4W écrase ses propres fichiers à chaque update — ce qui peut casser nos overrides.

```bash
# Après une update ML4W :
cd ~/dotfiles-custom
./install.sh   # réapplique l'overlay
```

Si ML4W introduit une nouvelle version d'un fichier qu'on override (ex: une nouvelle option pertinente dans `custom.conf`), comparer `*.bak.<date>` au nouveau fichier et merger à la main.

## Ce qui n'est volontairement **pas** versionné

- Symlinks `~/.config/*` (gérés par ML4W)
- Fichiers générés par matugen (`colors.conf`, `colors.css`, `ml4w/colors/*`, etc.) — réécrits à chaque changement de thème
- Le reste de ML4W non modifié — récupéré via leur installer
