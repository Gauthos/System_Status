#!/bin/bash

# Colors
CYAN='\e[36m'
GREEN='\e[32m'
YELLOW='\e[33m'
RED='\e[31m'
RESET='\e[0m'
WHITE='\e[97m'

# Terminal dimensions
COLUMNS=$(tput cols 2>/dev/null || echo 80)
WIDTH=$((COLUMNS - 10))
INFO_WIDTH=18

# OS and architecture detection
detect_os() {
    # Default to Linux
    OS="linux"
    DISTRO="unknown"
    
    # Check if FreeBSD
    if [ -f "/etc/rc.subr" ] || uname -s | grep -q "FreeBSD"; then
        OS="freebsd"
        DISTRO="FreeBSD"
        return
    fi
    
    # Try to get info from /etc/os-release
    if [ -f "/etc/os-release" ]; then
        source /etc/os-release
        DISTRO="${NAME}"
    
    # For older RHEL-based systems
    elif [ -f "/etc/redhat-release" ]; then
        DISTRO=$(cat /etc/redhat-release)
    
    # For older Debian-based systems
    elif [ -f "/etc/debian_version" ]; then
        DISTRO="Debian $(cat /etc/debian_version)"
    
    # For older SUSE-based systems
    elif [ -f "/etc/SuSE-release" ]; then
        DISTRO="SuSE"
    
    # For Alpine Linux
    elif [ -f "/etc/alpine-release" ]; then
        DISTRO="Alpine $(cat /etc/alpine-release)"
    
    # For Arch Linux
    elif [ -f "/etc/arch-release" ]; then
        DISTRO="Arch Linux"
    fi
}

# Architecture detection
detect_arch() {
    # Get architecture
    ARCH=$(uname -m)
    
    # Normalize architecture names
    case "$ARCH" in
        x86_64)
            ARCH_NAME="amd64"
            ;;
        aarch64|arm64)
            ARCH_NAME="arm64"
            ;;
        armv7l|armv6l)
            ARCH_NAME="arm"
            ;;
        i386|i686)
            ARCH_NAME="i386"
            ;;
        *)
            ARCH_NAME="$ARCH"
            ;;
    esac
}

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

# Get CPU info based on OS
get_cpu_info() {
    if [ "$OS" = "freebsd" ]; then
        # FreeBSD CPU info
        CPU_MODEL=$(sysctl -n hw.model 2>/dev/null)
        CPU_CORES=$(sysctl -n hw.ncpu 2>/dev/null)
        CPU_FREQ=$(sysctl -n dev.cpu.0.freq 2>/dev/null)
        [ -z "$CPU_FREQ" ] && CPU_FREQ="Unknown"
    else
        # Linux CPU info
        if command -v lscpu >/dev/null 2>&1; then
            CPU_MODEL=$(lscpu | grep "Model name" | sed 's/Model name:[ \t]*//')
            CPU_CORES=$(nproc)
            CPU_FREQ=$(lscpu | grep "CPU MHz" | sed 's/CPU MHz:[ \t]*//')
        else
            # Fallback if lscpu is not available
            CPU_MODEL=$(grep "model name" /proc/cpuinfo | head -1 | sed 's/model name[ \t]*:[ \t]*//')
            CPU_CORES=$(grep -c "processor" /proc/cpuinfo)
            CPU_FREQ=$(grep "cpu MHz" /proc/cpuinfo | head -1 | sed 's/cpu MHz[ \t]*:[ \t]*//')
        fi
        
        # If CPU model is still empty, try another method
        if [ -z "$CPU_MODEL" ]; then
            CPU_MODEL=$(grep "Hardware" /proc/cpuinfo | head -1 | sed 's/Hardware[ \t]*:[ \t]*//')
            [ -z "$CPU_MODEL" ] && CPU_MODEL="Unknown CPU"
        fi
        
        # If CPU frequency is empty, try another method
        if [ -z "$CPU_FREQ" ]; then
            CPU_FREQ=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq 2>/dev/null)
            if [ -n "$CPU_FREQ" ]; then
                CPU_FREQ=$(echo "$CPU_FREQ/1000" | bc -l 2>/dev/null || echo "$CPU_FREQ/1000" | awk '{printf "%.3f", $1}')
            else
                CPU_FREQ="Unknown"
            fi
        fi
    fi
}

