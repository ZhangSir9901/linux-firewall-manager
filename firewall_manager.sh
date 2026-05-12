#!/bin/bash

# ====================================================
# 通用 Linux 防火墙管理脚本 (检测/开启/关闭)
# 适用范围: CentOS/RHEL/Fedora, Ubuntu/Debian/Kali 等
# 支持组件: firewalld, ufw, iptables, nftables
# ====================================================

# 颜色定义
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
CYAN='\033[36m'
NC='\033[0m' # No Color

# 确保以 root 权限运行
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}[错误] 请使用 root 权限运行此脚本 (Please run as root)${NC}"
  exit 1
fi

# ==========================================
# 1. 检测系统与内核版本
# ==========================================
if [ -f /etc/os-release ]; then
    OS_NAME=$(grep -E '^PRETTY_NAME=' /etc/os-release | cut -d '"' -f 2)
    if [ -z "$OS_NAME" ]; then
        OS_NAME=$(grep -E '^NAME=' /etc/os-release | cut -d '"' -f 2)
    fi
elif type lsb_release >/dev/null 2>&1; then
    OS_NAME=$(lsb_release -sd)
elif [ -f /etc/redhat-release ]; then
    OS_NAME=$(cat /etc/redhat-release)
else
    OS_NAME=$(uname -s)
fi
KERNEL_VER=$(uname -r)

# ==========================================
# 2. 检测防火墙状态
# ==========================================
FWD_STATUS="${YELLOW}未安装${NC}"
UFW_STATUS="${YELLOW}未安装${NC}"
IPT_STATUS="${YELLOW}未安装${NC}"
NFT_STATUS="${YELLOW}未安装${NC}"

# 检测 Firewalld
if command -v firewall-cmd >/dev/null 2>&1 || systemctl list-unit-files | grep -q firewalld.service 2>/dev/null; then
    if systemctl is-active --quiet firewalld 2>/dev/null || firewall-cmd --state 2>/dev/null | grep -q running; then
        FWD_STATUS="${GREEN}运行中 (Active)${NC}"
    else
        FWD_STATUS="${RED}已停止 (Inactive)${NC}"
    fi
fi

# 检测 UFW
if command -v ufw >/dev/null 2>&1; then
    if ufw status 2>/dev/null | grep -q -i "active\|激活"; then
        UFW_STATUS="${GREEN}运行中 (Active)${NC}"
    else
        UFW_STATUS="${RED}已停止 (Inactive)${NC}"
    fi
fi

# 检测 iptables 底层规则
if command -v iptables >/dev/null 2>&1; then
    # 统计除了默认策略之外的实际规则条数
    IPT_RULES_COUNT=$(iptables -S 2>/dev/null | grep "^-A" | wc -l)
    if [ "$IPT_RULES_COUNT" -gt 0 ]; then
        IPT_STATUS="${GREEN}已生效 (存在 $IPT_RULES_COUNT 条拦截/转发规则)${NC}"
    else
        IPT_STATUS="${RED}未生效 (规则为空，默认放行)${NC}"
    fi
fi

# 检测 nftables 底层规则
if command -v nft >/dev/null 2>&1; then
    NFT_RULES_COUNT=$(nft list ruleset 2>/dev/null | grep -c "table")
    if [ "$NFT_RULES_COUNT" -gt 0 ]; then
        NFT_STATUS="${GREEN}已生效 (存在规则集)${NC}"
    else
        NFT_STATUS="${RED}未生效 (规则集为空)${NC}"
    fi
fi

# ==========================================
# 打印信息控制台
# ==========================================
clear
echo -e "${CYAN}====================================================${NC}"
echo -e "              ${CYAN}Linux 防火墙一键管理工具${NC}              "
echo -e "${CYAN}====================================================${NC}"
echo -e "【系统信息】"
echo -e " 操作发行版 : ${CYAN}$OS_NAME${NC}"
echo -e " 内核版本   : ${CYAN}$KERNEL_VER${NC}"
echo -e "----------------------------------------------------"
echo -e "【防火墙状态】"
echo -e " 1. Firewalld : $FWD_STATUS"
echo -e " 2. UFW       : $UFW_STATUS"
echo -e " 3. Iptables  : $IPT_STATUS"
echo -e " 4. Nftables  : $NFT_STATUS"
echo -e "${CYAN}====================================================${NC}"
echo -e " 请选择操作:"
echo -e "  ${GREEN}[1] 一键开启所有防火墙服务 (Enable)${NC}"
echo -e "  ${RED}[2] 一键关闭所有防火墙服务及清空规则 (Disable)${NC}"
echo -e "  [0] 退出脚本 (Exit)"
echo -e "${CYAN}====================================================${NC}"

