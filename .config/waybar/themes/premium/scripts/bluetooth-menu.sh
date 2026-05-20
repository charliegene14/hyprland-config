#!/usr/bin/env bash
# Bluetooth contextual menu — stays in rofi during scan via --async-pre-read.

THEME="$HOME/.config/rofi/config-short.rasi"
THEME_STR='window {width: 38em; location: center; anchor: center; x-offset: 0; y-offset: 0;} listview {lines: 14;}'

reopen() { exec "$0"; }

# Returns "✓" if device connected, "○" otherwise
device_state() {
    bluetoothctl info "$1" 2>/dev/null | grep -q "Connected: yes" && echo "✓" || echo "○"
}

# Returns 0 if device has a real human-readable name (not just its MAC)
has_name() {
    local line="$1"
    local mac=$(awk '{print $2}' <<< "$line")
    local name=$(cut -d' ' -f3- <<< "$line")
    [[ -z "$mac" || -z "$name" ]] && return 1
    # Skip if name equals MAC (no name advertised) or only contains hex/colons
    [[ "$name" == "$mac" ]] && return 1
    [[ "$name" =~ ^[A-F0-9:]+$ ]] && return 1
    return 0
}

# Initial state
soft_blocked=$(rfkill list bluetooth 2>/dev/null | awk '/Soft blocked:/ {print $3; exit}')
powered=$(bluetoothctl show 2>/dev/null | awk '/Powered:/ {print $2}')

# ──────────────────────────── Build main menu ────────────────────────────
build_menu() {
    if [[ "$soft_blocked" == "yes" ]]; then
        echo "󰂲  Bluetooth bloqué (rfkill) · Débloquer"
        echo "⚙  blueman-manager"
        return
    fi
    if [[ "$powered" == "no" ]]; then
        echo "󰂲  Allumer le Bluetooth"
        echo "⚙  blueman-manager"
        return
    fi

    echo "󰂯  Bluetooth : on · Éteindre"
    echo "🔍  Scanner (10s)"
    echo "──────────────"

    while IFS= read -r line; do
        has_name "$line" || continue
        local mac=$(awk '{print $2}' <<< "$line")
        local name=$(cut -d' ' -f3- <<< "$line")
        local state=$(device_state "$mac")
        echo "$state  $name [$mac]"
    done < <(bluetoothctl devices Paired 2>/dev/null)

    echo "──────────────"
    echo "⚙  blueman-manager"
}

# ──────────────────────────── Scan view (live) ────────────────────────────
build_scan_view() {
    echo "🔄 Recherche en cours (10s)…"
    echo "──── Déjà appairés ────"
    while IFS= read -r line; do
        has_name "$line" || continue
        local mac=$(awk '{print $2}' <<< "$line")
        local name=$(cut -d' ' -f3- <<< "$line")
        local state=$(device_state "$mac")
        echo "$state  $name [$mac]"
    done < <(bluetoothctl devices Paired 2>/dev/null)

    # Run scan (blocks)
    bluetoothctl --timeout 10 scan on >/dev/null 2>&1

    echo "──── Découverts ────"
    local found_any=0
    while IFS= read -r line; do
        has_name "$line" || continue
        local mac=$(awk '{print $2}' <<< "$line")
        [[ -z "$mac" ]] && continue
        bluetoothctl info "$mac" 2>/dev/null | grep -q "Paired: yes" && continue
        local name=$(cut -d' ' -f3- <<< "$line")
        echo "+  $name [$mac]"
        found_any=1
    done < <(bluetoothctl devices 2>/dev/null)

    [[ "$found_any" == "0" ]] && echo "   (aucun nouvel appareil trouvé)"
    echo "✓  Recherche terminée"
}

# ──────────────────────────── Action dispatcher ────────────────────────────
handle() {
    local choice="$1"
    [[ -z "$choice" ]] && exit 0

    case "$choice" in
        *"bloqué"*"Débloquer"*)
            pkexec rfkill unblock bluetooth && {
                sleep 0.5
                bluetoothctl power on >/dev/null 2>&1
                notify-send "Bluetooth" "Débloqué et activé"
            } || notify-send "Bluetooth" "Échec du déblocage"
            reopen ;;
        *"Allumer le Bluetooth")
            if bluetoothctl power on 2>&1 | grep -q "Failed"; then
                notify-send "Bluetooth" "Échec de l'allumage"
            else
                notify-send "Bluetooth" "Bluetooth activé"
            fi
            reopen ;;
        *"Éteindre")
            bluetoothctl power off >/dev/null 2>&1
            notify-send "Bluetooth" "Bluetooth éteint"
            reopen ;;
        *"Scanner"*)
            # Open scan view; the choice from there is processed recursively
            local scan_choice=$(build_scan_view | rofi -dmenu -i -p "Bluetooth (scan)" \
                -async-pre-read 1 -theme "$THEME" -theme-str "$THEME_STR" 2>/dev/null)
            handle "$scan_choice" ;;
        *"blueman-manager")
            blueman-manager & ;;
        "✓  Recherche terminée"|"🔄"*|"──"*|"   "*)
            reopen ;;
        "✓ "*|"✓  "*)
            mac=$(grep -oP '\[[A-F0-9:]+\]' <<< "$choice" | tr -d '[]')
            notify-send "Bluetooth" "Déconnexion…"
            bluetoothctl disconnect "$mac" >/dev/null 2>&1
            reopen ;;
        "○ "*|"○  "*)
            mac=$(grep -oP '\[[A-F0-9:]+\]' <<< "$choice" | tr -d '[]')
            notify-send "Bluetooth" "Connexion…"
            if bluetoothctl connect "$mac" 2>&1 | grep -q "successful"; then
                notify-send "Bluetooth" "Connecté"
            else
                notify-send "Bluetooth" "Échec de la connexion"
            fi
            reopen ;;
        "+ "*|"+  "*)
            mac=$(grep -oP '\[[A-F0-9:]+\]' <<< "$choice" | tr -d '[]')
            notify-send "Bluetooth" "Pairing…"
            if bluetoothctl pair "$mac" 2>&1 | grep -q "successful"; then
                bluetoothctl trust "$mac" >/dev/null 2>&1
                bluetoothctl connect "$mac" >/dev/null 2>&1
                notify-send "Bluetooth" "Appairé et connecté"
            else
                notify-send "Bluetooth" "Pairing échoué — ouverture de blueman pour code PIN"
                blueman-manager &
            fi
            reopen ;;
    esac
}

# ──────────────────────────── Main ────────────────────────────
if ! systemctl is-active --quiet bluetooth; then
    notify-send "Bluetooth" "Service bluetooth.service inactif"
    exit 1
fi

main_choice=$(build_menu | rofi -dmenu -i -p "Bluetooth" \
    -theme "$THEME" -theme-str "$THEME_STR" 2>/dev/null)
handle "$main_choice"
