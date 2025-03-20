#!/bin/bash

# Colors
CYAN='\e[36m'
GREEN='\e[32m'
RESET='\e[0m'
WHITE='\e[97m'

# Terminal dimensions
COLUMNS=$(tput cols)
WIDTH=$((COLUMNS - 10))

# Function to create progress bar without using bc
create_progress_bar() {
    local usage=$1
    local bar_size=15
    
    # Handle non-numeric or empty input
    if ! [[ "$usage" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        usage=0
    fi
    
    # Integer division using bash arithmetic
    local filled=$(( usage * bar_size / 100 ))
    
    # Handle zero case
    if [ "$usage" -lt 1 ]; then
        filled=0
    fi

    local empty=$((bar_size - filled))
    
    printf "["
    printf "%${filled}s" | tr ' ' '='
    printf "%${empty}s" | tr ' ' ' '
    printf "]"
}

clear
echo ""
echo -e "${WHITE}[System Info]${RESET}"
echo ""

# Current time
CURRENT_TIME=$(date +"%Y-%m-%d,%H:%M:%S")
printf "%-18s : %s\n" "Current Time" "$CURRENT_TIME"

# Linux version
VERSION=$(cat /etc/os-release | grep "PRETTY_NAME" | cut -d "\"" -f 2)
printf "%-18s : %s\n" "Version" "$VERSION"

# Kernel
KERNEL=$(uname -r)
printf "%-18s : %s\n" "Kernel" "$KERNEL"

# Uptime
UPTIME=$(uptime -p | sed 's/up //')
printf "%-18s : %s\n" "Uptime" "$UPTIME"

# IP Address
IP=$(hostname -I | awk '{print $1}')
printf "%-18s : %s\n" "Ipaddr" "$IP"

# Hostname
HOSTNAME=$(hostname -f)
printf "%-18s : %s\n" "Hostname" "$HOSTNAME"

echo ""

# CPU info
CPU_MODEL=$(lscpu | grep "Model name" | sed 's/Model name:[ \t]*//')
printf "%-18s : %s\n" "Cpu" "$CPU_MODEL"

# Memory
MEM_TOTAL=$(free -m | awk '/Mem:/ {print $2}')
MEM_USED=$(free -m | awk '/Mem:/ {print $3}')
# Calculate percentage using awk instead of bc
MEM_PERCENT=$(awk "BEGIN {printf \"%.1f\", $MEM_USED*100/$MEM_TOTAL}")
printf "%-18s : %dMB / %dMB (${GREEN}%s%%${RESET} Used) " "Memory" "$MEM_USED" "$MEM_TOTAL" "$MEM_PERCENT"
create_progress_bar ${MEM_PERCENT%.*}
echo ""

# Swap
SWAP_TOTAL=$(free -m | awk '/Swap:/ {print $2}')
SWAP_USED=$(free -m | awk '/Swap:/ {print $3}')
if [ "$SWAP_TOTAL" -gt "0" ]; then
    # Calculate percentage using awk instead of bc
    SWAP_PERCENT=$(awk "BEGIN {printf \"%.1f\", $SWAP_USED*100/$SWAP_TOTAL}")
else
    SWAP_PERCENT="0.0"
fi
printf "%-18s : %dMB / %dMB (${GREEN}%s%%${RESET} Used) " "SWAP" "$SWAP_USED" "$SWAP_TOTAL" "$SWAP_PERCENT"
create_progress_bar ${SWAP_PERCENT%.*}
echo ""

# Load average
LOAD_1=$(cat /proc/loadavg | awk '{print $1}')
LOAD_5=$(cat /proc/loadavg | awk '{print $2}')
LOAD_15=$(cat /proc/loadavg | awk '{print $3}')
printf "%-18s : ${GREEN}%s${RESET}(1m) ${GREEN}%s${RESET}(5m) ${GREEN}%s${RESET}(15m)\n" "Load avg" "$LOAD_1" "$LOAD_5" "$LOAD_15"

# Process count
PROC_ROOT=$(ps aux | grep root | wc -l)
PROC_USER=$(ps aux | grep -v root | grep -v COMMAND | wc -l)
PROC_TOTAL=$(( PROC_ROOT + PROC_USER ))
printf "%-18s : %d(root) %d(user) %d(total)\n" "Processes" "$PROC_ROOT" "$PROC_USER" "$PROC_TOTAL"

# Users logged on
USERS_ON=$(who | wc -l)
printf "%-18s : %d users\n" "Users Logged on" "$USERS_ON"

echo ""

# Last boot & login
LAST_BOOT=$(who -b | awk '{print $3, $4}')
printf "%-18s : %s\n" "Last Boot" "$LAST_BOOT"

LAST_LOGIN_INFO=$(last -1 -R | head -1)
LAST_LOGIN_USER=$(echo "$LAST_LOGIN_INFO" | awk '{print $1}')
LAST_LOGIN_IP=$(echo "$LAST_LOGIN_INFO" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')
LAST_LOGIN_TIME=$(echo "$LAST_LOGIN_INFO" | awk '{print $5, $6, $7}')
printf "%-18s : %s (%s) at %s\n" "Last Login" "$LAST_LOGIN_USER" "$LAST_LOGIN_IP" "$LAST_LOGIN_TIME"

echo ""
echo -e "${WHITE}[Filesystem Info]${RESET}"
echo ""

# Get mounted filesystems and usage
df -h | grep -v "tmpfs" | grep -v "devtmpfs" | grep -v "loop" | tail -n +2 | while read line; do
    MOUNT=$(echo "$line" | awk '{print $6}')
    SIZE=$(echo "$line" | awk '{print $2}')
    USED=$(echo "$line" | awk '{print $3}')
    PERCENT=$(echo "$line" | awk '{print $5}' | sed 's/%//')
    
    # Convert to integer for progress bar
    PERCENT_INT=${PERCENT:-0}
    
    printf "%-10s %-8s %s / %s (${GREEN}%s%%${RESET} Used) " "Mounted:" "$MOUNT" "$USED" "$SIZE" "$PERCENT"
    create_progress_bar $PERCENT_INT
    echo ""
done

echo ""