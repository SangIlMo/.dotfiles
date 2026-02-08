#!/bin/bash
# sys-info.sh - Display CPU, Memory, Battery info for tmux status bar
# Output: CPU:12% MEM:45% BAT:95%⚡

# Color thresholds: green<70, yellow<90, red>=90
color_by_value() {
    local val=$1
    if [ "$val" -ge 90 ]; then
        echo "#[fg=#f38ba8]"  # red
    elif [ "$val" -ge 70 ]; then
        echo "#[fg=#f9e2af]"  # yellow
    else
        echo "#[fg=#a6e3a1]"  # green
    fi
}

# Battery: inverse thresholds (red<=20, yellow<=50, green>50)
color_by_battery() {
    local val=$1
    if [ "$val" -le 20 ]; then
        echo "#[fg=#f38ba8]"  # red
    elif [ "$val" -le 50 ]; then
        echo "#[fg=#f9e2af]"  # yellow
    else
        echo "#[fg=#a6e3a1]"  # green
    fi
}

# CPU usage (sum of all process CPU)
cpu=$(ps -A -o %cpu | awk '{s+=$1} END {printf "%d", s+0.5}')
# Cap at reasonable values (multi-core can exceed 100%)
nproc=$(sysctl -n hw.ncpu 2>/dev/null || echo 8)
max_cpu=$((nproc * 100))
cpu_pct=$((cpu * 100 / max_cpu))
[ "$cpu_pct" -gt 100 ] && cpu_pct=100

cpu_color=$(color_by_value "$cpu_pct")

# Memory usage via vm_stat
page_size=$(sysctl -n hw.pagesize 2>/dev/null || echo 16384)
vm_stat_out=$(vm_stat 2>/dev/null)
active=$(echo "$vm_stat_out" | awk '/Pages active/ {gsub(/\./,"",$3); print $3}')
wired=$(echo "$vm_stat_out" | awk '/Pages wired/ {gsub(/\./,"",$4); print $4}')
compressed=$(echo "$vm_stat_out" | awk '/Pages occupied by compressor/ {gsub(/\./,"",$5); print $5}')
total_mem=$(sysctl -n hw.memsize 2>/dev/null || echo 17179869184)

used_pages=$(( ${active:-0} + ${wired:-0} + ${compressed:-0} ))
used_bytes=$(( used_pages * page_size ))
mem_pct=$(( used_bytes * 100 / total_mem ))

mem_color=$(color_by_value "$mem_pct")

# Battery
bat_info=$(pmset -g batt 2>/dev/null)
bat_pct=$(echo "$bat_info" | grep -o '[0-9]*%' | head -1 | tr -d '%')

bat_str=""
if [ -n "$bat_pct" ]; then
    bat_color=$(color_by_battery "$bat_pct")
    # Charging indicator
    if echo "$bat_info" | grep -q "charging"; then
        bat_icon="⚡"
    elif echo "$bat_info" | grep -q "charged"; then
        bat_icon="⚡"
    else
        bat_icon=""
    fi
    bat_str=" ${bat_color}BAT:${bat_pct}%${bat_icon}"
fi

echo "${cpu_color}CPU:${cpu_pct}% ${mem_color}MEM:${mem_pct}%${bat_str}"
