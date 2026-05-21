#!/usr/bin/env bash
# Unified system info script for eww desktop widget.
# Output: single JSON blob with all stats. Polled by eww every N seconds.

set -u

STATE_DIR="/tmp/eww-sysinfo"
mkdir -p "$STATE_DIR"

# -------- CPU --------
get_cpu() {
    # Usage % (delta since last call, stored in /tmp/eww-sysinfo/cpu)
    local prev_total=0 prev_idle=0
    if [ -f "$STATE_DIR/cpu" ]; then
        IFS=' ' read -r prev_total prev_idle < "$STATE_DIR/cpu"
    fi
    read -r _ user nice sys idle iowait irq softirq steal _ < /proc/stat
    local total=$((user + nice + sys + idle + iowait + irq + softirq + steal))
    local idle_all=$((idle + iowait))
    echo "$total $idle_all" > "$STATE_DIR/cpu"
    local diff_total=$((total - prev_total))
    local diff_idle=$((idle_all - prev_idle))
    local usage=0
    [ "$diff_total" -gt 0 ] && usage=$(( (1000 * (diff_total - diff_idle) / diff_total + 5) / 10 ))

    # Frequency: average over all cores (in MHz from cpuinfo)
    local freq_mhz
    freq_mhz=$(awk '/cpu MHz/ {sum+=$4; n++} END {if (n>0) printf "%.0f", sum/n}' /proc/cpuinfo)
    local freq_ghz
    freq_ghz=$(awk -v m="$freq_mhz" 'BEGIN {printf "%.2f", m/1000}')

    # Temp (Package id 0 from sensors)
    local temp
    temp=$(sensors 2>/dev/null | awk '/Package id 0:/ {gsub(/[+°C]/,"",$4); printf "%d", $4; exit}')
    [ -z "$temp" ] && temp=0

    echo "{\"usage\":$usage,\"freq_ghz\":\"$freq_ghz\",\"temp\":$temp}"
}

# -------- RAM --------
get_ram() {
    local total_kb used_kb avail_kb
    while read -r key val _; do
        case "$key" in
            MemTotal:)     total_kb=$val ;;
            MemAvailable:) avail_kb=$val ;;
        esac
    done < /proc/meminfo
    used_kb=$((total_kb - avail_kb))
    local percent=$(( used_kb * 100 / total_kb ))
    local used_gb total_gb
    used_gb=$(awk -v u="$used_kb" 'BEGIN {printf "%.1f", u/1024/1024}')
    total_gb=$(awk -v t="$total_kb" 'BEGIN {printf "%.1f", t/1024/1024}')
    echo "{\"percent\":$percent,\"used_gb\":\"$used_gb\",\"total_gb\":\"$total_gb\"}"
}

# -------- dGPU (NVIDIA discrete) --------
get_dgpu() {
    local line name usage vram_used vram_total temp
    line=$(nvidia-smi --query-gpu=name,utilization.gpu,memory.used,memory.total,temperature.gpu \
        --format=csv,noheader,nounits 2>/dev/null | head -1)
    if [ -z "$line" ]; then
        echo "{\"present\":false,\"usage\":0,\"vram_used\":0,\"vram_total\":0,\"temp\":0,\"name\":\"n/a\"}"
        return
    fi
    IFS=',' read -r name usage vram_used vram_total temp <<< "$line"
    name=$(echo "$name" | sed 's/^ *//;s/ *$//;s/NVIDIA GeForce //;s/ Laptop GPU//;s/ Max-Q.*//')
    usage=$(echo "$usage" | tr -d ' ')
    vram_used=$(echo "$vram_used" | tr -d ' ')
    vram_total=$(echo "$vram_total" | tr -d ' ')
    temp=$(echo "$temp" | tr -d ' ')
    echo "{\"present\":true,\"usage\":$usage,\"vram_used\":$vram_used,\"vram_total\":$vram_total,\"temp\":$temp,\"name\":\"$name\"}"
}

# -------- iGPU (Intel) --------
get_igpu() {
    # Find Intel card (i915 driver)
    local card=""
    for c in /sys/class/drm/card*; do
        [[ "$c" == *"-"* ]] && continue
        local drv=""
        [ -L "$c/device/driver" ] && drv=$(basename "$(readlink "$c/device/driver")")
        if [ "$drv" = "i915" ] || [ "$drv" = "xe" ]; then
            card="$c"
            break
        fi
    done
    if [ -z "$card" ]; then
        echo "{\"present\":false,\"usage\":0,\"freq_mhz\":0,\"max_mhz\":0,\"name\":\"n/a\"}"
        return
    fi

    local act_freq max_freq usage_pct
    act_freq=$(cat "$card/gt_act_freq_mhz" 2>/dev/null || echo 0)
    max_freq=$(cat "$card/gt_max_freq_mhz" 2>/dev/null || echo 0)
    if [ "$max_freq" -gt 0 ]; then
        usage_pct=$((act_freq * 100 / max_freq))
    else
        usage_pct=0
    fi

    # Name from lspci (short form)
    local name
    name=$(lspci 2>/dev/null | awk -F': ' '/VGA|3D|Display/ && /Intel/ {print $2; exit}' \
           | sed 's/Intel Corporation //;s/.*\[\(.*\)\].*/\1/;s/ Graphics$//' )
    [ -z "$name" ] && name="Intel iGPU"

    echo "{\"present\":true,\"usage\":$usage_pct,\"freq_mhz\":$act_freq,\"max_mhz\":$max_freq,\"name\":\"$name\"}"
}