# Get memory info based on OS
get_memory_info() {
    if [ "$OS" = "freebsd" ]; then
        # FreeBSD memory info
        MEM_TOTAL=$(sysctl -n hw.physmem 2>/dev/null)
        MEM_TOTAL=$((MEM_TOTAL / 1024 / 1024)) # Convert to MB
        
        # Use vmstat to get memory usage
        MEM_USED=$(vmstat -H | awk 'NR==3{print $3}' | sed 's/M//')
        
        # Calculate memory percentage
        MEM_PERCENT=$(echo "$MEM_USED $MEM_TOTAL" | awk '{printf "%.1f", ($1/$2)*100}')
    else
        # Linux memory info
        if command -v free >/dev/null 2>&1; then
            MEM_TOTAL=$(free -m | awk '/Mem:/ {print $2}')
            MEM_USED=$(free -m | awk '/Mem:/ {print $3}')
            MEM_PERCENT=$(echo "$MEM_USED $MEM_TOTAL" | awk '{printf "%.1f", ($1/$2)*100}')
        else
            # Fallback if free is not available
            MEM_TOTAL=$(grep MemTotal /proc/meminfo | awk '{print $2/1024}' | cut -f1 -d".")
            MEM_FREE=$(grep MemFree /proc/meminfo | awk '{print $2/1024}' | cut -f1 -d".")
            MEM_BUFFERS=$(grep Buffers /proc/meminfo | awk '{print $2/1024}' | cut -f1 -d".")
            MEM_CACHED=$(grep "^Cached" /proc/meminfo | awk '{print $2/1024}' | cut -f1 -d".")
            MEM_USED=$((MEM_TOTAL - MEM_FREE - MEM_BUFFERS - MEM_CACHED))
            MEM_PERCENT=$(echo "$MEM_USED $MEM_TOTAL" | awk '{printf "%.1f", ($1/$2)*100}')
        fi
    fi
}

# Get swap info based on OS
get_swap_info() {
    if [ "$OS" = "freebsd" ]; then
        # FreeBSD swap info
        SWAP_INFO=$(swapinfo -k 2>/dev/null)
        if [ $? -eq 0 ] && [ -n "$SWAP_INFO" ]; then
            SWAP_TOTAL=$(echo "$SWAP_INFO" | awk 'NR>1{sum+=$2} END{print sum/1024}' | cut -f1 -d".")
            SWAP_USED=$(echo "$SWAP_INFO" | awk 'NR>1{sum+=$3} END{print sum/1024}' | cut -f1 -d".")
            if [ "$SWAP_TOTAL" -gt 0 ]; then
                SWAP_PERCENT=$(echo "$SWAP_USED $SWAP_TOTAL" | awk '{printf "%.1f", ($1/$2)*100}')
            else
                SWAP_PERCENT="0.0"
            fi
        else
            SWAP_TOTAL=0
            SWAP_USED=0
            SWAP_PERCENT="0.0"
        fi
    else
        # Linux swap info
        if command -v free >/dev/null 2>&1; then
            SWAP_TOTAL=$(free -m | awk '/Swap:/ {print $2}')
            SWAP_USED=$(free -m | awk '/Swap:/ {print $3}')
            if [ "$SWAP_TOTAL" -gt 0 ]; then
                SWAP_PERCENT=$(echo "$SWAP_USED $SWAP_TOTAL" | awk '{printf "%.1f", ($1/$2)*100}')
            else
                SWAP_PERCENT="0.0"
            fi
        else
            # Fallback if free is not available
            SWAP_TOTAL=$(grep SwapTotal /proc/meminfo | awk '{print $2/1024}' | cut -f1 -d".")
            SWAP_FREE=$(grep SwapFree /proc/meminfo | awk '{print $2/1024}' | cut -f1 -d".")
            SWAP_USED=$((SWAP_TOTAL - SWAP_FREE))
            if [ "$SWAP_TOTAL" -gt 0 ]; then
                SWAP_PERCENT=$(echo "$SWAP_USED $SWAP_TOTAL" | awk '{printf "%.1f", ($1/$2)*100}')
            else
                SWAP_PERCENT="0.0"
            fi
        fi
    fi
}

