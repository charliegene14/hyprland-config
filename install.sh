#!/usr/bin/env bash
# Deploy this overlay on top of a working HyDE setup.
# - Backs up any HyDE file we replace as *.bak.<date>
# - Installs missing packages
# - Copies overlay files
# - Makes scripts executable

set -euo pipefail
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
STAMP=$(date +%Y%m%d_%H%M%S)

info() { printf '\033[1;34m::\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }

# ─── 0. Sanity checks ─────────────────────────────────────────
if ! command -v hyprctl &>/dev/null; then
    warn "Hyprland is required. Install HyDE first: https://github.com/HyDE-Project/HyDE"
    exit 1
fi
if [ ! -f "$HOME/.config/hypr/hyprland.conf" ] || ! grep -q HYDE_HYPRLAND "$HOME/.config/hypr/hyprland.conf" 2>/dev/null; then
    warn "HyDE doesn't seem fully installed (missing ~/.config/hypr/hyprland.conf with HYDE marker)."
    warn "Install HyDE first, then re-run this."
    exit 1
fi

# ─── 1. Packages ──────────────────────────────────────────────
PACMAN_PKGS=(intel-media-driver)
AUR_PKGS=(eww)

info "Checking pacman packages..."
missing_p=()
for p in "${PACMAN_PKGS[@]}"; do
    pacman -Qq "$p" &>/dev/null || missing_p+=("$p")
done
[ "${#missing_p[@]}" -gt 0 ] && sudo pacman -S --needed --noconfirm "${missing_p[@]}"

info "Checking AUR packages..."
if ! command -v yay &>/dev/null; then
    warn "yay not found — install yay first (or skip AUR step)."
else
    missing_a=()
    for p in "${AUR_PKGS[@]}"; do
        pacman -Qq "$p" &>/dev/null || missing_a+=("$p")
    done
    [ "${#missing_a[@]}" -gt 0 ] && yay -S --needed --noconfirm "${missing_a[@]}"
fi

# ─── 2. Copy overlay files ────────────────────────────────────
copy_with_backup() {
    local src="$1" dst="$2"
    mkdir -p "$(dirname "$dst")"
    if [ -f "$dst" ] && ! cmp -s "$src" "$dst"; then
        cp "$dst" "$dst.bak.$STAMP"
        info "  backed up: $dst -> $dst.bak.$STAMP"
    fi
    cp "$src" "$dst"
    info "  installed: $dst"
}

info "Deploying overlay..."
while IFS= read -r -d '' f; do
    rel="${f#$SCRIPT_DIR/}"
    copy_with_backup "$f" "$HOME/$rel"
done < <(find "$SCRIPT_DIR/.config" "$SCRIPT_DIR/.local" -type f -print0)

# ─── 3. chmod scripts ─────────────────────────────────────────
chmod +x "$HOME/.config/hypr/scripts/"*.sh 2>/dev/null || true
chmod +x "$HOME/.config/eww/scripts/"*.sh 2>/dev/null || true

# ─── 4. Reload Hyprland ───────────────────────────────────────
info "Reloading Hyprland config..."
hyprctl reload >/dev/null || warn "hyprctl reload failed — reload manually."

# ─── 5. Apply waybar custom layout ────────────────────────────
if command -v hyde-shell &>/dev/null && [ -f "$HOME/.local/share/waybar/layouts/custom.jsonc" ]; then
    info "Switching waybar to 'custom' layout..."
    hyde-shell waybar.py --set custom >/dev/null 2>&1 || warn "Layout switch failed — run manually: hyde-shell waybar.py --set custom"
fi

# ─── 6. Open eww widget ───────────────────────────────────────
if command -v eww &>/dev/null; then
    info "Opening eww desktop widget..."
    eww open sysinfo >/dev/null 2>&1 || warn "eww open failed — run manually: eww open sysinfo"
fi

info "Done."
echo
echo "Next:"
echo "  - Inspect ~/.config/hypr/*.conf for any *.bak.$STAMP and review diff"
echo "  - Reboot or relog to ensure exec-once items (eww autostart) trigger cleanly"