# -------- Disks (all real mounts + USB) --------
get_disks() {
    # Filesystems considered "real" — internal HDD/SSD + removable USB drives.
    # Excludes tmpfs/devtmpfs/proc/sysfs/cgroup/squashfs/overlay/fuse-binary-mounts.
    local fs_re='^(ext[234]|btrfs|xfs|f2fs|vfat|exfat|ntfs3?)$'

    df -B1 --output=source,fstype,size,used,target 2>/dev/null | tail -n +2 \
    | awk -v re="$fs_re" '
        $2 ~ re && $5 != "" {
            # Build a human label from the mountpoint
            label = $5
            if (label == "/") label = "Root"
            else if (label == "/home") label = "Home"
            else if (label == "/boot") label = "Boot"
            else if (label ~ /^\/run\/media\//) {
                n = split(label, parts, "/")
                label = parts[n]
            } else if (label ~ /^\/mnt\//) {
                n = split(label, parts, "/")
                label = parts[n]
            }
            # Numeric values
            total_gb = $3 / 1024 / 1024 / 1024
            used_gb  = $4 / 1024 / 1024 / 1024
            pct      = ($3 > 0) ? int(($4 * 100 / $3) + 0.5) : 0
            entries[++n_entries] = sprintf("{\"label\":\"%s\",\"mount\":\"%s\",\"used_gb\":%.1f,\"total_gb\":%.1f,\"percent\":%d}", label, $5, used_gb, total_gb, pct)
        }
        END {
            printf "["
            for (i = 1; i <= n_entries; i++) {
                printf (i > 1 ? ",%s" : "%s"), entries[i]
            }
            printf "]"
        }
    '
}

# -------- Network (delta over interval) --------
get_net() {
    local iface
    iface=$(ip -br link | awk '$2 == "UP" && $1 != "lo" {print $1; exit}')
    [ -z "$iface" ] && { echo "{\"up_kbs\":\"0.0\",\"down_kbs\":\"0.0\",\"iface\":\"none\"}"; return; }

    local rx_now tx_now ts_now
    rx_now=$(cat "/sys/class/net/$iface/statistics/rx_bytes" 2>/dev/null || echo 0)
    tx_now=$(cat "/sys/class/net/$iface/statistics/tx_bytes" 2>/dev/null || echo 0)
    ts_now=$(date +%s%N)

    local rx_prev=0 tx_prev=0 ts_prev=0
    if [ -f "$STATE_DIR/net" ]; then
        IFS=' ' read -r rx_prev tx_prev ts_prev < "$STATE_DIR/net"
    fi
    echo "$rx_now $tx_now $ts_now" > "$STATE_DIR/net"

    local dt_s
    dt_s=$(awk -v n="$ts_now" -v p="$ts_prev" 'BEGIN {printf "%.3f", (n - p) / 1e9}')
    local down_kbs="0.0" up_kbs="0.0"
    if awk -v d="$dt_s" 'BEGIN {exit !(d > 0.1)}'; then
        down_kbs=$(awk -v r="$rx_now" -v p="$rx_prev" -v d="$dt_s" 'BEGIN {v=(r-p)/1024/d; if (v<0) v=0; printf "%.1f", v}')
        up_kbs=$(awk -v t="$tx_now" -v p="$tx_prev" -v d="$dt_s" 'BEGIN {v=(t-p)/1024/d; if (v<0) v=0; printf "%.1f", v}')
    fi
    echo "{\"up_kbs\":\"$up_kbs\",\"down_kbs\":\"$down_kbs\",\"iface\":\"$iface\"}"
}

# -------- Uptime --------
get_uptime() {
    local up_s d h m
    up_s=$(awk '{print int($1)}' /proc/uptime)
    d=$((up_s / 86400))
    h=$(( (up_s % 86400) / 3600 ))
    m=$(( (up_s % 3600) / 60 ))
    if [ "$d" -gt 0 ]; then
        echo "\"${d}d ${h}h ${m}m\""
    elif [ "$h" -gt 0 ]; then
        echo "\"${h}h ${m}m\""
    else
        echo "\"${m}m\""
    fi
}

# -------- Load average --------
get_load() {
    read -r l1 l5 l15 _ < /proc/loadavg
    echo "{\"l1\":\"$l1\",\"l5\":\"$l5\",\"l15\":\"$l15\"}"
}

case "${1:-all}" in
    --all|all)
        printf '{"cpu":%s,"ram":%s,"dgpu":%s,"igpu":%s,"disks":%s,"net":%s,"uptime":%s,"load":%s}\n' \
            "$(get_cpu)" "$(get_ram)" "$(get_dgpu)" "$(get_igpu)" "$(get_disks)" "$(get_net)" "$(get_uptime)" "$(get_load)"
        ;;
    --cpu)      get_cpu ;;
    --ram)      get_ram ;;
    --dgpu)     get_dgpu ;;
    --igpu)     get_igpu ;;
    --disks)    get_disks ;;
    --net)      get_net ;;
    --uptime)   get_uptime ;;
    --load)     get_load ;;
    *)
        echo "Usage: $0 [--all|--cpu|--ram|--gpu|--disk|--net|--uptime|--load]" >&2
        exit 1
        ;;
esac
