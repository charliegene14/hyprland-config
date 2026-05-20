#!/usr/bin/env bash
# Power profile indicator + rotation on click.
# Usage:
#   ./powerprofile.sh         -> emit current state as JSON
#   ./powerprofile.sh cycle   -> rotate to next profile

action="${1:-status}"

if [[ "$action" == "cycle" ]]; then
    current=$(powerprofilesctl get 2>/dev/null)
    case "$current" in
        power-saver) next="balanced" ;;
        balanced)    next="performance" ;;
        performance) next="power-saver" ;;
        *)           next="balanced" ;;
    esac
    powerprofilesctl set "$next"
    # Force waybar to re-poll: refresh signal not strictly needed since we use interval
    pkill -RTMIN+11 waybar 2>/dev/null
    exit 0
fi

current=$(powerprofilesctl get 2>/dev/null)
case "$current" in
    performance)
        # Material Symbols: bolt () — performance/fast
        echo '{"text":"","tooltip":"Profil : Performance\nClic pour basculer","class":"performance"}'
        ;;
    power-saver)
        # Material Symbols: eco () — power saving
        echo '{"text":"","tooltip":"Profil : Économie\nClic pour basculer","class":"saver"}'
        ;;
    *)
        # balanced fallback: balance ()
        echo '{"text":"","tooltip":"Profil : Équilibré\nClic pour basculer","class":"balanced"}'
        ;;
esac
