#!/bin/bash

# Colors
CYAN='\e[36m'
GREEN='\e[32m'
YELLOW='\e[33m'
RESET='\e[0m'
WHITE='\e[97m'

# Terminal dimensions
COLUMNS=$(tput cols)
WIDTH=$((COLUMNS - 10))
INFO_WIDTH=18

# Function to create progress bar
create_progress_bar() {
    local usage=$1
    local bar_size=20
    
    if ! [[ "$usage" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        usage=0
    fi
    
    local filled=$(( usage * bar_size / 100 ))
    
    if [ "$usage" -gt 0 ] && [ "$filled" -eq 0 ]; then
        filled=1
    fi

    local empty=$((bar_size - filled))
    
    local bar_color=$GREEN
    if [ "$usage" -gt 80 ]; then
        bar_color='\e[31m'
    elif [ "$usage" -gt 50 ]; then
        bar_color=$YELLOW
    fi
    
    printf "["
    printf "${bar_color}%${filled}s${RESET}" | tr ' ' '='
    printf "%${empty}s" | tr ' ' ' '
    printf "]"
}

# Function for filesystem progress bars
create_fs_progress_bar() {
    local percent=$1
    local bar_size=$((COLUMNS - 2))
    
    local filled=$(( percent * bar_size / 100 ))
    
    if [ "$percent" -gt 0 ] && [ "$filled" -eq 0 ]; then
        filled=1
    fi
    
    local empty=$((bar_size - filled))
    
    local bar_color=$GREEN
    if [ "$percent" -gt 80 ]; then
        bar_color='\e[31m'
    elif [ "$percent" -gt 50 ]; then
        bar_color=$YELLOW
    fi
    
    printf "["
    printf "${bar_color}%${filled}s${RESET}" | tr ' ' '='
    printf "%${empty}s" | tr ' ' ' '
    printf "]\n"
}

clear
echo ""
echo -e "${WHITE}[System Info]${RESET}"
echo ""

# Current time with timezone
CURRENT_TIME=$(date +"%Y-%m-%d,%H:%M:%S %Z")
printf "%-${INFO_WIDTH}s : %s\n" "Current Time" "$CURRENT_TIME"

# Linux version
VERSION=$(cat /etc/os-release | grep "PRETTY_NAME" | cut -d "\"" -f 2)
printf "%-${INFO_WIDTH}s : %s\n" "Version" "$VERSION"

# Kernel
KERNEL=$(uname -r)
printf "%-${INFO_WIDTH}s : %s\n" "Kernel" "$KERNEL"

# Uptime
UPTIME=$(uptime -p | sed 's/up //')
printf "%-${INFO_WIDTH}s : %s\n" "Uptime" "$UPTIME"

# IP Address
IP=$(hostname -I | awk '{print $1}')
printf "%-${INFO_WIDTH}s : %s\n" "Ipaddr" "$IP"

# Hostname
HOSTNAME=$(hostname -f)
printf "%-${INFO_WIDTH}s : %s\n" "Hostname" "$HOSTNAME"

echo ""

# CPU info
CPU_MODEL=$(lscpu | grep "Model name" | sed 's/Model name:[ \t]*//')
CPU_MODEL_LENGTH=${#CPU_MODEL}
COLUMNS_AVAILABLE=$((COLUMNS - INFO_WIDTH - 3))

if [ $CPU_MODEL_LENGTH -gt $COLUMNS_AVAILABLE ]; then
    printf "%-${INFO_WIDTH}s : %s\n" "Cpu" "$CPU_MODEL"
else
    printf "%-${INFO_WIDTH}s : %s\n" "Cpu" "$CPU_MODEL"
fi

# Memory
MEM_TOTAL=$(free -m | awk '/Mem:/ {print $2}')
MEM_USED=$(free -m | awk '/Mem:/ {print $3}')
MEM_PERCENT=$(awk "BEGIN {printf \"%.1f\", $MEM_USED*100/$MEM_TOTAL}")
printf "%-${INFO_WIDTH}s : %dMB / %dMB (${GREEN}%s%%${RESET} Used) " "Memory" "$MEM_USED" "$MEM_TOTAL" "$MEM_PERCENT"
create_progress_bar ${MEM_PERCENT%.*}
echo ""

# Swap
SWAP_TOTAL=$(free -m | awk '/Swap:/ {print $2}')
SWAP_USED=$(free -m | awk '/Swap:/ {print $3}')
if [ "$SWAP_TOTAL" -gt "0" ]; then
    SWAP_PERCENT=$(awk "BEGIN {printf \"%.1f\", $SWAP_USED*100/$SWAP_TOTAL}")
else
    SWAP_PERCENT="0.0"
fi
printf "%-${INFO_WIDTH}s : %dMB / %dMB (${GREEN}%s%%${RESET} Used) " "SWAP" "$SWAP_USED" "$SWAP_TOTAL" "$SWAP_PERCENT"
create_progress_bar ${SWAP_PERCENT%.*}
echo ""

# Load average
LOAD_1=$(cat /proc/loadavg | awk '{print $1}')
LOAD_5=$(cat /proc/loadavg | awk '{print $2}')
LOAD_15=$(cat /proc/loadavg | awk '{print $3}')
printf "%-${INFO_WIDTH}s : ${GREEN}%s${RESET}(1m) ${GREEN}%s${RESET}(5m) ${GREEN}%s${RESET}(15m)\n" "Load avg" "$LOAD_1" "$LOAD_5" "$LOAD_15"

# Process count
PROC_ROOT=$(ps aux | grep root | wc -l)
PROC_USER=$(ps aux | grep -v root | grep -v COMMAND | wc -l)
PROC_TOTAL=$(( PROC_ROOT + PROC_USER ))
printf "%-${INFO_WIDTH}s : %d(root) %d(user) %d(total)\n" "Processes" "$PROC_ROOT" "$PROC_USER" "$PROC_TOTAL"

# Users logged on
USERS_ON=$(who | wc -l)
printf "%-${INFO_WIDTH}s : %d users\n" "Users Logged on" "$USERS_ON"

echo ""

# Last boot & login
LAST_BOOT=$(who -b | awk '{print $3, $4}')
if [[ $LAST_BOOT != *"-"* ]]; then
    CURRENT_YEAR=$(date +"%Y")
    LAST_BOOT="$CURRENT_YEAR-$LAST_BOOT"
fi
printf "%-${INFO_WIDTH}s : %s %s\n" "Last Boot" "$LAST_BOOT" "$(date +%Z)"

LAST_LOGIN_INFO=$(last -1 -R | head -1)
LAST_LOGIN_USER=$(echo "$LAST_LOGIN_INFO" | awk '{print $1}')
LAST_LOGIN_IP=$(echo "$LAST_LOGIN_INFO" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')
if [ -z "$LAST_LOGIN_IP" ]; then
    LAST_LOGIN_IP="local"
fi
LAST_LOGIN_TIME=$(echo "$LAST_LOGIN_INFO" | awk '{print $5, $6, $7, $8}')
printf "%-${INFO_WIDTH}s : %s (%s) at %s %s\n" "Last Login" "$LAST_LOGIN_USER" "$LAST_LOGIN_IP" "$LAST_LOGIN_TIME" "$(date +%Z)"

echo ""
echo -e "${WHITE}[Filesystem Info]${RESET}"
echo ""

# Filesystem display
df -h | grep -v "tmpfs" | grep -v "devtmpfs" | grep -v "loop" | tail -n +2 | while read line; do
    MOUNT=$(echo "$line" | awk '{print $6}')
    SIZE=$(echo "$line" | awk '{print $2}')
    USED=$(echo "$line" | awk '{print $3}')
    PERCENT=$(echo "$line" | awk '{print $5}' | sed 's/%//')
    
    if [ -z "$PERCENT" ]; then
        PERCENT="0"
    fi

    PERCENT_COLOR=$GREEN
    if [ "$PERCENT" -gt 80 ]; then
        PERCENT_COLOR='\e[31m'
    elif [ "$PERCENT" -gt 50 ]; then
        PERCENT_COLOR=$YELLOW
    fi
    
    printf "Mounted: %-6s %s / %s (${PERCENT_COLOR}%s%%${RESET} Used)\n" "$MOUNT" "$USED" "$SIZE" "$PERCENT"
    create_fs_progress_bar "$PERCENT"
done

echo ""