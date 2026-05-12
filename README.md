# 🛡️ Linux 通用防火墙一键管理脚本 (Universal Firewall Manager)

![Bash](https://img.shields.io/badge/Language-Bash-4EAA25?style=flat-square&logo=gnu-bash&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-blue?style=flat-square)
![Platform](https://img.shields.io/badge/Platform-Linux-lightgrey?style=flat-square&logo=linux)

这是一个专为运维设计的轻量级脚本。它可以智能识别系统派系，一键开启推荐防火墙或彻底关闭并清空所有底层规则，防止多种防火墙工具共存导致的冲突。

---

## ✨ 核心特性

*   🔍 **智能派系识别**：自动区分 `RedHat/CentOS` 与 `Debian/Ubuntu` 体系，提供定制化建议。
*   💡 **冲突预防机制**：智能推荐开启当前系统原生防火墙，并自动关闭冲突的竞争组件。
*   🛡️ **安全清空策略**：在清空底层 `iptables` 前自动放行默认策略，确保 **SSH 永不掉线**。
*   🖱️ **交互式菜单**：全中文循环菜单，执行完操作自动刷新状态预览，无需重复启动脚本。

---

## 🚀 一键运行 (Quick Start)

请根据您的环境选择一种方式，直接在终端执行：

### 方式 A：推荐方式 (使用 curl)
```bash
bash <(curl -s -L https://raw.githubusercontent.com/ZhangSir9901/linux-firewall-manager/refs/heads/main/firewall_manager.sh)
```

### 方式 B：备用方式 (使用 wget)
```bash
wget -O firewall_manager.sh https://raw.githubusercontent.com/ZhangSir9901/linux-firewall-manager/refs/heads/main/firewall_manager.sh && bash firewall_manager.sh
```

---

## 💻 界面预览 (UI Preview)

运行后您将看到如下专业终端界面：

```text
****************************************************
  脚本名称 : Linux Universal Firewall Manager
  脚本版本 : v1.2.0 (2024-05-24)
  核心功能 : 一键检测、智能开启(推荐)或彻底关闭系统防火墙
  安全警告 : 警告：关闭防火墙会暴露系统风险，请确保处于受信任的网络环境！
****************************************************
【系统环境】
 发行版本 : Ubuntu 22.04.2 LTS 
 系统内核 : 5.15.0-76-generic
----------------------------------------------------
【防火墙当前状态】
 1. Firewalld : 已停止 (Inactive) 【建议关闭/勿用】
 2. UFW       : 运行中 (Active) 【系统推荐开启】
 3. Iptables  : 已生效 (存在 12 条自定义规则)
 4. Nftables  : 未生效 (规则集为空)
====================================================
 请选择操作:
  [1] 智能开启系统推荐的防火墙 (只启动推荐组件)
  [2] 一键关闭所有防火墙服务及底层规则 (彻底放行)
  [0] 退出脚本 (Exit)
====================================================
请输入对应数字 (0/1/2): 
```

---

## ⚠️ 重要说明与免责声明

> [!IMPORTANT]
> **权限要求**：本脚本涉及系统核心网络配置，必须以 `root` 用户或通过 `sudo` 运行。

> [!WARNING]
> **安全风险**：
> 1. 彻底关闭防火墙会极大降低系统的网络安全性。
> 2. 建议仅在安全的内网环境、受信任的安全组保护下，或明确知晓风险的测试环境中使用。
> 3. 生产环境公网服务器请务必谨慎操作。

### 🛡️ 免责声明
本脚本按“原样”提供，不提供任何明示或暗示的保证。因使用本脚本造成的任何网络安全事件、数据损失或生产事故，作者不承担任何连带责任。

---

## 📄 开源协议
本项目遵循 [MIT License](LICENSE) 协议。

---
**⭐ 如果这个项目帮到了你，请给一个 Star 表示支持！**
