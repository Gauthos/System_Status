#!/bin/bash

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # 无颜色

# 显示标题
echo -e "${BLUE}=======================================${NC}"
echo -e "${BLUE}    系统状态显示脚本卸载工具    ${NC}"
echo -e "${BLUE}=======================================${NC}"
echo ""

# 检查是否为root用户运行
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}错误: 请以root用户运行此脚本${NC}" >&2
    exit 1
fi

# 确认卸载
echo -e "此脚本将卸载SSH登录系统状态显示工具"
echo -e "将删除以下文件:"
echo -e "  - /usr/local/bin/system-status.sh"
echo -e "  - /etc/profile.d/system-status.sh"
echo ""
read -p "是否继续卸载? (y/n): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}卸载已取消${NC}"
    exit 0
fi

echo -e "\n${BLUE}>>> 开始卸载...${NC}"

# 删除系统状态显示脚本
if [ -f /usr/local/bin/system-status.sh ]; then
    echo -e "删除系统状态显示脚本..."
    rm -f /usr/local/bin/system-status.sh
    if [ $? -ne 0 ]; then
        echo -e "${RED}错误: 无法删除系统状态显示脚本${NC}" >&2
    else
        echo -e "${GREEN}系统状态显示脚本已成功删除${NC}"
    fi
else
    echo -e "${BLUE}系统状态显示脚本不存在，无需删除${NC}"
fi

# 删除profile.d脚本
if [ -f /etc/profile.d/system-status.sh ]; then
    echo -e "删除启动配置..."
    rm -f /etc/profile.d/system-status.sh
    if [ $? -ne 0 ]; then
        echo -e "${RED}错误: 无法删除启动配置${NC}" >&2
    else
        echo -e "${GREEN}启动配置已成功删除${NC}"
    fi
else
    echo -e "${BLUE}启动配置不存在，无需删除${NC}"
fi

echo -e "\n${GREEN}卸载完成!${NC}"
echo -e "系统状态显示工具已从系统中移除"
echo -e "重新登录后将不再显示系统状态信息"

exit 0