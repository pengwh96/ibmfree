#!/bin/bash

# Author: Joey
# Blog: joeyblog.net
# Feedback TG (Feedback Telegram): https://t.me/+ft-zI76oovgwNmRh
# Core Functionality By:
#   - https://github.com/eooce
# Version: 2.4.8.sh (macOS - sed delimiter, panel URL opening with https default) - Modified by User Request

# --- Color Definitions ---
COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[0;33m'
COLOR_MAGENTA='\033[0;35m'
COLOR_CYAN='\033[0;36m'
COLOR_RESET='\033[0m' # No Color

echo ""
echo -e "${COLOR_MAGENTA}Welcome to the IBM-ws-nodejs Configuration Script!${COLOR_RESET}"
echo -e "${COLOR_MAGENTA}This script is provided by Joey (joeyblog.net) to simplify the configuration process.${COLOR_RESET}"
echo -e "${COLOR_MAGENTA}Core functionality is based on the work of eooce and qwer-search.${COLOR_RESET}"
echo -e "${COLOR_MAGENTA}If you have any feedback on this script, please contact via Telegram: https://t.me/+ft-zI76oovgwNmRh${COLOR_RESET}"
echo -e "${COLOR_MAGENTA}--------------------------------------------------------------------------${COLOR_RESET}"

# --- Environment Preparation and Detection ---

#!/bin/bash

# --- 读取用户输入的函数 ---
read_input() {
  local prompt="$1"
  local variable_name="$2"
  local default_value="$3"
  local advice="$4"

  if [ -n "$advice" ]; then
    echo -e "\033[36m$advice\033[0m" # 青色用于提示信息
  fi

  if [ -n "$default_value" ]; then
    read -p "$prompt [$default_value]: " user_input
    eval "$variable_name=\"${user_input:-$default_value}\""
  else
    read -p "$prompt: " user_input
    eval "$variable_name=\"$user_input\""
  fi
  echo # 新行以提高可读性
}

# --- 交互式脚本开始 ---
echo "---------------------------------------------------------------------"
echo "欢迎使用交互式配置向导。"
echo "此脚本将帮助您生成所需的环境变量并选择是否自动运行部署。"
echo "按 Enter键可跳过可选字段或使用默认值。"
echo "---------------------------------------------------------------------"
echo

# --- UUID ---
echo -e "\033[1mUUID:\033[0m"
echo -e "\033[36m原始脚本提到: 'export UUID=自动不输入自动生成' (不输入则自动生成)。\033[0m"
echo -e "\033[36m对于此向导，我们假设如果您未在此处指定 UUID，主脚本将负责自动生成。\033[0m"
read_input "如果您想指定一个 UUID (否则将由主脚本自动生成):" CUSTOM_UUID
echo

# --- 哪吒探针配置 ---
echo -e "\033[1m--- 哪吒探针配置 (Nezha Probe Configuration) ---\033[0m"
read -p "您想配置哪吒探针吗? (y/N): " configure_nezha
configure_nezha=$(echo "$configure_nezha" | tr '[:upper:]' '[:lower:]')
echo

if [[ "$configure_nezha" == "y" ]]; then
  read_input "哪吒面板域名:" NEZHA_SERVER "" "v1 填写形式：nezha.xxx.com:8008；v0 填写形式：nezha.xxx.com"

  echo -e "\033[36m请确定您使用的是 v0 还是 v1 版本的哪吒面板配置。\033[0m"
  echo -e "\033[36m- 如果您的 NEZHA_SERVER 已包含端口 (例如 nezha.xxx.com:8008), 则可能是 v1 版本，不需要单独设置 NEZHA_PORT。\033[0m"
  echo -e "\033[36m- 如果您的 NEZHA_SERVER 仅为域名 (例如 nezha.xxx.com), 则可能是 v0 版本，需要指定 NEZHA_PORT。\033[0m"
  read -p "您上面输入的 NEZHA_SERVER 是否已包含端口 (v1 版典型特征)? (y/N): " nezha_server_includes_port
  nezha_server_includes_port=$(echo "$nezha_server_includes_port" | tr '[:upper:]' '[:lower:]')
  echo

  if [[ "$nezha_server_includes_port" == "y" ]]; then
    NEZHA_PORT="" # v1, 不需要 NEZHA_PORT
    echo -e "\033[33mNEZHA_PORT 将留空 (v1 类型配置)。\033[0m"
  else
    read_input "哪吒 Agent 端口 (v0 版使用):" NEZHA_PORT "" "v1 哪吒不要填写这个。v0 哪吒 Agent 端口，端口为 {443, 8443, 2096, 2087, 2083, 2053} 之一时开启 TLS"
  fi

  read_input "哪吒的 NZ_CLIENT_SECRET (v1 版) 或 Agent 密钥 (v0 版):" NEZHA_KEY
else
  NEZHA_SERVER=""
  NEZHA_PORT=""
  NEZHA_KEY=""
  echo -e "\033[33m已跳过哪吒探针配置。\033[0m"
fi
echo

# --- Argo 隧道配置 ---
echo -e "\033[1m--- Argo 隧道配置 (Argo Tunnel Configuration) ---\033[0m"
read -p "您想配置 Argo 隧道吗? (y/N): " configure_argo
configure_argo=$(echo "$configure_argo" | tr '[:upper:]' '[:lower:]')
echo

if [[ "$configure_argo" == "y" ]]; then
  read_input "Argo 域名 (例如 sub.yourdomain.com)。留空则启用临时隧道:" ARGO_DOMAIN "" "留空即启用临时隧道 (例如 xxx.trycloudflare.com)。"
  if [ -n "$ARGO_DOMAIN" ]; then
    read_input "Argo Token 或 JSON (如果您指定了 ARGO_DOMAIN 则需要):" ARGO_AUTH
  else
    ARGO_AUTH=""
    echo -e "\033[33mARGO_AUTH 将留空，因为将使用临时隧道。\033[0m"
  fi
else
  ARGO_DOMAIN=""
  ARGO_AUTH=""
  echo -e "\033[33m已跳过 Argo 隧道配置。\033[0m"
fi
echo

# --- 其他配置 ---
echo -e "\033[1m--- 其他配置 (Other Configurations) ---\033[0m"
read_input "节点名称:" NAME "ibm"

read -p "您想配置 Cloudflare 优选 IP/域名 (CFIP) 吗? (y/N): " configure_cfip
configure_cfip=$(echo "$configure_cfip" | tr '[:upper:]' '[:lower:]')
echo

if [[ "$configure_cfip" == "y" ]]; then
  read_input "优选 IP 或优选域名 (CFIP):" CFIP "www.visa.com.tw"
  read_input "优选 IP 或优选域名对应端口 (CFPORT):" CFPORT "443"
else
  CFIP=""
  CFPORT=""
  echo -e "\033[33m已跳过优选 IP/域名配置。\033[0m"
fi
echo

read -p "您想配置 Telegram 推送通知吗? (y/N): " configure_telegram
configure_telegram=$(echo "$configure_telegram" | tr '[:upper:]' '[:lower:]')
echo

if [[ "$configure_telegram" == "y" ]]; then
  read_input "Telegram Chat ID:" CHAT_ID "" "需要同时填写 Chat ID 和 Bot Token 才能推送到 Telegram。"
  read_input "Telegram Bot Token:" BOT_TOKEN
else
  CHAT_ID=""
  BOT_TOKEN=""
  echo -e "\033[33m已跳过 Telegram 配置。\033[0m"
fi
echo

read -p "您想配置节点自动推送到订阅器 (merge-sub) 吗? (y/N): " configure_upload
configure_upload=$(echo "$configure_upload" | tr '[:upper:]' '[:lower:]')
echo

if [[ "$configure_upload" == "y" ]]; then
  read_input "上传 URL (例如 https://merge.example.com):" UPLOAD_URL "" "需要填写部署 merge-sub 项目后的首页地址，例如：https://merge.eooce.ggff.net"
else
  UPLOAD_URL=""
  echo -e "\033[33m已跳过上传 URL 配置。\033[0m"
fi
echo

# --- 配置摘要 ---
echo "---------------------------------------------------------------------"
echo -e "\033[1m配置摘要:\033[0m"
echo "---------------------------------------------------------------------"
echo "UUID: \"${CUSTOM_UUID:-<将由主脚本自动生成>}\"" # Adjusted for clarity
echo "NEZHA_SERVER: \"$NEZHA_SERVER\""
echo "NEZHA_PORT: \"$NEZHA_PORT\""
echo "NEZHA_KEY: \"$NEZHA_KEY\""
echo "ARGO_DOMAIN: \"$ARGO_DOMAIN\""
echo "ARGO_AUTH: \"$ARGO_AUTH\""
echo "NAME: \"$NAME\""
echo "CFIP: \"$CFIP\""
echo "CFPORT: \"$CFPORT\""
echo "CHAT_ID: \"$CHAT_ID\""
echo "BOT_TOKEN: \"$BOT_TOKEN\""
echo "UPLOAD_URL: \"$UPLOAD_URL\""
echo "---------------------------------------------------------------------"
echo

# --- 执行部署脚本 ---
read -p "您想使用这些配置自动运行部署脚本吗? (Y/n): " auto_execute_script
auto_execute_script=$(echo "$auto_execute_script" | tr '[:upper:]' '[:lower:]')
echo

if [[ "$auto_execute_script" == "y" || "$auto_execute_script" == "" ]]; then
  echo -e "\033[33m警告：接下来的步骤将从外部来源 (https://main.ssss.nyc.mn/sb.sh) 下载并执行 'sb.sh' 脚本。\033[0m"
  echo -e "\033[33m请确保您信任此脚本来源及其内容，执行未知脚本可能存在安全风险。\033[0m"
  read -p "确实要继续执行吗? (y/N): " final_confirmation
  final_confirmation=$(echo "$final_confirmation" | tr '[:upper:]' '[:lower:]')
  echo

  if [[ "$final_confirmation" == "y" ]]; then
    echo "正在导出配置并执行部署脚本..."

    # 导出变量
    if [ -n "$CUSTOM_UUID" ]; then
      export UUID="$CUSTOM_UUID"
    else
      # 如果用户未提供CUSTOM_UUID，则不导出UUID，让sb.sh自行处理。
      # 或者根据sb.sh的行为，可以 export UUID=""
      # 为安全起见，此处选择不主动导出空UUID，依赖sb.sh的默认行为。
      # 如果sb.sh期望一个空的UUID来触发生成，则应取消下面一行的注释：
      # export UUID=""
      : # 无操作，表示如果CUSTOM_UUID为空，则不导出
    fi
    export NEZHA_SERVER="$NEZHA_SERVER"
    export NEZHA_PORT="$NEZHA_PORT"
    export NEZHA_KEY="$NEZHA_KEY"
    export ARGO_DOMAIN="$ARGO_DOMAIN"
    export ARGO_AUTH="$ARGO_AUTH"
    export NAME="$NAME"
    export CFIP="$CFIP"
    export CFPORT="$CFPORT"
    export CHAT_ID="$CHAT_ID"
    export BOT_TOKEN="$BOT_TOKEN"
    export UPLOAD_URL="$UPLOAD_URL"

    # 执行主部署脚本
    bash <(curl -Ls https://main.ssss.nyc.mn/sb.sh)

    echo "部署脚本已尝试执行。"
  else
    echo "自动运行已取消。"
  fi
else
  echo "自动运行已跳过。如果您想手动运行，请复制上面的配置摘要并设置环境变量后，"
  echo "再执行: bash <(curl -Ls https://main.ssss.nyc.mn/sb.sh)"
fi

echo "---------------------------------------------------------------------"
echo "配置向导已完成。"
echo "---------------------------------------------------------------------"
