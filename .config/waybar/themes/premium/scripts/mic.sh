#!/usr/bin/env bash
# Mic mute indicator. Hidden when mic is unmuted (premium UX).
# Output: JSON. When muted: shows icon + 'muted' class. When not muted: empty text → CSS hides.

state=$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null)

if [[ "$state" == *"MUTED"* ]]; then
    # mic_off icon (Material Symbols)
    echo '{"text":"", "tooltip":"Microphone muté\nClic pour démuter", "class":"muted"}'
else
    # Hidden when mic is open
    echo '{"text":"", "tooltip":"", "class":"open"}'
fi
