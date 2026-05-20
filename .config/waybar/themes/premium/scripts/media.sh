#!/usr/bin/env bash
# Media with rich Pango-markup tooltip (artist/album/progress bar).

MAX_LEN=26
ICON=""  # Phosphor music-note

title=$(playerctl metadata title 2>/dev/null)
artist=$(playerctl metadata artist 2>/dev/null)
album=$(playerctl metadata album 2>/dev/null)
status=$(playerctl status 2>/dev/null)
length_us=$(playerctl metadata mpris:length 2>/dev/null)
pos=$(playerctl position 2>/dev/null)
player=$(playerctl metadata --format '{{playerName}}' 2>/dev/null)

if [[ -z "$title" ]]; then
    echo '{"text":"","tooltip":"","class":"empty","alt":"empty"}'
    exit 0
fi

# Format display title
if [[ -n "$artist" ]]; then
    display="$artist — $title"
else
    display="$title"
fi
if (( ${#display} > MAX_LEN )); then
    display="${display:0:$((MAX_LEN-1))}…"
fi

class="playing"
[[ "$status" == "Paused" ]] && class="paused"

# Build progress bar (16 chars)
bar=""
percent=0
pos_str="--:--"
dur_str="--:--"
if [[ -n "$length_us" && "$length_us" -gt 0 && -n "$pos" ]]; then
    # pos is seconds (float), length_us is microseconds (int)
    pos_int=${pos%.*}
    length_s=$((length_us / 1000000))
    if (( length_s > 0 )); then
        percent=$(( pos_int * 100 / length_s ))
        (( percent > 100 )) && percent=100
        (( percent < 0 )) && percent=0
        filled=$(( percent * 16 / 100 ))
        for ((i=0; i<filled; i++)); do bar+="█"; done
        for ((i=filled; i<16; i++)); do bar+="░"; done
        # Format times
        pos_str=$(printf "%d:%02d" $((pos_int/60)) $((pos_int%60)))
        dur_str=$(printf "%d:%02d" $((length_s/60)) $((length_s%60)))
    fi
fi

esc() { sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g' <<< "$1"; }

tip="<b>$(esc "$title")</b>"
[[ -n "$artist" ]] && tip+="\n<i>$(esc "$artist")</i>"
[[ -n "$album"  ]] && tip+="\n<span alpha='55000'>$(esc "$album")</span>"
[[ -n "$bar"    ]] && tip+="\n\n<span size='smaller'>$bar  $pos_str / $dur_str  ($percent%)</span>"
[[ -n "$player" ]] && tip+="\n<span alpha='45000' size='smaller'>via $player · $status</span>"

# Compose text (icon + display)
text="$ICON  $(esc "$display")"

jq -nc --arg text "$text" --arg tooltip "$tip" --arg class "$class" --arg alt "$class" \
    '{ text: $text, tooltip: $tooltip, class: $class, alt: $alt }'
