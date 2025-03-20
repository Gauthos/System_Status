#!/bin/bash

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # 无颜色

# 显示标题
echo -e "${BLUE}=======================================${NC}"
echo -e "${BLUE}    系统状态显示脚本快速部署工具    ${NC}"
echo -e "${BLUE}=======================================${NC}"
echo ""

# 检查是否为root用户运行
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}错误: 请以root用户运行此脚本${NC}" >&2
    exit 1
fi

# 确认安装
echo -e "此脚本将安装SSH登录系统状态显示工具"
echo -e "适用于Debian/Ubuntu系统"
echo ""
read -p "是否继续安装? (y/n): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}安装已取消${NC}"
    exit 0
fi

REPO_URL="https://raw.githubusercontent.com/Gauthos/System_Status/main"

echo -e "\n${BLUE}>>> 检查必要的依赖...${NC}"
# 检查并安装curl (如果需要)
if ! command -v curl &> /dev/null; then
    echo -e "安装curl..."
    apt-get update && apt-get install -y curl
    if [ $? -ne 0 ]; then
        echo -e "${RED}错误: 无法安装curl${NC}" >&2
        exit 1
    fi
fi

echo -e "\n${BLUE}>>> 下载系统状态显示脚本...${NC}"
# 创建目标目录
mkdir -p /usr/local/bin

# 下载系统状态显示脚本
echo -e "从仓库下载脚本..."
curl -s -o /usr/local/bin/system-status.sh ${REPO_URL}/system-status.sh

if [ $? -ne 0 ]; then
    echo -e "${RED}错误: 无法下载脚本文件${NC}" >&2
    exit 1
fi

# 设置执行权限
chmod +x /usr/local/bin/system-status.sh

echo -e "\n${BLUE}>>> 设置SSH登录自动显示...${NC}"
# 创建profile.d脚本
cat > /etc/profile.d/system-status.sh << 'EOF'
#!/bin/bash
# 只在SSH会话中运行系统状态显示
if [ -n "$SSH_CONNECTION" ]; then
  /usr/local/bin/system-status.sh
fi
EOF

# 设置执行权限
chmod +x /etc/profile.d/system-status.sh

echo -e "\n${BLUE}>>> 测试系统状态显示脚本...${NC}"
# 测试运行脚本
/usr/local/bin/system-status.sh

# 如果测试成功，显示成功消息
if [ $? -eq 0 ]; then
    echo -e "\n${GREEN}安装成功!${NC}"
    echo -e "系统状态显示脚本已安装并配置为在SSH登录时自动运行"
    echo -e "你可以通过以下命令手动运行:"
    echo -e "  ${BLUE}/usr/local/bin/system-status.sh${NC}"
    echo -e "\n享受你的系统状态显示工具!"
else
    echo -e "\n${RED}警告: 脚本测试可能存在问题${NC}"
    echo -e "请检查上面的错误信息"
fi

exit 0