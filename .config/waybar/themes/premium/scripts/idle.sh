#!/usr/bin/env bash
# Caffeine indicator: visible when hypridle is OFF (screen stays awake)
if pgrep -x hypridle >/dev/null 2>&1; then
    echo '{"text":"","tooltip":"","class":"normal"}'
else
    echo '{"text":"","tooltip":"Mode caféine actif (écran reste allumé)\nClic pour réactiver l'\''idle","class":"caffeine"}'
fi
