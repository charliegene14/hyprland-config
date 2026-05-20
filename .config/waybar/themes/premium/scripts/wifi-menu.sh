#!/usr/bin/env bash
# Contextual Wi-Fi menu via rofi — list nearby networks, connect on selection.
# Mimics macOS Wi-Fi dropdown.

# Check NetworkManager is running
if ! systemctl is-active --quiet NetworkManager; then
    notify-send "Wi-Fi" "NetworkManager n'est pas actif"
    exit 1
fi

# Trigger a scan in background (don't block)
nmcli device wifi rescan >/dev/null 2>&1 &

# Wi-Fi state
wifi_state=$(nmcli -t -f WIFI g)

# Build menu lines
build_menu() {
    if [[ "$wifi_state" == "disabled" ]]; then
        echo "󰖪  Activer le Wi-Fi"
        echo "⚙  Ouvrir nm-connection-editor"
        return
    fi

    # Current connection
    current=$(nmcli -t -f ACTIVE,SSID dev wifi | awk -F: '$1=="yes"{print $2}' | head -1)

    # Header items
    echo "󰖩  Wi-Fi : activé · Désactiver"
    [[ -n "$current" ]] && echo "✓  $current (connecté)"
    echo "──────────────"

    # Available networks (deduplicated, sorted by signal desc)
    nmcli -t -f SSID,SIGNAL,SECURITY dev wifi list \
      | awk -F: '$1!="" && $1!="--"' \
      | sort -t: -k2 -nr \
      | awk -F: '!seen[$1]++ {
          icon = ($3=="" || $3=="--") ? "󰤨 " : "󰤪 ";
          printf "%s %s (%s%%)\n", icon, $1, $2
        }' \
      | head -15

    echo "──────────────"
    echo "⚙  Réglages avancés"
}

choice=$(build_menu | rofi -dmenu -i -p "Wi-Fi" \
    -theme ~/.config/rofi/config-short.rasi \
    -theme-str 'window {width: 32em; location: center; anchor: center; x-offset: 0; y-offset: 0;} listview {lines: 12;}' \
    2>/dev/null)

[[ -z "$choice" ]] && exit 0

case "$choice" in
    *"Activer le Wi-Fi")
        nmcli radio wifi on
        ;;
    *"Désactiver")
        nmcli radio wifi off
        ;;
    *"Réglages avancés"|*"nm-connection-editor")
        nm-connection-editor &
        ;;
    *"(connecté)")
        # Click on current → offer disconnect
        ssid=$(sed 's/^✓  //; s/ (connecté)$//' <<< "$choice")
        nmcli connection down "$ssid"
        ;;
    "──────"*)
        # Separator clicked, ignore
        ;;
    *)
        # Network item — extract SSID between icon prefix and " (xx%)"
        ssid=$(sed -E 's/^[^ ]+ //; s/ \([0-9]+%\)$//' <<< "$choice")
        # Try connect (will prompt password if needed via secret agent)
        nmcli device wifi connect "$ssid" 2>&1 | grep -q "Error" && {
            # If password needed, open editor
            notify-send "Wi-Fi" "Connexion à $ssid en cours ou mot de passe requis"
            nm-connection-editor &
        } || notify-send "Wi-Fi" "Connecté à $ssid"
        ;;
esac
