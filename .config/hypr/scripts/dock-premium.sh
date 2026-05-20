#!/usr/bin/env bash
# AnkurAlpha config — exact flags from upstream README

exec 200>/tmp/dock-premium.lock
flock -n 200 || exit 0

killall nwg-dock-hyprland 2>/dev/null
sleep 0.3

cd ~/.config/nwg-dock-hyprland
nwg-dock-hyprland \
    -l top \
    -x \
    -p "left" \
    -i 24 \
    -mt 20 \
    -mb 20 \
    -ml 10 \
    -f \
    -s themes/premium/style.css \
    -ico "$HOME/.config/nwg-dock-hyprland/icons/squares-four.svg" \
    -c "$HOME/.config/hypr/scripts/launcher.sh" &
