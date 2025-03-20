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
echo -e "${BLUE}    版本: 1.2.0 - $(date +%Y-%m-%d)    ${NC}"
echo ""

# 检测系统类型和版本
detect_system() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        VER=$VERSION_ID
        
        # 处理特殊情况
        if [[ "$OS" == "rhel" || "$OS" == "centos" || "$OS" == "rocky" || "$OS" == "almalinux" || "$OS" == "ol" || "$OS" == "openeuler" || "$OS" == "opencloudos" ]]; then
            OS_FAMILY="rhel"
        elif [[ "$OS" == "debian" || "$OS" == "ubuntu" || "$OS" == "astra" || "$OS" == "linuxmint" || "$OS" == "pop" ]]; then
            OS_FAMILY="debian"
        elif [[ "$OS" == "fedora" ]]; then
            OS_FAMILY="fedora"
        elif [[ "$OS" == "arch" || "$OS" == "manjaro" || "$OS" == "endeavouros" ]]; then
            OS_FAMILY="arch"
        elif [[ "$OS" == "alpine" ]]; then
            OS_FAMILY="alpine"
        else
            OS_FAMILY="unknown"
        fi
    elif [ -f /etc/redhat-release ]; then
        OS_FAMILY="rhel"
        if grep -q "CentOS" /etc/redhat-release; then
            OS="centos"
        elif grep -q "Red Hat" /etc/redhat-release; then
            OS="rhel"
        fi
        VER=$(cat /etc/redhat-release | grep -oE '[0-9]+\.[0-9]+' | cut -d'.' -f1)
    elif [ -f /etc/SuSE-release ]; then
        OS_FAMILY="suse"
        OS="suse"
    elif [ -f /etc/debian_version ]; then
        OS_FAMILY="debian"
        OS="debian"
        VER=$(cat /etc/debian_version)
    elif [ -f /etc/freebsd-update.conf ]; then
        OS_FAMILY="freebsd"
        OS="freebsd"
        VER=$(uname -r | cut -d'-' -f1)
    else
        OS_FAMILY="unknown"
        OS="unknown"
    fi
    
    echo -e "检测到系统: ${YELLOW}$OS $VER${NC}"
    echo -e "系统家族: ${YELLOW}$OS_FAMILY${NC}"
}

# 检测系统架构
detect_arch() {
    ARCH=$(uname -m)
    case "$ARCH" in
    "x86_64" | "amd64")
        ARCH_TYPE="amd64"
        ;;
    "aarch64" | "arm64")
        ARCH_TYPE="arm64"
        ;;
    "armv7l" | "armv8" | "armv8l")
        ARCH_TYPE="arm"
        ;;
    "i386" | "i686")
        ARCH_TYPE="i386"
        ;;
    *)
        ARCH_TYPE="$ARCH"
        ;;
    esac
    
    echo -e "系统架构: ${YELLOW}$ARCH ($ARCH_TYPE)${NC}"
}

# 检查是否为root用户运行
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo -e "${RED}错误: 请以root用户运行此脚本${NC}" >&2
        echo -e "使用命令: ${YELLOW}sudo bash install.sh${NC}" >&2
        exit 1
    fi
}

# 确认安装
confirm_install() {
    echo -e "此脚本将安装SSH登录系统状态显示工具"
    echo -e "适用于以下系统:"
    echo -e " - Ubuntu 18+"
    echo -e " - Debian 8+"
    echo -e " - CentOS 7+"
    echo -e " - Fedora 33+"
    echo -e " - AlmaLinux 8.5+"
    echo -e " - OracleLinux 8+"
    echo -e " - RockyLinux 8+"
    echo -e " - AstraLinux CE"
    echo -e " - Arch Linux"
    echo -e " - FreeBSD(需先安装curl和bash)"
    echo -e " - Armbian"
    echo -e "支持架构: amd64(x86_64)、arm64、i386、arm"
    echo ""
    read -p "是否继续安装? (y/n): " -n 1 -r
    echo ""

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}安装已取消${NC}"
        exit 0
    fi
}

