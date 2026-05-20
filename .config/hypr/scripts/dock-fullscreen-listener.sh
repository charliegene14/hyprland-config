#!/usr/bin/env bash
# Auto-hide dock when any window enters fullscreen, show when leaving.
# Listens to Hyprland events via the socket2 IPC.

SOCK="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
[[ ! -S "$SOCK" ]] && {
    echo "Hyprland socket not found: $SOCK" >&2
    exit 1
}

hide() {
    pkill -SIGRTMIN+3 nwg-dock-hyprland 2>/dev/null
}
show() {
    pkill -SIGRTMIN+2 nwg-dock-hyprland 2>/dev/null
}

state="visible"
socat -u "UNIX-CONNECT:$SOCK" - | while IFS= read -r line; do
    case "$line" in
        fullscreen\>\>1*)
            [[ "$state" == "visible" ]] && hide && state="hidden"
            ;;
        fullscreen\>\>0*)
            [[ "$state" == "hidden" ]] && show && state="visible"
            ;;
    esac
done
