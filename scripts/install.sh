#!/bin/bash

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # 无颜色

# 显示标题
echo -e "${BLUE}=======================================${NC}"
echo -e "${BLUE}    系统状态显示脚本快速部署工具    ${NC}"
echo -e "${BLUE}=======================================${NC}"
echo -e "${BLUE}    版本: 1.1.0 - $(date +%Y-%m-%d)    ${NC}"
echo ""

# 检查系统类型
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
else
    OS=$(uname -s)
    VER=$(uname -r)
fi

echo -e "检测到系统: ${YELLOW}$OS $VER${NC}"
echo ""

# 检查是否为root用户运行
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}错误: 请以root用户运行此脚本${NC}" >&2
    echo -e "使用命令: ${YELLOW}sudo bash install.sh${NC}" >&2
    exit 1
fi

# 确认安装
echo -e "此脚本将安装SSH登录系统状态显示工具"
echo -e "适用于Debian/Ubuntu/CentOS/RHEL等Linux系统"
echo ""
read -p "是否继续安装? (y/n): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}安装已取消${NC}"
    exit 0
fi

# 检测包管理器
echo -e "\n${BLUE}>>> 检测系统包管理器...${NC}"
if command -v apt-get &> /dev/null; then
    PKG_MANAGER="apt-get"
    PKG_CHECK="dpkg -l"
    PKG_CHECK_GREP="grep -q \"ii  \$package \""
    INSTALL_CMD="apt-get update && apt-get install -y"
    NEEDED_PACKAGES="curl lsb-release procps hostname net-tools"
elif command -v yum &> /dev/null; then
    PKG_MANAGER="yum"
    PKG_CHECK="rpm -qa"
    PKG_CHECK_GREP="grep -q \"\$package\""
    INSTALL_CMD="yum install -y"
    NEEDED_PACKAGES="curl redhat-lsb-core procps hostname net-tools"
elif command -v dnf &> /dev/null; then
    PKG_MANAGER="dnf"
    PKG_CHECK="rpm -qa"
    PKG_CHECK_GREP="grep -q \"\$package\""
    INSTALL_CMD="dnf install -y"
    NEEDED_PACKAGES="curl redhat-lsb-core procps hostname net-tools"
else
    echo -e "${YELLOW}警告: 无法识别的包管理系统, 将尝试继续安装${NC}"
    echo -e "如果安装失败, 请手动安装必要的依赖: curl, lsb-release, procps, hostname, net-tools"
    PKG_MANAGER="unknown"
fi

echo -e "使用包管理器: ${YELLOW}$PKG_MANAGER${NC}"

# 检查并安装必要的依赖
if [ "$PKG_MANAGER" != "unknown" ]; then
    echo -e "\n${BLUE}>>> 检查必要的依赖...${NC}"
    PACKAGES_TO_INSTALL=""

    for package in $NEEDED_PACKAGES; do
        if ! eval "$PKG_CHECK | $PKG_CHECK_GREP"; then
            PACKAGES_TO_INSTALL="$PACKAGES_TO_INSTALL $package"
        fi
    done

    if [ ! -z "$PACKAGES_TO_INSTALL" ]; then
        echo -e "安装必要的依赖: $PACKAGES_TO_INSTALL"
        if ! eval "$INSTALL_CMD $PACKAGES_TO_INSTALL"; then
            echo -e "${RED}错误: 无法安装必要的依赖${NC}" >&2
            echo -e "请尝试手动安装: ${YELLOW}$PACKAGES_TO_INSTALL${NC}" >&2
            read -p "是否继续安装脚本? (y/n): " -n 1 -r
            echo ""
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                echo -e "${RED}安装已取消${NC}"
                exit 1
            fi
        fi
    else
        echo -e "所有必要的依赖已安装"
    fi
fi

# 检查是否有本地system-status.sh文件
LOCAL_SCRIPT="system-status.sh"
SCRIPT_PATH="/usr/local/bin/system-status.sh"

echo -e "\n${BLUE}>>> 安装系统状态显示脚本...${NC}"
# 创建目标目录
mkdir -p /usr/local/bin

# 如果当前目录有system-status.sh文件，直接使用本地文件
if [ -f "$LOCAL_SCRIPT" ]; then
    echo -e "使用本地系统状态显示脚本..."
    cp "$LOCAL_SCRIPT" "$SCRIPT_PATH"
else
    # 否则询问是否使用GitHub加速
    echo -e "从仓库下载脚本..."
    echo -e "您是否在中国大陆环境使用? (使用GitHub加速下载)"
    read -p "是否使用GitHub加速下载? (y/n): " -n 1 -r
    echo ""
    
    GITHUB_URL="https://raw.githubusercontent.com/Gauthos/System_Status/main/scripts/system-status.sh"
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        DOWNLOAD_URL="https://ghfast.top/https://raw.githubusercontent.com/Gauthos/System_Status/main/scripts/system-status.sh"
        echo -e "使用GitHub加速服务下载..."
    else
        DOWNLOAD_URL="$GITHUB_URL"
        echo -e "使用GitHub原始链接下载..."
    fi
    
    if ! curl -s -o "$SCRIPT_PATH" "$DOWNLOAD_URL"; then
        echo -e "${RED}错误: 无法下载脚本文件${NC}" >&2
        echo -e "请尝试手动下载文件并重新运行安装脚本" >&2
        exit 1
    fi
fi

# 设置执行权限
chmod +x "$SCRIPT_PATH"

echo -e "\n${BLUE}>>> 设置SSH登录自动显示...${NC}"
# 创建profile.d脚本
PROFILE_SCRIPT="/etc/profile.d/system-status.sh"

# 写入新配置
cat > "$PROFILE_SCRIPT" << 'EOF'
#!/bin/bash
# 只在SSH会话中运行系统状态显示
if [ -n "$SSH_CONNECTION" ]; then
  /usr/local/bin/system-status.sh
fi
EOF

# 设置执行权限
chmod +x "$PROFILE_SCRIPT"

echo -e "\n${BLUE}>>> 测试系统状态显示脚本...${NC}"
# 测试运行脚本
bash "$SCRIPT_PATH"

# 如果测试成功，显示成功消息
if [ $? -eq 0 ]; then
    echo -e "\n${GREEN}安装成功!${NC}"
    echo -e "系统状态显示脚本已安装并配置为在SSH登录时自动运行"
    echo -e "你可以通过以下命令手动运行:"
    echo -e "  ${BLUE}$SCRIPT_PATH${NC}"
    echo -e "\n如需自定义脚本，请编辑: ${BLUE}$SCRIPT_PATH${NC}"
    echo -e "配置文件位置: ${BLUE}$PROFILE_SCRIPT${NC}"
    echo -e "\n享受你的系统状态显示工具!"
    
    # 完成时再执行一次
    echo -e "\n${BLUE}>>> 执行系统状态显示...${NC}"
    bash "$SCRIPT_PATH"
else
    echo -e "\n${RED}警告: 脚本测试可能存在问题${NC}"
    echo -e "请检查上面的错误信息"
fi

exit 0