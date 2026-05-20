#!/usr/bin/env bash
# Single-line active window with Pango markup: <b>Class</b> · Title
# Re-emits only when state changes.

MAX_LEN=46

emit() {
    local window=$(hyprctl activewindow -j 2>/dev/null)
    local address=$(jq -r '.address // empty' <<< "$window")

    if [[ -z "$address" || "$address" == "null" ]]; then
        local ws=$(hyprctl activeworkspace -j 2>/dev/null | jq -r '.id // "?"')
        local class="Hyprland"
        local title="Workspace $ws"
    else
        local class=$(jq -r '.class // "Unknown"' <<< "$window")
        local title=$(jq -r '.title // ""' <<< "$window")
        local lc="${class,,}"

        if [[ "$lc" == *discord* || "$lc" == *vesktop* ]]; then
            title=$(sed -E 's/^\([0-9]+\)[[:space:]]*//' <<< "$title")
            title=$(sed -E 's/^Discord[[:space:]]*\|[[:space:]]*//' <<< "$title")
        fi

        # Truncate title if combined "Class · Title" too long
        local combined="$class · $title"
        if (( ${#combined} > MAX_LEN )); then
            local room=$(( MAX_LEN - ${#class} - 4 ))
            (( room < 6 )) && room=6
            title="${title:0:$((room-1))}…"
        fi
    fi

    # Pango markup escape (only & < >) — quotes don't need escaping
    local ec=$(sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g' <<< "$class")
    local et=$(sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g' <<< "$title")

    # Big middle dot via span
    local markup="<b>$ec</b><span size='larger' alpha='60000'>  ·  </span>$et"
    local tip="$class — $title"

    jq -nc --arg text "$markup" --arg tooltip "$tip" \
        '{ text: $text, tooltip: $tooltip }'
}

emit

last=""
while true; do
    cur=$(hyprctl activewindow -j 2>/dev/null)
    if [[ "$cur" != "$last" ]]; then
        emit
        last="$cur"
    fi
    sleep 0.4
done
