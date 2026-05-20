#!/usr/bin/env bash
# Privacy: visible when any /dev/video* is opened.
in_use=""
for dev in /dev/video*; do
    [[ -e "$dev" ]] || continue
    pid=$(fuser "$dev" 2>/dev/null | tr -d ' ')
    if [[ -n "$pid" ]]; then
        # Resolve PIDs to comm names
        for p in $pid; do
            name=$(ps -p "$p" -o comm= 2>/dev/null)
            [[ -n "$name" ]] && in_use+="• $name on $dev\\n"
        done
    fi
done

if [[ -n "$in_use" ]]; then
    echo "{\"text\":\"\",\"tooltip\":\"Caméra en cours d'\''utilisation\\n$in_use\",\"class\":\"recording\"}"
else
    echo '{"text":"","tooltip":"","class":"idle"}'
fi
