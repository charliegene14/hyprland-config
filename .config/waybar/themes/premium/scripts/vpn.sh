#!/usr/bin/env bash
# VPN indicator. Visible only when a VPN connection is active.

vpn_active=$(nmcli -t -f TYPE,STATE,NAME connection show --active 2>/dev/null \
    | awk -F: 'tolower($1) ~ /vpn|wireguard/ && $2=="activated" {print $3; exit}')

if [[ -z "$vpn_active" ]] && command -v wg >/dev/null 2>&1; then
    wg_iface=$(wg show interfaces 2>/dev/null | tr ' ' '\n' | head -1)
    [[ -n "$wg_iface" ]] && vpn_active="$wg_iface (wg)"
fi

if [[ -n "$vpn_active" ]]; then
    echo "{\"text\":\"\",\"tooltip\":\"VPN actif : $vpn_active\",\"class\":\"active\"}"
else
    echo '{"text":"","tooltip":"","class":"inactive"}'
fi
