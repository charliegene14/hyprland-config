#!/usr/bin/env bash
# Privacy: visible when any app is consuming the default microphone.
n=$(pactl list short source-outputs 2>/dev/null | wc -l)
if (( n > 0 )); then
    apps=$(pactl list source-outputs 2>/dev/null \
        | awk -F'=' '/application.name =/ {gsub(/^[ "]+|[ "]+$/, "", $2); print "• " $2}' \
        | sort -u | head -5)
    [[ -z "$apps" ]] && apps="(app inconnu)"
    echo "{\"text\":\"\",\"tooltip\":\"Microphone en cours d'\''utilisation\\n$apps\",\"class\":\"recording\"}"
else
    echo '{"text":"","tooltip":"","class":"idle"}'
fi
