# SSH 系统状态显示工具

![系统状态显示截图](docs/images/screenshot.png)

一个轻量级、美观的 Linux 系统状态显示工具，在 SSH 登录时自动展示系统信息，包括 CPU、内存、磁盘使用情况等关键指标。

## ✨ 特性

- 🚀 SSH 登录时自动显示
- 💻 展示完整系统信息（CPU、内存、磁盘等）
- 📊 直观的进度条展示资源使用率
- 🔄 无需第三方依赖，使用系统内置命令
- 🎨 美观的彩色输出
- 📦 简单的一键部署

## 🚀 快速安装

### 方法 1：一键部署（推荐）

只需在终端中运行以下命令：

```bash
curl -sSL https://github.com/Gauthos/System_Status/main/scripts/install.sh | sudo bash
```

### 方法 2：手动安装

1. 克隆仓库：

```bash
git clone https://github.com/yourusername/system-status.git
cd system-status
```

1. 安装脚本：

```bash
sudo bash scripts/install.sh
```

## 🔧 使用方法

安装完成后，每次通过 SSH 登录系统时，将自动显示系统状态信息。

如需手动查看系统状态，可以运行：

```bash
bash /usr/local/bin/system-status.sh
```

## 🎨 自定义

如需自定义显示内容或样式，可以编辑以下文件：

```bash
sudo nano /usr/local/bin/system-status.sh
```

详细的自定义选项请参考 [自定义指南](docs/customization.md)。

### 卸载

如需卸载系统状态显示工具，请运行以下命令：

```
curl -sSL https://github.com/Gauthos/System_Status/main/scripts/uninstall.sh | sudo bash
```

## 💻 系统兼容性

- ✅ 基本适配目前市面上Linux发行版(X86和Arm)

## 📝 许可证

本项目采用 MIT 许可证 - 详情请查看 [LICENSE](LICENSE) 文件。

## 🤝 贡献

欢迎提交问题和拉取请求！如果您有任何改进建议，请随时与我们分享。

## 📊 截图

![完整截图](docs/images/screenshot.png)