# 安装必要的依赖
install_dependencies() {
    echo -e "\n${BLUE}>>> 检查并安装必要的依赖...${NC}"
    
    case $OS_FAMILY in
        debian)
            # 尝试修复可能的APT问题
            apt_update_output=$(apt-get update 2>&1)
            if echo "$apt_update_output" | grep -q 'NO_PUBKEY'; then
                echo -e "${YELLOW}检测到APT密钥问题，尝试修复...${NC}"
                public_keys=$(echo "$apt_update_output" | grep -oE 'NO_PUBKEY [0-9A-F]+' | awk '{ print $2 }' | tr '\n' ' ')
                echo -e "${YELLOW}缺失的密钥: ${public_keys}${NC}"
                for key in $public_keys; do
                    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys $key
                done
                apt-get update
            fi
            
            echo -e "安装依赖: curl procps hostname net-tools lsb-release..."
            apt-get install -y curl procps hostname net-tools lsb-release
            if [ $? -ne 0 ]; then
                echo -e "${YELLOW}尝试修复安装问题...${NC}"
                apt-get --fix-broken install -y
                apt-get install -y curl procps hostname net-tools lsb-release
            fi
            ;;
            
        rhel)
            echo -e "安装依赖: curl procps hostname net-tools redhat-lsb-core..."
            if command -v dnf &>/dev/null; then
                dnf install -y curl procps hostname net-tools redhat-lsb-core
            else
                yum install -y curl procps hostname net-tools redhat-lsb-core
            fi
            ;;
            
        fedora)
            echo -e "安装依赖: curl procps hostname net-tools redhat-lsb-core..."
            dnf install -y curl procps hostname net-tools redhat-lsb-core
            ;;
            
        arch)
            echo -e "安装依赖: curl procps-ng inetutils net-tools..."
            pacman -Sy --needed --noconfirm curl procps-ng inetutils net-tools
            ;;
            
        alpine)
            echo -e "安装依赖: curl procps hostname net-tools..."
            apk update
            apk add curl procps hostname net-tools
            ;;
            
        freebsd)
            echo -e "安装依赖: curl bash procps net-tools..."
            pkg install -y curl bash procps net-tools
            ;;
            
        *)
            echo -e "${YELLOW}未知系统类型，尝试继续安装...${NC}"
            echo -e "${YELLOW}如果安装失败，请手动安装必要的依赖: curl, procps, hostname, net-tools${NC}"
            ;;
    esac
}

# 选择下载源
choose_download_source() {
    echo -e "\n${BLUE}>>> 选择下载源${NC}"
    echo -e "您是否在中国大陆环境使用? (使用镜像加速下载)"
    read -p "是否使用镜像加速下载? (y/n): " -n 1 -r
    echo ""
    
    GITHUB_URL="https://raw.githubusercontent.com/Gauthos/System_Status/main/scripts/system-status.sh"
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        DOWNLOAD_URL="https://ghfast.top/$GITHUB_URL"
        echo -e "使用镜像加速服务下载..."
    else
        DOWNLOAD_URL="$GITHUB_URL"
        echo -e "使用GitHub原始链接下载..."
    fi
}

# 下载或使用本地脚本
install_script() {
    echo -e "\n${BLUE}>>> 安装系统状态显示脚本...${NC}"
    
    # 创建目标目录
    mkdir -p /usr/local/bin
    
    # 检查是否有本地system-status.sh文件
    LOCAL_SCRIPT="system-status.sh"
    SCRIPT_PATH="/usr/local/bin/system-status.sh"
    
    # 如果当前目录有system-status.sh文件，直接使用本地文件
    if [ -f "$LOCAL_SCRIPT" ]; then
        echo -e "使用本地系统状态显示脚本..."
        cp "$LOCAL_SCRIPT" "$SCRIPT_PATH"
    else
        # 否则从网络下载
        echo -e "从仓库下载脚本..."
        
        # 尝试使用curl下载
        if ! curl -s -o "$SCRIPT_PATH" "$DOWNLOAD_URL"; then
            echo -e "${YELLOW}使用curl下载失败，尝试使用wget...${NC}"
            
            # 尝试使用wget下载
            if ! wget -q -O "$SCRIPT_PATH" "$DOWNLOAD_URL"; then
                echo -e "${RED}错误: 无法下载脚本文件${NC}" >&2
                echo -e "请检查网络连接或手动下载脚本文件" >&2
                exit 1
            fi
        fi
    fi
    
    # 设置执行权限
    chmod +x "$SCRIPT_PATH"
}

# 配置SSH登录自动显示
configure_ssh_login() {
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
    
    # 对于FreeBSD，需要额外配置
    if [ "$OS_FAMILY" = "freebsd" ]; then
        echo -e "${YELLOW}检测到FreeBSD系统，配置额外启动选项...${NC}"
        
        # 检查/etc/profile是否包含profile.d目录的处理
        if ! grep -q "profile.d" /etc/profile; then
            echo -e "${YELLOW}添加profile.d支持到/etc/profile...${NC}"
            cat >> /etc/profile << 'EOF'

# Process /etc/profile.d scripts if exists
if [ -d /etc/profile.d ]; then
  for i in /etc/profile.d/*.sh; do
    if [ -r $i ]; then
      . $i
    fi
  done
  unset i
fi
EOF
        fi
    fi
}

# 测试脚本
test_script() {
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
        
        # 再运行一次脚本以展示最终效果
        echo -e "\n${BLUE}>>> 再次执行系统状态显示...${NC}"
        bash "$SCRIPT_PATH"
    else
        echo -e "\n${RED}警告: 脚本测试可能存在问题${NC}"
        echo -e "请检查上面的错误信息"
    fi
}

# 主函数
main() {
    # 检测系统和架构
    detect_system
    detect_arch
    
    # 检查权限
    check_root
    
    # 确认安装
    confirm_install
    
    # 安装依赖
    install_dependencies
    
    # 选择下载源
    choose_download_source
    
    # 安装脚本
    install_script
    
    # 配置SSH登录自动显示
    configure_ssh_login
    
    # 测试脚本
    test_script
}

# 执行主函数
main
exit 0