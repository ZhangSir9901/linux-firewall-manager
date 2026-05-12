#!/bin/bash

# ====================================================
# 高级 Linux 防火墙管理脚本 (基于运维最佳实践)
# 特性: 智能推荐、防前端冲突、循环菜单、冗余检测
# ====================================================

# --- 脚本元数据 (固定显示信息) ---
SCRIPT_NAME="Linux Universal Firewall Manager"
SCRIPT_FUNC="一键检测、智能开启(推荐)或彻底关闭系统防火墙"
SCRIPT_WARN="警告：关闭防火墙会暴露系统风险，请确保处于受信任的网络环境！"
SCRIPT_VER="v1.2.0"
SCRIPT_DATE="2024-05-24"

# 颜色定义
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
CYAN='\033[36m'
PURPLE='\033[35m'
NC='\033[0m' # No Color

# 确保以 root 权限运行
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}[错误] 请使用 root 权限运行此脚本 (Please run as root)${NC}"
  exit 1
fi

# ==========================================
# 1. 探针：检测系统类型与派系划分
# ==========================================
OS_FAMILY="unknown"
OS_NAME="Unknown Linux"

if [ -f /etc/os-release ]; then
    source /etc/os-release
    OS_NAME=$PRETTY_NAME
    if [[ "$ID" =~ (ubuntu|debian|kali|linuxmint) ]] || [[ "$ID_LIKE" =~ (ubuntu|debian) ]]; then
        OS_FAMILY="debian"
    elif [[ "$ID" =~ (centos|rhel|fedora|rocky|almalinux|opencloudos|tencentos|aliyun) ]] || [[ "$ID_LIKE" =~ (centos|rhel|fedora) ]]; then
        OS_FAMILY="rhel"
    fi
elif [ -f /etc/redhat-release ]; then
    OS_NAME=$(cat /etc/redhat-release)
    OS_FAMILY="rhel"
else
    OS_NAME=$(uname -s)
fi
KERNEL_VER=$(uname -r)