read -p "请输入对应数字 (0/1/2): " choice

# ==========================================
# 3. 核心逻辑：开启或关闭
# ==========================================

case $choice in
    1)
        echo -e "\n${CYAN}[*] 正在一键开启防火墙...${NC}"
        
        # 开启 UFW
        if command -v ufw >/dev/null 2>&1; then
            echo "[-] 检测到 UFW，正在启动..."
            ufw --force enable >/dev/null 2>&1
            systemctl enable --now ufw >/dev/null 2>&1
            echo -e "  ${GREEN}✓ UFW 已开启。${NC}"
        fi
        
        # 开启 Firewalld
        if command -v firewall-cmd >/dev/null 2>&1 || systemctl list-unit-files | grep -q firewalld.service 2>/dev/null; then
            echo "[-] 检测到 Firewalld，正在启动..."
            systemctl unmask firewalld >/dev/null 2>&1
            systemctl enable --now firewalld >/dev/null 2>&1
            echo -e "  ${GREEN}✓ Firewalld 已开启。${NC}"
        fi

        # 持久化 iptables 服务检测 (如果有)
        if systemctl list-unit-files | grep -q netfilter-persistent 2>/dev/null; then
            systemctl enable --now netfilter-persistent >/dev/null 2>&1
        fi
        if systemctl list-unit-files | grep -q iptables.service 2>/dev/null; then
            systemctl enable --now iptables >/dev/null 2>&1
        fi

        echo -e "\n${GREEN}[√] 开启操作执行完毕！请重新运行脚本查看当前状态。${NC}\n"
        ;;
        
    2)
        echo -e "\n${CYAN}[*] 正在彻底关闭并清空所有防火墙配置...${NC}"

        # 关闭 Firewalld
        if systemctl is-active --quiet firewalld 2>/dev/null || systemctl list-unit-files | grep -q firewalld.service 2>/dev/null; then
            systemctl stop firewalld >/dev/null 2>&1
            systemctl disable firewalld >/dev/null 2>&1
            echo -e "  ${GREEN}✓ Firewalld 服务已停止并禁用自启。${NC}"
        fi

        # 关闭 UFW
        if command -v ufw >/dev/null 2>&1; then
            ufw --force disable >/dev/null 2>&1
            systemctl stop ufw >/dev/null 2>&1
            systemctl disable ufw >/dev/null 2>&1
            echo -e "  ${GREEN}✓ UFW 服务已停止并禁用自启。${NC}"
        fi

        # 关闭 Ubuntu/Debian 的 netfilter-persistent 服务
        if systemctl list-unit-files | grep -q netfilter-persistent 2>/dev/null; then
            systemctl stop netfilter-persistent >/dev/null 2>&1
            systemctl disable netfilter-persistent >/dev/null 2>&1
        fi

        # 清空 iptables
        if command -v iptables >/dev/null 2>&1; then
            # 先将默认策略置为 ACCEPT，防止清空规则后直接断网 (非常重要)
            iptables -P INPUT ACCEPT
            iptables -P FORWARD ACCEPT
            iptables -P OUTPUT ACCEPT
            
            # 清空所有的链和表
            iptables -F
            iptables -X
            iptables -t nat -F
            iptables -t nat -X
            iptables -t mangle -F
            iptables -t mangle -X
            iptables -t raw -F
            iptables -t raw -X
            echo -e "  ${GREEN}✓ Iptables 所有规则已清空，默认策略已改为全部放行 (ACCEPT)。${NC}"
        fi

        # 清空 nftables
        if command -v nft >/dev/null 2>&1; then
            nft flush ruleset >/dev/null 2>&1
            echo -e "  ${GREEN}✓ Nftables 规则集已清空。${NC}"
        fi

        echo -e "\n${GREEN}[√] 关闭操作执行完毕！系统当前处于无防火墙保护状态！${NC}\n"
        ;;
        
    0)
        echo -e "${YELLOW}已退出操作。${NC}"
        exit 0
        ;;
        
    *)
        echo -e "${RED}[错误] 无效的输入，脚本退出。${NC}"
        exit 1
        ;;
esac
