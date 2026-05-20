#!/usr/bin/env bash
# Contextual Audio menu via rofi — switch output sink, quick mute, open pavucontrol.

current_sink=$(wpctl status | awk '
    /^Audio/ {audio=1}
    audio && /Sinks:/ {sinks=1; next}
    sinks && /Sources:/ {exit}
    sinks && /\*/ { sub(/^[ │└├─*.]+/, ""); sub(/ \[vol:.*$/, ""); print; exit }
')

build_menu() {
    echo "🔊  Volume : $(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{printf "%.0f%%\n", $2*100}')"
    if wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -q MUTED; then
        echo "🔈  Démuter"
    else
        echo "🔇  Muter"
    fi
    echo "──────────────"
    echo "Périphériques de sortie :"

    # List sinks (ID. Name)
    wpctl status | awk '
        /^Audio/ {audio=1}
        audio && /Sinks:/ {sinks=1; next}
        sinks && /Sources:/ {exit}
        sinks && /^[ │└├*. ]+[0-9]+\./ {
            id=$0
            sub(/^[ │└├─*.]+/, "", id)
            id_num=id
            sub(/\..*/, "", id_num)
            name=id
            sub(/^[0-9]+\. */, "", name)
            sub(/ \[vol:.*$/, "", name)
            marker=" "
            if (match($0, /\*/)) marker="✓"
            printf "%s [%s] %s\n", marker, id_num, name
        }'

    echo "──────────────"
    echo "⚙  pavucontrol"
}

choice=$(build_menu | rofi -dmenu -i -p "Audio" \
    -theme ~/.config/rofi/config-short.rasi \
    -theme-str 'window {width: 36em; location: center; anchor: center; x-offset: 0; y-offset: 0;} listview {lines: 10;}' \
    2>/dev/null)

[[ -z "$choice" ]] && exit 0

case "$choice" in
    *"Démuter"|*"Muter")
        wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
        ;;
    *"pavucontrol")
        pavucontrol &
        ;;
    *"["*"]"*)
        # Switch to this sink
        id=$(grep -oP '\[\K[0-9]+(?=\])' <<< "$choice")
        wpctl set-default "$id"
        notify-send "Audio" "Sortie audio changée"
        ;;
    "──────"*|"Périphériques"*|"🔊"*)
        ;;
esac
