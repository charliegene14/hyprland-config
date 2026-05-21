#!/usr/bin/env bash
# Cycle next/prev through waybar styles (HyDE has no native style next/prev).
# Usage: waybar-style-cycle.sh [next|prev]
#
# Reads the actual current style from waybar's @import (HyDE's `-s` flag updates
# style.css but doesn't sync staterc — staterc would lie).

set -e
direction="${1:-next}"
style_css="$HOME/.config/waybar/style.css"
state_file="$HOME/.local/state/hyde/staterc"
styles_dir="$HOME/.local/share/waybar/styles"

current=$(grep -oE '/[^"]*/styles/[^"]+\.css' "$style_css" | head -1)
mapfile -t styles < <(find "$styles_dir" -maxdepth 1 -name "*.css" | sort)
n=${#styles[@]}
[ "$n" -eq 0 ] && { echo "No styles found in $styles_dir" >&2; exit 1; }

idx=0
for i in "${!styles[@]}"; do
    [ "${styles[$i]}" = "$current" ] && idx=$i && break
done

case "$direction" in
    next) next_idx=$(( (idx + 1) % n )) ;;
    prev) next_idx=$(( (idx - 1 + n) % n )) ;;
    *)    echo "Usage: $0 [next|prev]" >&2; exit 1 ;;
esac

next_style="${styles[$next_idx]}"
hyde-shell waybar.py -s "$next_style"

# Sync staterc so reboots respect the choice (HyDE -s doesn't do this).
if [ -f "$state_file" ]; then
    sed -i "s|^WAYBAR_STYLE_PATH=.*|WAYBAR_STYLE_PATH=$next_style|" "$state_file"
fi

notify-send -r 9 "Waybar" "Style → $(basename "$next_style" .css)" 2>/dev/null || true