# Get load average based on OS
get_load_average() {
    if [ "$OS" = "freebsd" ]; then
        # FreeBSD load average
        LOAD_AVG=$(sysctl -n vm.loadavg 2>/dev/null | sed 's/{ //' | sed 's/ }//')
        LOAD_1=$(echo $LOAD_AVG | awk '{print $1}')
        LOAD_5=$(echo $LOAD_AVG | awk '{print $2}')
        LOAD_15=$(echo $LOAD_AVG | awk '{print $3}')
    else
        # Linux load average
        if [ -f "/proc/loadavg" ]; then
            LOAD_1=$(cat /proc/loadavg | awk '{print $1}')
            LOAD_5=$(cat /proc/loadavg | awk '{print $2}')
            LOAD_15=$(cat /proc/loadavg | awk '{print $3}')
        else
            # Fallback using uptime command
            UPTIME_OUTPUT=$(uptime)
            LOAD_1=$(echo "$UPTIME_OUTPUT" | awk -F'load average: ' '{print $2}' | awk -F',' '{print $1}')
            LOAD_5=$(echo "$UPTIME_OUTPUT" | awk -F'load average: ' '{print $2}' | awk -F',' '{print $2}')
            LOAD_15=$(echo "$UPTIME_OUTPUT" | awk -F'load average: ' '{print $2}' | awk -F',' '{print $3}')
        fi
    fi
}

# Get filesystem info based on OS
get_filesystem_info() {
    if [ "$OS" = "freebsd" ]; then
        # FreeBSD filesystem info
        FS_OUTPUT=$(df -h -t ufs,zfs 2>/dev/null)
    else
        # Linux filesystem info - exclude common virtual filesystems
        FS_OUTPUT=$(df -h -x tmpfs -x devtmpfs -x squashfs -x udev 2>/dev/null)
        if [ $? -ne 0 ]; then
            # Try without exclusions if df doesn't support -x
            FS_OUTPUT=$(df -h | grep -vE "^(Filesystem|tmpfs|devtmpfs|udev)" 2>/dev/null)
        fi
    fi
}

# Initialize system detection
detect_os
detect_arch

# Get CPU info
get_cpu_info

# Get memory info
get_memory_info

# Get swap info
get_swap_info

# Get load average
get_load_average

# Clear screen and display header
clear
echo ""
echo -e "${WHITE}[System Info]${RESET}"
echo ""

# Current time with timezone
CURRENT_TIME=$(date +"%Y-%m-%d,%H:%M:%S %Z")
printf "%-${INFO_WIDTH}s : %s\n" "Current Time" "$CURRENT_TIME"

# OS version
printf "%-${INFO_WIDTH}s : %s\n" "OS" "$DISTRO"

# Architecture
printf "%-${INFO_WIDTH}s : %s (%s)\n" "Architecture" "$ARCH" "$ARCH_NAME"

# Kernel
KERNEL=$(uname -r)
printf "%-${INFO_WIDTH}s : %s\n" "Kernel" "$KERNEL"

# Uptime
if [ "$OS" = "freebsd" ]; then
    UPTIME=$(uptime | sed 's/.*up //' | sed 's/,.*//')
