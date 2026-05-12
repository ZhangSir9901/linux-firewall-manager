# 🛡️ Linux 通用防火墙一键管理脚本 (Linux Firewall Manager)

![Bash](https://img.shields.io/badge/Language-Bash-4EAA25?style=flat-square&logo=gnu-bash&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-blue?style=flat-square)
![Platform](https://img.shields.io/badge/Platform-Linux-lightgrey?style=flat-square&logo=linux)

这是一个轻量、安全、通用的 Bash 脚本。用于一键检测、智能开启（推荐）或彻底关闭 Linux 系统下的各类防火墙服务。非常适合在内网测试、配置复杂网络环境或进行网络排错时使用。

---

## ✨ 核心特性

- 🔍 **多系统兼容**：自动识别 CentOS / RHEL / Fedora / Ubuntu / Debian / Kali 等主流发行版。
- 💡 **智能推荐机制**：根据系统派系（RedHat/Debian）自动推荐最适合的防火墙工具，防止组件冲突。
- 🛠️ **全组件支持**：一经运行，同时接管并处理 `firewalld`、`ufw`、底层 `iptables` 和 `nftables`。
- 🛡️ **安全防断连**：在清空底层规则（iptables）前，**自动将默认策略置为放行 (ACCEPT)**，完美防止 SSH 瞬间断连。
- 🖱️ **极简交互**：直观的终端循环菜单，检测状态一目了然，数字键一键操作。

---

## 🚀 一键运行指令 (Quick Start)

无需手动下载解压，你可以直接在任意 Linux 终端复制并运行以下命令（请确保你拥有 `root` 权限）：

### 推荐方式 (使用 curl)
```bash
bash <(curl -s -L https://raw.githubusercontent.com/ZhangSir9901/linux-firewall-manager/refs/heads/main/firewall_manager.sh)
```
### 备用方式  (使用 wget)
```bash
wget -O firewall_manager.sh https://raw.githubusercontent.com/ZhangSir9901/linux-firewall-manager/refs/heads/main/firewall_manager.sh && bash firewall_manager.sh
```

💻 界面展示 (Preview)
运行脚本后，你将看到如下直观的控制台界面：

```bash
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

⚠️ 注意事项与免责声明
[!IMPORTANT]
权限要求：必须以 root 用户或使用 sudo 权限运行此脚本。
安全风险：彻底关闭防火墙会极大降低系统的网络安全性！建议仅在安全的内网环境、受信任的云安全组保护下，或明确知晓风险的测试环境中使用“一键关闭”功能。生产环境公网服务器请慎用。
冲突预防：脚本会自动处理 Firewalld 与 UFW 的冲突，不建议在同一台机器上强行手动开启多个防火墙前端。
免责声明：本脚本按“原样”提供，因使用本脚本造成的任何网络安全事件或数据损失，作者不承担任何连带责任。

📄 开源协议
This project is licensed under the MIT License.

⭐ 如果这个脚本帮到了你，请给一个 Star 以示支持！
