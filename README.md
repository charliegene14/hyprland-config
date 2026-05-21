# dotfiles-custom

Overlay perso sur [HyDE Project](https://github.com/HyDE-Project/HyDE) (Hyprland on EndeavourOS).

## Contenu

```
.config/
├── hypr/
│   ├── hyprland.conf          # Template HyDE (source userprefs/keybindings/etc)
│   ├── userprefs.conf         # kb_layout=fr, blur premium, exec-once eww
│   ├── monitors.conf          # (vide — Hyprland auto-detect, scale 1.5 par défaut)
│   ├── nvidia.conf            # LIBVA=iHD (iGPU Intel pour HW video decode)
│   ├── keybindings.conf       # HyDE binds + section "ML4W overlay" + workspaces AZERTY
│   └── scripts/
│       └── waybar-style-cycle.sh   # SUPER SHIFT+PgUp/PgDn cycle styles waybar
└── eww/
    ├── eww.yuck               # Widget desktop sysinfo (CPU/RAM/dGPU/iGPU/disks/net)
    ├── eww.scss               # Style sobre semi-transparent
    └── scripts/
        └── sysinfo.sh         # Source unifiée JSON pour eww

.local/
└── share/
    └── waybar/
        └── layouts/
            └── custom.jsonc   # Layout perso : workspaces + taskbar + clock séparé + power-profiles + updates + hyde-menu
```

## Particularités

- **Keybindings hybrides** : on garde les binds HyDE (rofi `SUPER+A`, clipboard `SUPER+V`, lock `SUPER+L`…) + on ajoute le mapping ML4W familier (`SUPER+RETURN` terminal, `SUPER+T` float, `SUPER+F/M` fullscreen/maximize, `SUPER+K` swapsplit, `SUPER ALT+arrows` swapwindow, `SUPER+CTRL+K` keybinds hint…).
- **Workspaces AZERTY** : `SUPER+&é"'(-è_çà` via `code:10..19` (rangée physique 1..0, indépendante du layout).
- **GPU hybride** : NVIDIA RTX 4050 pour render offload explicite, Intel iGPU pour HW video decode (low-power).
- **Waybar layout `custom`** : workspaces, taskbar apps, clock séparé, power-profiles-daemon (cycle profil énergie au scroll), updates pacman, swaync alternative dunst, keybindhint, hyde-menu.
- **Desktop widget eww** en haut-droite (`:stacking "bg"`, sous les fenêtres) : CPU/RAM/dGPU/iGPU/Disks (tous les mounts y compris USB)/Network/Uptime/Load avg.

## Install sur une nouvelle machine

Pré-requis : EndeavourOS (ou Arch) avec HyDE déjà installé et fonctionnel.

```bash
git clone git@github.com:charliegene14/hyprland-config.git ~/dotfiles-custom
cd ~/dotfiles-custom
./install.sh
```

Le script :
1. Backup les fichiers HyDE qui vont être remplacés (`*.bak.<date>`)
2. Copie l'overlay dans `~/.config/` et `~/.local/share/`
3. Installe les paquets manquants (`eww`, `intel-media-driver` pour iHD, etc.)
4. Rend les scripts exécutables
5. Demande à recharger Hyprland

## Archive

L'ancien overlay ML4W est conservé sous le tag git `ml4w-era`.
```bash
git show ml4w-era
git checkout ml4w-era  # browse l'ancien état (read-only)
```