else
    UPTIME=$(uptime -p 2>/dev/null)
    if [ $? -ne 0 ]; then
        # Fallback for systems without uptime -p
        UPTIME_SEC=$(cat /proc/uptime 2>/dev/null | awk '{print $1}')
        if [ -n "$UPTIME_SEC" ]; then
            UPTIME=$(awk -v sec="$UPTIME_SEC" 'BEGIN{
                days=int(sec/86400);
                hours=int((sec%86400)/3600);
                mins=int((sec%3600)/60);
                printf "%d days, %d hours, %d minutes", days, hours, mins
            }')
        else
            UPTIME=$(uptime | sed 's/.*up //' | sed 's/,.*//')
        fi
    else
        UPTIME=${UPTIME#up }
    fi
fi
printf "%-${INFO_WIDTH}s : %s\n" "Uptime" "$UPTIME"

# IP Address - try different methods
IP=""
if command -v hostname >/dev/null 2>&1; then
    IP=$(hostname -I 2>/dev/null | awk '{print $1}')
fi
if [ -z "$IP" ] && command -v ip >/dev/null 2>&1; then
    IP=$(ip addr show | grep 'inet ' | grep -v 127.0.0 | head -1 | awk '{print $2}' | cut -d/ -f1)
fi
if [ -z "$IP" ] && command -v ifconfig >/dev/null 2>&1; then
    IP=$(ifconfig | grep 'inet ' | grep -v 127.0.0 | head -1 | awk '{print $2}' | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')
fi
printf "%-${INFO_WIDTH}s : %s\n" "IP Address" "$IP"

# Hostname
HOSTNAME=$(hostname 2>/dev/null)
printf "%-${INFO_WIDTH}s : %s\n" "Hostname" "$HOSTNAME"

echo ""

# CPU info display
printf "%-${INFO_WIDTH}s : %s\n" "CPU" "$CPU_MODEL"
printf "%-${INFO_WIDTH}s : %s\n" "CPU Cores" "$CPU_CORES"

if [ "$CPU_FREQ" != "Unknown" ]; then
    printf "%-${INFO_WIDTH}s : %.2f MHz\n" "CPU Frequency" "$CPU_FREQ"
else
    printf "%-${INFO_WIDTH}s : %s\n" "CPU Frequency" "$CPU_FREQ"
fi

# Memory info display
printf "%-${INFO_WIDTH}s : %dMB / %dMB (${GREEN}%s%%${RESET} Used) " "Memory" "$MEM_USED" "$MEM_TOTAL" "$MEM_PERCENT"
create_progress_bar ${MEM_PERCENT%.*}
echo ""

# Swap info display
printf "%-${INFO_WIDTH}s : %dMB / %dMB (${GREEN}%s%%${RESET} Used) " "SWAP" "$SWAP_USED" "$SWAP_TOTAL" "$SWAP_PERCENT"
create_progress_bar ${SWAP_PERCENT%.*}
echo ""

# Load average display
printf "%-${INFO_WIDTH}s : ${GREEN}%s${RESET}(1m) ${GREEN}%s${RESET}(5m) ${GREEN}%s${RESET}(15m)\n" "Load avg" "$LOAD_1" "$LOAD_5" "$LOAD_15"

# Process count - use different methods based on OS
if [ "$OS" = "freebsd" ]; then
    PROC_TOTAL=$(ps -ax | wc -l)
    printf "%-${INFO_WIDTH}s : %d processes\n" "Processes" "$PROC_TOTAL"
else
    if command -v ps >/dev/null 2>&1; then
        PROC_ROOT=$(ps aux 2>/dev/null | grep root | wc -l)
        PROC_USER=$(ps aux 2>/dev/null | grep -v root | grep -v COMMAND | wc -l)
        PROC_TOTAL=$(( PROC_ROOT + PROC_USER ))
        printf "%-${INFO_WIDTH}s : %d(root) %d(user) %d(total)\n" "Processes" "$PROC_ROOT" "$PROC_USER" "$PROC_TOTAL"
    else
        PROC_TOTAL=$(ls /proc/ | grep -E '^[0-9]+$' | wc -l)
        printf "%-${INFO_WIDTH}s : %d processes\n" "Processes" "$PROC_TOTAL"
    fi
fi

# Users logged on
if command -v who >/dev/null 2>&1; then
    USERS_ON=$(who | wc -l)
    printf "%-${INFO_WIDTH}s : %d users\n" "Users Logged on" "$USERS_ON"
fi

echo ""

# Last boot & login info (if available)
if command -v who >/dev/null 2>&1; then
    LAST_BOOT=$(who -b 2>/dev/null | awk '{print $3, $4}')
    if [ -n "$LAST_BOOT" ]; then
        if [[ $LAST_BOOT != *"-"* ]]; then
            CURRENT_YEAR=$(date +"%Y")
            LAST_BOOT="$CURRENT_YEAR-$LAST_BOOT"
        fi
        printf "%-${INFO_WIDTH}s : %s %s\n" "Last Boot" "$LAST_BOOT" "$(date +%Z)"
    fi
fi

if command -v last >/dev/null 2>&1; then
    LAST_LOGIN_INFO=$(last -1 -R 2>/dev/null | head -1)
    if [ -n "$LAST_LOGIN_INFO" ] && [[ "$LAST_LOGIN_INFO" != *"wtmp begins"* ]]; then
        LAST_LOGIN_USER=$(echo "$LAST_LOGIN_INFO" | awk '{print $1}')
        LAST_LOGIN_IP=$(echo "$LAST_LOGIN_INFO" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')
        if [ -z "$LAST_LOGIN_IP" ]; then
            LAST_LOGIN_IP="local"
        fi
        LAST_LOGIN_TIME=$(echo "$LAST_LOGIN_INFO" | awk '{print $5, $6, $7, $8}')
        printf "%-${INFO_WIDTH}s : %s (%s) at %s %s\n" "Last Login" "$LAST_LOGIN_USER" "$LAST_LOGIN_IP" "$LAST_LOGIN_TIME" "$(date +%Z)"
    fi
fi

echo ""
echo -e "${WHITE}[Filesystem Info]${RESET}"
echo ""

# Get filesystem info and display
get_filesystem_info

echo "$FS_OUTPUT" | tail -n +2 | while read line; do
    MOUNT=$(echo "$line" | awk '{print $NF}')
    SIZE=$(echo "$line" | awk '{print $2}')
    USED=$(echo "$line" | awk '{print $3}')
    PERCENT=$(echo "$line" | awk '{print $5}' | sed 's/[^0-9]//g')
    
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