# ==========================================
# 主循环菜单开始
# ==========================================
while true; do
    clear
    
    # --- A. 打印固定头部信息 ---
    echo -e "${CYAN}****************************************************${NC}"
    echo -e "  脚本名称 : ${PURPLE}$SCRIPT_NAME${NC}"
    echo -e "  脚本版本 : $SCRIPT_VER (${SCRIPT_DATE})"
    echo -e "  核心功能 : $SCRIPT_FUNC"
    echo -e "  ${RED}安全警告 : $SCRIPT_WARN${NC}"
    echo -e "${CYAN}****************************************************${NC}"

    # 状态变量初始化
    FWD_IS_ACTIVE=false
    UFW_IS_ACTIVE=false
    IPT_RULES_COUNT=0
    NFT_RULES_COUNT=0
    ANY_ACTIVE=false

    FWD_STATUS="${YELLOW}未安装${NC}"
    UFW_STATUS="${YELLOW}未安装${NC}"
    IPT_STATUS="${YELLOW}未安装${NC}"
    NFT_STATUS="${YELLOW}未安装${NC}"

    # ==========================================
    # 2. 探针：检测防火墙状态
    # ==========================================
    # 2.1 Firewalld
    if command -v firewall-cmd >/dev/null 2>&1 || systemctl list-unit-files | grep -q firewalld.service 2>/dev/null; then
        if systemctl is-active --quiet firewalld 2>/dev/null || firewall-cmd --state 2>/dev/null | grep -q running; then
            FWD_IS_ACTIVE=true
            ANY_ACTIVE=true
            FWD_STATUS="${GREEN}运行中 (Active)${NC}"
        else
            FWD_STATUS="${RED}已停止 (Inactive)${NC}"
        fi
    fi

    # 2.2 UFW
    if command -v ufw >/dev/null 2>&1; then
        if ufw status 2>/dev/null | grep -q -i "active\|激活"; then
            UFW_IS_ACTIVE=true
            ANY_ACTIVE=true
            UFW_STATUS="${GREEN}运行中 (Active)${NC}"
        else
            UFW_STATUS="${RED}已停止 (Inactive)${NC}"
        fi
    fi

    # 2.3 iptables
    if command -v iptables-save >/dev/null 2>&1; then
        IPT_RULES_COUNT=$(iptables-save 2>/dev/null | grep -c '^-A')
        if [ "$IPT_RULES_COUNT" -gt 0 ]; then
            ANY_ACTIVE=true
            IPT_STATUS="${GREEN}已生效 (存在 $IPT_RULES_COUNT 条自定义规则)${NC}"
        else
            IPT_STATUS="${RED}未生效 (规则为空)${NC}"
        fi
    fi

    # 2.4 nftables
    if command -v nft >/dev/null 2>&1; then
        NFT_RULES_COUNT=$(nft list ruleset 2>/dev/null | grep -c "table")
        if [ "$NFT_RULES_COUNT" -gt 0 ]; then
            ANY_ACTIVE=true
            NFT_STATUS="${GREEN}已生效 (存在规则集)${NC}"
        else
            NFT_STATUS="${RED}未生效 (规则集为空)${NC}"
        fi
    fi

    # ==========================================
    # 3. 智能推荐标签逻辑
    # ==========================================
    FWD_TAG=""
    UFW_TAG=""
    if [ "$OS_FAMILY" = "rhel" ]; then
        FWD_TAG=" ${GREEN}【系统推荐开启】${NC}"
        UFW_TAG=" ${RED}【建议关闭/勿用】${NC}"
    elif [ "$OS_FAMILY" = "debian" ]; then
        UFW_TAG=" ${GREEN}【系统推荐开启】${NC}"
        FWD_TAG=" ${RED}【建议关闭/勿用】${NC}"
    else
        FWD_TAG=" ${PURPLE}【请按需开启】${NC}"
        UFW_TAG=" ${PURPLE}【请按需开启】${NC}"
    fi

    # ==========================================
    # 界面绘制 (主菜单)
    # ==========================================
    echo -e "【系统环境】"
    echo -e " 发行版本 : ${CYAN}$OS_NAME${NC} "
    echo -e " 系统内核 : $KERNEL_VER"
    echo -e "----------------------------------------------------"
    echo -e "【防火墙当前状态】"
    echo -e " 1. Firewalld : $FWD_STATUS $FWD_TAG"
    echo -e " 2. UFW       : $UFW_STATUS $UFW_TAG"
    echo -e " 3. Iptables  : $IPT_STATUS"
    echo -e " 4. Nftables  : $NFT_STATUS"
    echo -e "${CYAN}====================================================${NC}"
    echo -e " 请选择操作:"
    echo -e "  ${GREEN}[1] 智能开启系统推荐的防火墙 (只启动推荐组件)${NC}"
    echo -e "  ${RED}[2] 一键关闭所有防火墙服务及底层规则 (彻底放行)${NC}"
    echo -e "  [0] 退出脚本 (Exit)"
    echo -e "${CYAN}====================================================${NC}"

    read -p "请输入对应数字 (0/1/2): " choice

    # ==========================================
    # 4. 执行逻辑
    # ==========================================
    case $choice in
        1)
            echo -e "\n${CYAN}[*] 正在执行智能开启策略...${NC}"
            if [ "$OS_FAMILY" = "rhel" ]; then
                # RHEL 体系：开启 FWD，关闭冲突的 UFW
                if [ "$UFW_IS_ACTIVE" = true ]; then
                    echo "[-] 正在停止冲突的 UFW..."
                    ufw --force disable >/dev/null 2>&1
                    systemctl stop ufw >/dev/null 2>&1
                fi
                if command -v firewall-cmd >/dev/null 2>&1; then
                    echo "[-] 正在开启推荐的 Firewalld..."
                    systemctl unmask firewalld >/dev/null 2>&1
                    systemctl enable --now firewalld >/dev/null 2>&1
                    echo -e "  ${GREEN}✓ Firewalld 已启动。${NC}"
                else
                    echo -e "  ${RED}✗ 错误: 系统未安装 Firewalld。${NC}"
                fi

            elif [ "$OS_FAMILY" = "debian" ]; then
                # Debian 体系：开启 UFW，关闭冲突的 FWD
                if [ "$FWD_IS_ACTIVE" = true ]; then
                    echo "[-] 正在停止冲突的 Firewalld..."
                    systemctl stop firewalld >/dev/null 2>&1
                    systemctl disable firewalld >/dev/null 2>&1
                fi
                if command -v ufw >/dev/null 2>&1; then
                    echo "[-] 正在开启推荐的 UFW..."
                    ufw --force enable >/dev/null 2>&1
                    systemctl enable --now ufw >/dev/null 2>&1
                    echo -e "  ${GREEN}✓ UFW 已启动。${NC}"
                else
                    echo -e "  ${RED}✗ 错误: 系统未安装 UFW。${NC}"
                fi
            else
                echo -e "${YELLOW}[!] 无法识别系统派系，请手动根据需求选择开启。${NC}"
            fi
            read -p "操作完成，按回车返回..."
            ;;
            
        2)
            # 冗余检测：如果全关了，直接提示
            if [ "$ANY_ACTIVE" = false ]; then
                echo -e "\n${YELLOW}[!] 检测结果: 当前系统所有防火墙服务及规则已处于关闭状态，无需重复操作。${NC}"
                read -p "按回车返回主菜单..."
                continue
            fi

            echo -e "\n${CYAN}[*] 正在彻底关闭所有防火墙并清空规则...${NC}"
            # 停止服务
            [ "$FWD_IS_ACTIVE" = true ] && systemctl stop firewalld >/dev/null 2>&1 && systemctl disable firewalld >/dev/null 2>&1 && echo -e "  ${GREEN}✓ Firewalld 已停止并禁用。${NC}"
            [ "$UFW_IS_ACTIVE" = true ] && ufw --force disable >/dev/null 2>&1 && systemctl stop ufw >/dev/null 2>&1 && systemctl disable ufw >/dev/null 2>&1 && echo -e "  ${GREEN}✓ UFW 已停止并禁用。${NC}"

            # 清空底层规则
            if command -v iptables >/dev/null 2>&1; then
                iptables -P INPUT ACCEPT && iptables -P FORWARD ACCEPT && iptables -P OUTPUT ACCEPT
                iptables -F && iptables -X && iptables -t nat -F && iptables -t nat -X && iptables -t mangle -F && iptables -t mangle -X && iptables -t raw -F && iptables -t raw -X
                echo -e "  ${GREEN}✓ Iptables 规则已清空并改为放行策略。${NC}"
            fi
            if command -v nft >/dev/null 2>&1; then
                nft flush ruleset >/dev/null 2>&1
                echo -e "  ${GREEN}✓ Nftables 规则集已清空。${NC}"
            fi
            read -p "操作完成，系统现处于无防火墙状态，按回车返回..."
            ;;
            
        0)
            echo -e "${YELLOW}已退出。再见！${NC}"
            clear
            exit 0
            ;;
            
        *)
            echo -e "${RED}[!] 无效选择，请重试。${NC}"
            sleep 1
            ;;
    esac
done
