# 系统状态显示工具自定义指南

本文档将帮助您根据自己的需求自定义系统状态显示工具。

## 基本配置

系统状态显示脚本位于 `/usr/local/bin/system-status.sh`。您可以使用任何文本编辑器进行编辑：

```bash
sudo nano /usr/local/bin/system-status.sh
```

## 显示选项

### 修改颜色

在脚本开头的颜色定义部分，您可以更改显示颜色：

```bash
# 颜色
CYAN='\e[36m'
GREEN='\e[32m'
RESET='\e[0m'
WHITE='\e[97m'
```

您可以添加更多颜色或修改现有颜色：

```bash
# 添加颜色
YELLOW='\e[33m'
RED='\e[31m'
BLUE='\e[34m'
```

### 自定义标题

修改以下代码来自定义标题：

```bash
echo -e "${WHITE}[System Info]${RESET}"
```

例如，添加您的服务器名称：

```bash
echo -e "${WHITE}[System Info - Production Server]${RESET}"
```

### 自定义显示项目

您可以通过注释或删除相应部分来移除不需要的信息。例如，如果不需要显示 SWAP 信息，可以注释掉：

```bash
# # Swap
# SWAP_TOTAL=$(free -m | awk '/Swap:/ {print $2}')
# SWAP_USED=$(free -m | awk '/Swap:/ {print $3}')
# if [ "$SWAP_TOTAL" -gt "0" ]; then
#     # Calculate percentage using awk instead of bc
#     SWAP_PERCENT=$(awk "BEGIN {printf \"%.1f\", $SWAP_USED*100/$SWAP_TOTAL}")
# else
#     SWAP_PERCENT="0.0"
# fi
# printf "%-18s : %dMB / %dMB (${GREEN}%s%%${RESET} Used) " "SWAP" "$SWAP_USED" "$SWAP_TOTAL" "$SWAP_PERCENT"
# create_progress_bar ${SWAP_PERCENT%.*}
# echo ""
```

### 添加新信息

您可以添加更多系统信息。例如，添加 CPU 温度（在支持的硬件上）：

```bash
# CPU 温度 (仅支持树莓派和部分硬件)
if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
    CPU_TEMP=$(cat /sys/class/thermal/thermal_zone0/temp)
    CPU_TEMP=$(awk "BEGIN {printf \"%.1f\", $CPU_TEMP/1000}")
    printf "%-18s : ${GREEN}%s°C${RESET}\n" "CPU Temperature" "$CPU_TEMP"
fi
```

## 进度条自定义

### 修改进度条长度

在 `create_progress_bar` 函数中，更改 `bar_size` 变量的值：

```bash
create_progress_bar() {
    local usage=$1
    local bar_size=20  # 改为更长的进度条
    ...
}
```

### 修改进度条样式

您可以更改进度条的样式，例如使用不同的字符：

```bash
printf "["
printf "%${filled}s" | tr ' ' '#'  # 使用 # 而不是 =
printf "%${empty}s" | tr ' ' '.'   # 使用 . 表示空白部分
printf "]"
```

## 启动选项

### 选择性显示（特定用户）

如果只想为特定用户显示，请编辑 `/etc/profile.d/system-status.sh` 文件：

```bash
#!/bin/bash
# 只在 SSH 会话中为特定用户运行
if [ -n "$SSH_CONNECTION" ] && [ "$USER" = "admin" ]; then
  /usr/local/bin/system-status.sh
fi
```

### 添加欢迎信息

在系统状态显示后添加自定义欢迎信息：

```bash
# 在 /etc/profile.d/system-status.sh 文件末尾添加
echo ""
echo "欢迎使用生产服务器。请谨慎操作！"
echo "如需帮助，请联系 admin@example.com"
```

## 高级自定义

### 添加网络流量监控

在脚本中添加网络流量监控部分：

```bash
echo -e "${WHITE}[Network Traffic]${RESET}"
echo ""

# 获取主要网络接口
MAIN_INTERFACE=$(ip route | grep default | awk '{print $5}' | head -n 1)

if [ -n "$MAIN_INTERFACE" ]; then
    # 获取当前网络统计
    RX_BYTES=$(cat /sys/class/net/$MAIN_INTERFACE/statistics/rx_bytes)
    TX_BYTES=$(cat /sys/class/net/$MAIN_INTERFACE/statistics/tx_bytes)
    
    # 转换为人类可读格式
    RX_MB=$(awk "BEGIN {printf \"%.2f\", $RX_BYTES/1024/1024}")
    TX_MB=$(awk "BEGIN {printf \"%.2f\", $TX_BYTES/1024/1024}")
    
    printf "%-18s : %s\n" "Interface" "$MAIN_INTERFACE"
    printf "%-18s : ${GREEN}%s MB${RESET} (received)\n" "Total Traffic" "$RX_MB"
    printf "%-18s : ${GREEN}%s MB${RESET} (sent)\n" "Total Traffic" "$TX_MB"
fi
```

### 添加服务状态检查

检查重要服务的运行状态：

```bash
echo -e "${WHITE}[Services Status]${RESET}"
echo ""

# 要检查的服务列表
SERVICES=("ssh" "nginx" "docker" "mysql")

for SERVICE in "${SERVICES[@]}"; do
    if systemctl is-active --quiet $SERVICE; then
        printf "%-18s : ${GREEN}Running${RESET}\n" "$SERVICE"
    else
        printf "%-18s : ${RED}Stopped${RESET}\n" "$SERVICE"
    fi
done
```

## 故障排除

如果脚本不工作或显示错误，请检查：

1. 脚本是否有执行权限：
   ```bash
   sudo chmod +x /usr/local/bin/system-status.sh
   ```

2. 确保依赖命令存在：
   ```bash
   which free && which df && which ps && which awk
   ```

3. 检查语法错误：
   ```bash
   bash -n /usr/local/bin/system-status.sh
   ```

如有其他问题，请提交 GitHub Issues 获取支持。