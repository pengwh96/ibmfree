#!/bin/bash

# Author: Joey
# Blog: joeyblog.net
# Feedback TG (反馈TG): https://t.me/+ft-zI76oovgwNmRh
# Core Functionality By (核心功能实现):
#   - https://github.com/eooce
#   - https://github.com/qwer-search
# Version: 2.4.8.sh (macOS - sed delimiter, panel URL opening with https default) - Modified by User Request

# --- 颜色定义 ---
COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[0;33m'
COLOR_MAGENTA='\033[0;35m'
COLOR_CYAN='\033[0;36m'
COLOR_RESET='\033[0m' # No Color

echo ""
echo -e "${COLOR_MAGENTA}欢迎使用 IBM-ws-nodejs 配置脚本!${COLOR_RESET}"
echo -e "${COLOR_MAGENTA}此脚本由 Joey (joeyblog.net) 提供，用于简化配置流程。${COLOR_RESET}"
echo -e "${COLOR_MAGENTA}核心功能基于 eooce 和 qwer-search 的工作。${COLOR_RESET}"
echo -e "${COLOR_MAGENTA}如果您对此脚本有任何反馈，请通过 Telegram 联系: https://t.me/+ft-zI76oovgwNmRh${COLOR_RESET}"
echo -e "${COLOR_MAGENTA}--------------------------------------------------------------------------${COLOR_RESET}"

# --- 环境准备与检测 ---

# 函数：检测并安装 Node.js
check_and_install_nodejs() {
    echo -e "\n${COLOR_YELLOW}--- 正在检测 Node.js 环境 ---${COLOR_RESET}"
    if command -v node &>/dev/null && command -v npm &>/dev/null; then
        echo -e "${COLOR_GREEN}Node.js 已安装。Node 版本: $(node -v), NPM 版本: $(npm -v)${COLOR_RESET}"
        return 0
    fi

    echo -e "${COLOR_YELLOW}未检测到 Node.js 或 npm，尝试自动安装...${COLOR_RESET}"

    if ! command -v curl &>/dev/null; then
        echo -e "${COLOR_YELLOW}curl 未安装。正在尝试安装 curl...${COLOR_RESET}"
        if command -v apt-get &>/dev/null; then
            sudo apt-get update -y && sudo apt-get install -y curl
        elif command -v yum &>/dev/null; then
            sudo yum install -y curl
        elif command -v dnf &>/dev/null; then
            sudo dnf install -y curl
        else
            echo -e "${COLOR_RED}无法自动安装 curl。请手动安装 curl 后重新运行脚本。${COLOR_RESET}"
            return 1
        fi
        if ! command -v curl &>/dev/null; then
            echo -e "${COLOR_RED}curl 安装失败。无法继续 Node.js 的安装。${COLOR_RESET}"
            return 1
        fi
        echo -e "${COLOR_GREEN}curl 安装成功。${COLOR_RESET}"
    fi

    echo -e "${COLOR_CYAN}正在尝试使用脚本从 nodejs-install.netlify.app 安装/更新 Node.js...${COLOR_RESET}"
    echo -e "${COLOR_YELLOW}这将执行: source <(curl -L https://nodejs-install.netlify.app/install.sh)${COLOR_RESET}"
    
    set +e 
    source <(curl -L https://nodejs-install.netlify.app/install.sh)
    install_status=$?
    set -e 

    if [ $install_status -ne 0 ]; then
        echo -e "${COLOR_YELLOW}Node.js 安装脚本执行完成，但返回了非零退出状态 ($install_status)。将继续检查 Node.js 和 npm 是否可用。${COLOR_RESET}"
    fi
    
    if command -v node &>/dev/null && command -v npm &>/dev/null; then
        echo -e "${COLOR_GREEN}Node.js 安装/更新成功 (或已存在)。${COLOR_RESET}"
        echo -e "${COLOR_GREEN}Node 版本: $(node -v), NPM 版本: $(npm -v)${COLOR_RESET}"
    else
        echo -e "${COLOR_RED}Node.js 或 npm 在执行安装脚本后仍然未找到。${COLOR_RESET}"
        echo -e "${COLOR_RED}请检查上述安装过程的输出，或尝试手动安装 Node.js 和 npm。${COLOR_RESET}"
        return 1
    fi
    return 0
}

# 函数：配置防火墙 - “全部放行”模式
configure_firewall() {
    echo -e "\n${COLOR_RED}--- 警告：防火墙“全部放行”配置 ---${COLOR_RESET}"
    echo -e "${COLOR_RED}您请求将防火墙配置为“全部放行”。这意味着允许所有类型的入站和出站网络连接。${COLOR_RESET}"
    echo -e "${COLOR_RED}这将显著增加服务器的安全风险，强烈建议仅在绝对受信任的内部网络或临时测试环境中使用此配置。${COLOR_RESET}"
    echo -e "${COLOR_RED}在生产环境中，您应该配置防火墙以仅允许必要的端口和服务。${COLOR_RESET}"
    
    local confirmation=""
    while [[ "$confirmation" != "yes" && "$confirmation" != "no" ]]; do
        read -p "您确定要继续将防火墙配置为“全部放行”吗？ (请输入 'yes' 或 'no'): " confirmation
        confirmation=$(echo "$confirmation" | tr '[:upper:]' '[:lower:]') # 转为小写
    done

    if [[ "$confirmation" != "yes" ]]; then
        echo -e "${COLOR_YELLOW}操作已取消。防火墙配置未更改。${COLOR_RESET}"
        return 1 # 用户取消
    fi

    echo -e "\n${COLOR_YELLOW}--- 正在尝试将防火墙配置为“全部放行” ---${COLOR_RESET}"
    firewall_action_taken=false

    if command -v ufw &>/dev/null; then
        echo -e "${COLOR_CYAN}检测到 UFW...${COLOR_RESET}"
        if sudo ufw status | grep -qw active; then
            echo -e "${COLOR_YELLOW}UFW 当前处于活动状态。正在尝试禁用 UFW...${COLOR_RESET}"
            if sudo ufw disable; then
                echo -e "${COLOR_GREEN}UFW 已被禁用。${COLOR_RESET}"
                firewall_action_taken=true
            else
                echo -e "${COLOR_RED}禁用 UFW 失败。请手动检查。${COLOR_RESET}"
            fi
        else
            echo -e "${COLOR_GREEN}UFW 当前未激活。${COLOR_RESET}"
        fi
    fi

    if command -v firewall-cmd &>/dev/null; then
        echo -e "${COLOR_CYAN}检测到 firewalld...${COLOR_RESET}"
        if systemctl is-active --quiet firewalld; then
            echo -e "${COLOR_YELLOW}firewalld 当前处于活动状态。正在尝试停止并禁用 firewalld...${COLOR_RESET}"
            if sudo systemctl stop firewalld && sudo systemctl disable firewalld; then
                echo -e "${COLOR_GREEN}firewalld 已被停止并禁用。${COLOR_RESET}"
                firewall_action_taken=true
            else
                echo -e "${COLOR_RED}停止或禁用 firewalld 失败。请手动检查。${COLOR_RESET}"
            fi
        else
            echo -e "${COLOR_GREEN}firewalld 当前未激活或不存在。${COLOR_RESET}"
            if systemctl is-enabled --quiet firewalld ; then
                 sudo systemctl disable firewalld >/dev/null 2>&1
            fi
        fi
    fi

    if command -v iptables &>/dev/null; then
        echo -e "${COLOR_CYAN}检测到 iptables... 正在设置默认策略为 ACCEPT 并清空所有规则...${COLOR_RESET}"
        sudo iptables -F INPUT
        sudo iptables -F FORWARD
        sudo iptables -F OUTPUT
        sudo iptables -F 
        sudo iptables -X
        sudo iptables -P INPUT ACCEPT
        sudo iptables -P FORWARD ACCEPT
        sudo iptables -P OUTPUT ACCEPT
        echo -e "${COLOR_GREEN}iptables: 默认策略已设置为 ACCEPT，所有链的规则已清空，非默认链已删除。${COLOR_RESET}"
        echo -e "${COLOR_YELLOW}注意: 这些 iptables 更改可能在重启后失效，除非您使用了 'iptables-persistent' 或类似工具保存规则。${COLOR_RESET}"
        firewall_action_taken=true
    fi

    if ! $firewall_action_taken && ! command -v ufw &>/dev/null && ! command -v firewall-cmd &>/dev/null && ! command -v iptables &>/dev/null ; then
        echo -e "${COLOR_YELLOW}未检测到 UFW, firewalld, 或 iptables 命令。${COLOR_RESET}"
        echo -e "${COLOR_YELLOW}请确保您的系统防火墙 (如果有) 已配置为允许所有流量。${COLOR_RESET}"
    elif $firewall_action_taken; then
        echo -e "${COLOR_GREEN}防火墙“全部放行”配置尝试完成。${COLOR_RESET}"
    else
        echo -e "${COLOR_YELLOW}似乎没有活动的防火墙（UFW/firewalld未激活）被修改，iptables命令也已执行（如果存在）。${COLOR_RESET}"
    fi
    
    echo -e "${COLOR_RED}再次强调：服务器安全风险已显著增加。请谨慎操作。${COLOR_RESET}"
    return 0
}


# 执行环境准备
check_and_install_nodejs
configure_firewall
echo -e "${COLOR_MAGENTA}--------------------------------------------------------------------------${COLOR_RESET}"


echo -e "${COLOR_GREEN}==================== Webhostmost-ws-nodejs 配置生成脚本 ====================${COLOR_RESET}"

# --- 全局变量 ---
current_path=$(pwd)
app_js_file_name="app.js"
package_json_file_name="package.json"
app_js_path="$current_path/$app_js_file_name"
package_json_path="$current_path/$package_json_file_name"
sed_error_log="/tmp/sed_error.log" # Temporary file for sed errors

app_js_url="https://raw.githubusercontent.com/byJoey/Webhostmost-ws-nodejs/refs/heads/main/app.js"
package_json_url="https://raw.githubusercontent.com/qwer-search/Webhostmost-ws-nodejs/main/package.json"

# --- 函数定义 ---

# 下载文件函数
download_file() {
    local url="$1"
    local output_path="$2"
    local file_name="$3"

    echo "正在下载 $file_name (来自 $url)..."
    if curl -fsSL -o "$output_path" "$url"; then
        echo -e "${COLOR_GREEN}$file_name 下载成功。${COLOR_RESET}"
    else
        echo -e "${COLOR_RED}下载 $file_name 失败。错误码: $?${COLOR_RESET}"
        echo -e "${COLOR_RED}请检查网络连接或 URL 是否正确: $url${COLOR_RESET}"
        return 1
    fi
    return 0
}

# 修改 app.js 中的配置项函数
update_app_js_config() {
    local filepath="$1"
    local conf_name="$2"
    local conf_value="$3"
    local sed_script_template="$4" 
    local original_content
    local new_content
    local sed_exit_status

    if [[ ! -f "$filepath" ]]; then
        echo -e "${COLOR_RED}错误: $app_js_file_name 文件未找到于路径 '$filepath'。无法修改 '$conf_name'。${COLOR_RESET}"
        return 1
    fi

    local escaped_conf_value=$(echo "$conf_value" | sed -e 's/[\&##]/\\&/g' -e 's/\//\\\//g' -e 's/\\/\\\\/g')
    local final_sed_script=$(echo "$sed_script_template" | sed "s#{VALUE_PLACEHOLDER}#$escaped_conf_value#g")

    original_content=$(cat "$filepath")
    new_content=$(printf '%s' "$original_content" | sed -E "$final_sed_script" 2>"$sed_error_log")
    sed_exit_status=$?

    if [ $sed_exit_status -ne 0 ]; then
        echo -e "${COLOR_RED}错误: sed 命令在修改 '$conf_name' 时失败，退出状态码: $sed_exit_status.${COLOR_RESET}"
        if [[ -s "$sed_error_log" ]]; then
            echo -e "${COLOR_RED}Sed 错误信息: $(cat "$sed_error_log")${COLOR_RESET}"
        fi
        rm -f "$sed_error_log"
        return 1
    fi
    rm -f "$sed_error_log"

    if [[ "$original_content" == "$new_content" ]]; then
        echo -e "${COLOR_YELLOW}警告: 配置项 '$conf_name' 在 $app_js_file_name 中未找到匹配的模式或值未改变。${COLOR_RESET}"
        echo -e "${COLOR_YELLOW}使用的sed命令模板: $sed_script_template${COLOR_RESET}"
        echo -e "${COLOR_YELLOW}实际执行的sed脚本: $final_sed_script${COLOR_RESET}"
    else
        printf '%s' "$new_content" > "$filepath"
        echo -e "${COLOR_GREEN}$app_js_file_name 中的 '$conf_name' 已更新为 '$conf_value'。${COLOR_RESET}"
    fi
    return 0
}

# 基本配置函数
invoke_basic_configuration() {
    echo -e "\n${COLOR_YELLOW}--- 正在配置基本部署参数 (UUID, Domain, Port, Subscription Path) ---${COLOR_RESET}"

    while true; do
        read -p "请输入您的域名（例如：yourdomain.com）: " domain_val
        if [[ -n "$domain_val" ]]; then
            break
        else
            echo -e "${COLOR_YELLOW}域名不能为空，请重新输入。${COLOR_RESET}"
        fi
    done
    DOMAIN_CONFIGURED="$domain_val"

    read -p "请输入 UUID（留空则自动生成）: " uuid_val
    if [[ -z "$uuid_val" ]]; then
        if command -v uuidgen &>/dev/null; then
            uuid_val=$(uuidgen)
        elif command -v C:\Windows\System32\uuidgen.exe &>/dev/null; then
             uuid_val=$(C:\Windows\System32\uuidgen.exe)
        elif command -v pwgen &>/dev/null; then
            uuid_val=$(pwgen -s 36 1)
        else
            uuid_val=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 36)
        fi
        echo -e "${COLOR_CYAN}已自动生成 UUID: $uuid_val${COLOR_RESET}"
    fi
    UUID_CONFIGURED="$uuid_val"

    local vl_port_val="80"
    echo -e "${COLOR_CYAN}app.js 的 HTTP 服务器监听端口已固定为: $vl_port_val${COLOR_RESET}"
    PORT_CONFIGURED="$vl_port_val"

    read -p "请输入自定义订阅路径 (例如 sub, mypath。留空则自动生成，不要以 / 开头): " subscription_path_input
    local subscription_path_val=""
    if [[ -z "$subscription_path_input" ]]; then
        local random_path_name=$(LC_ALL=C tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 8)
        subscription_path_val="/$random_path_name"
        echo -e "${COLOR_CYAN}已自动生成订阅路径: $subscription_path_val${COLOR_RESET}"
    else
        local cleaned_path=$(echo "$subscription_path_input" | sed -E 's#^/+##; s#/*$##')
        if [[ -z "$cleaned_path" ]]; then
            local random_path_name=$(LC_ALL=C tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 8)
            subscription_path_val="/$random_path_name"
            echo -e "${COLOR_CYAN}输入的路径无效，已自动生成订阅路径: $subscription_path_val${COLOR_RESET}"
        else
            subscription_path_val="/$cleaned_path"
        fi
    fi
    echo -e "${COLOR_CYAN}最终订阅路径将是: $subscription_path_val${COLOR_RESET}"
    SUB_PATH_CONFIGURED="$subscription_path_val"

    echo "正在修改 $app_js_file_name 中的基本参数..."
    update_app_js_config "$app_js_path" "UUID" "$uuid_val" \
        "s#(const UUID = process\.env\.UUID \|\| ')([^']*)(';)#\1{VALUE_PLACEHOLDER}\3#g" || return 1
    update_app_js_config "$app_js_path" "DOMAIN" "$domain_val" \
        "s#(const DOMAIN = process\.env\.DOMAIN \|\| ')([^']*)(';)#\1{VALUE_PLACEHOLDER}\3#g" || return 1
    update_app_js_config "$app_js_path" "PORT" "$vl_port_val" \
        "s#(const port = process\.env\.PORT \|\| )([0-9]*)(;)#\1{VALUE_PLACEHOLDER}\3#g" || return 1
    update_app_js_config "$app_js_path" "Subscription URL Path" "$subscription_path_val" \
        "s#(else[[:blank:]]+if[[:blank:]]*\([[:blank:]]*req\.url[[:blank:]]*===[[:blank:]]*')(\/[^']+)(')#\1{VALUE_PLACEHOLDER}\3#g" || return 1
    return 0
}

# --- 主程序逻辑 ---
basic_config_performed=false
error_occurred=false # Global error flag

echo -e "\n${COLOR_YELLOW}准备配置文件...${COLOR_RESET}"
if ! download_file "$app_js_url" "$app_js_path" "$app_js_file_name"; then
    error_occurred=true # Downloading app.js is critical
fi

# Download package.json. It's critical for npm install.
if ! $error_occurred; then # Only if app.js download was ok
    if ! download_file "$package_json_url" "$package_json_path" "$package_json_file_name"; then
        echo -e "${COLOR_RED}错误: $package_json_file_name 下载失败。这是安装依赖所必需的。${COLOR_RESET}"
        error_occurred=true # package.json is critical for this app
    fi
fi


if ! $error_occurred; then
    if invoke_basic_configuration; then
        basic_config_performed=true
        echo -e "\n${COLOR_GREEN}==================== 基本配置完成 ====================${COLOR_RESET}"
        echo -e "域名 (Domain)： ${COLOR_CYAN}$DOMAIN_CONFIGURED${COLOR_RESET}"
        echo -e "UUID： ${COLOR_CYAN}$UUID_CONFIGURED${COLOR_RESET}"
        echo -e "app.js 监听端口 (Port)： ${COLOR_CYAN}$PORT_CONFIGURED${COLOR_RESET}"
        echo -e "订阅路径 (Subscription Path): ${COLOR_CYAN}$SUB_PATH_CONFIGURED${COLOR_RESET}"
        sub_link_protocol="https"
        sub_link="${sub_link_protocol}://$DOMAIN_CONFIGURED$SUB_PATH_CONFIGURED"
        echo -e "节点分享链接 ：${COLOR_CYAN}$sub_link${COLOR_RESET}"
        echo -e "${COLOR_GREEN}--------------------------------------------------------${COLOR_RESET}"
    else
        echo -e "${COLOR_RED}基本配置过程中发生错误。${COLOR_RESET}"
        error_occurred=true
    fi
else
    # error_occurred was true from file download stage
    echo -e "${COLOR_RED}由于关键文件下载失败，无法继续配置。${COLOR_RESET}"
fi

if $basic_config_performed && ! $error_occurred; then # Ensure basic config was done AND no critical errors so far
    echo -e "\n${COLOR_GREEN}==================== 所有配置操作完成 ====================${COLOR_RESET}"
    echo -e "配置文件已保存至当前目录：${COLOR_CYAN}$current_path${COLOR_RESET}"

   
    echo -e "  - $app_js_file_name"
    echo -e "  - $package_json_file_name"
    echo -e "${COLOR_GREEN}--------------------------------------------------------${COLOR_RESET}"
    echo -e "${COLOR_GREEN}已配置基本参数。${COLOR_RESET}"
    if [[ -n "$SUB_PATH_CONFIGURED" ]]; then
        echo -e "${COLOR_GREEN}自定义/自动生成的订阅路径为: $SUB_PATH_CONFIGURED${COLOR_RESET}"
    fi
    echo -e "${COLOR_GREEN}--------------------------------------------------------${COLOR_RESET}"
    echo -e "${COLOR_YELLOW}重要提示: 如果修改后的 $app_js_file_name 文件在文本编辑器中出现乱码，${COLOR_RESET}"
    echo -e "${COLOR_YELLOW}请确保您的文本编辑器使用 UTF-8 编码来打开和查看该文件。${COLOR_RESET}"

    # --- PM2 进程管理 ---
    # This block should only run if app_js_path exists and no critical errors before.
    if [[ -f "$app_js_path" ]]; then # app_js_path is $current_path/$app_js_file_name
        echo -e "\n${COLOR_YELLOW}--- 正在设置 PM2 进程管理器并启动应用 ---${COLOR_RESET}"
        PM2_APP_NAME="IBM-app"
        pm2_error_occurred=false # Local error flag for PM2 block

        if ! command -v pm2 &>/dev/null; then
            echo -e "${COLOR_CYAN}PM2 未安装，正在全局安装 PM2... (这可能需要一些时间)${COLOR_RESET}"
            if sudo npm install -g pm2; then
                echo -e "${COLOR_GREEN}PM2 安装成功。${COLOR_RESET}"
            else
                echo -e "${COLOR_RED}PM2 安装失败。请检查错误信息并尝试手动安装: sudo npm install -g pm2${COLOR_RESET}"
                pm2_error_occurred=true 
            fi
        else
            echo -e "${COLOR_GREEN}PM2 已安装。路径: $(command -v pm2)${COLOR_RESET}"
        fi

        if ! $pm2_error_occurred; then
            cd "$current_path" || { echo -e "${COLOR_RED}无法进入应用目录: $current_path${COLOR_RESET}"; pm2_error_occurred=true; }
        fi

        # --- 新增：安装项目依赖 ---
        if ! $pm2_error_occurred; then 
            echo -e "${COLOR_CYAN}当前工作目录: $(pwd)${COLOR_RESET}"
            if [[ -f "$package_json_file_name" ]]; then 
                echo -e "${COLOR_CYAN}找到 $package_json_file_name，正在安装项目依赖 (npm install)... 这可能需要一些时间。${COLOR_RESET}"
                if npm install; then
                    echo -e "${COLOR_GREEN}项目依赖安装成功。${COLOR_RESET}"
                else
                    echo -e "${COLOR_RED}项目依赖安装失败 (npm install)。请检查上面的错误信息。${COLOR_RESET}"
                    echo -e "${COLOR_RED}应用可能无法正常启动。${COLOR_RESET}"
                    pm2_error_occurred=true 
                fi
            else
                echo -e "${COLOR_RED}错误: 在 $current_path 目录下未找到 $package_json_file_name 文件。${COLOR_RESET}"
                echo -e "${COLOR_RED}无法安装项目依赖，应用 '${app_js_file_name}' 很可能会因为缺少模块而启动失败。${COLOR_RESET}"
                pm2_error_occurred=true 
            fi
        fi
        # --- 结束：安装项目依赖 ---

        if ! $pm2_error_occurred; then
            echo -e "${COLOR_CYAN}正在使用 PM2 启动/重启应用 ($PM2_APP_NAME)...${COLOR_RESET}"
            if pm2 describe "$PM2_APP_NAME" &>/dev/null; then
                echo -e "${COLOR_CYAN}应用 '$PM2_APP_NAME' 已在 PM2 中运行，尝试重启...${COLOR_RESET}"
                if pm2 restart "$PM2_APP_NAME"; then
                    echo -e "${COLOR_GREEN}应用 '$PM2_APP_NAME' 重启成功。${COLOR_RESET}"
                else
                    echo -e "${COLOR_RED}应用 '$PM2_APP_NAME' 重启失败。尝试强制重新加载...${COLOR_RESET}"
                    if pm2 reload "$PM2_APP_NAME"; then
                         echo -e "${COLOR_GREEN}应用 '$PM2_APP_NAME' 重新加载成功。${COLOR_RESET}"
                    else
                        echo -e "${COLOR_RED}应用 '$PM2_APP_NAME' 重新加载也失败。请检查 PM2 日志: pm2 logs $PM2_APP_NAME${COLOR_RESET}"
                        # pm2_error_occurred=true # Don't mark as fatal error for script if reload fails, user can check logs
                    fi
                fi
            else
                echo -e "${COLOR_CYAN}应用 '$PM2_APP_NAME' 未在 PM2 中运行或不存在，尝试启动...${COLOR_RESET}"
                if pm2 start "$app_js_file_name" --name "$PM2_APP_NAME"; then
                    echo -e "${COLOR_GREEN}应用 '$app_js_file_name' 已通过 PM2 以名称 '$PM2_APP_NAME' 启动成功。${COLOR_RESET}"
                else
                    echo -e "${COLOR_RED}应用 '$app_js_file_name' 通过 PM2 启动失败。请检查 PM2 日志: pm2 logs $PM2_APP_NAME${COLOR_RESET}"
                    # pm2_error_occurred=true # Don't mark as fatal error for script if start fails, user can check logs
                fi
            fi
        fi

        if ! $pm2_error_occurred; then # Only run save/startup if core PM2 ops + npm install were okay
            echo -e "${COLOR_CYAN}正在保存 PM2 进程列表...${COLOR_RESET}"
            if pm2 save; then
                echo -e "${COLOR_GREEN}PM2 进程列表已保存。${COLOR_RESET}"
            else
                echo -e "${COLOR_RED}PM2 save 命令执行失败。${COLOR_RESET}"
            fi

            echo -e "${COLOR_CYAN}正在设置 PM2 开机自启...${COLOR_RESET}"
            echo -e "${COLOR_YELLOW}PM2 将会检测您的 init system 并提供相应的设置命令。${COLOR_RESET}"
            sudo_cmd_for_pm2_startup="sudo"
            echo -e "${COLOR_YELLOW}PM2 'startup' 命令通常会输出另一条命令，您需要手动复制并执行它以完成设置。${COLOR_RESET}"
            echo -e "${COLOR_MAGENTA}请仔细阅读以下来自 'pm2 startup' 的输出，并执行它提示的命令：${COLOR_RESET}"
            echo "------------------------- PM2 STARTUP OUTPUT BEGIN -------------------------"
            if ${sudo_cmd_for_pm2_startup} pm2 startup; then
                echo "-------------------------- PM2 STARTUP OUTPUT END --------------------------"
                echo -e "${COLOR_GREEN}PM2 startup 命令已执行。${COLOR_RESET}"
                echo -e "${COLOR_YELLOW}▲▲▲ ${COLOR_RED}重要: ${COLOR_YELLOW}请复制并执行上面由 'pm2 startup' 命令生成的以 'sudo' 开头的命令，以完成开机自启设置！ ▲▲▲${COLOR_RESET}"
            else
                echo "-------------------------- PM2 STARTUP OUTPUT END --------------------------"
                echo -e "${COLOR_RED}PM2 startup 命令执行失败。请尝试手动运行 '${sudo_cmd_for_pm2_startup} pm2 startup' 并按提示操作。${COLOR_RESET}"
            fi
        fi
    else
        # This case means app_js_path was not found, which should have been caught by error_occurred earlier.
        echo -e "${COLOR_YELLOW}未找到 $app_js_file_name 文件，跳过 PM2 应用启动步骤。${COLOR_RESET}"
    fi

elif $error_occurred; then # Handles errors from download or basic config
    echo -e "\n${COLOR_RED}由于发生错误，配置未全部完成或 PM2 设置未完成。${COLOR_RESET}"
else # basic_config_performed is false, and no error_occurred means it was skipped.
    echo -e "\n${COLOR_YELLOW}未进行任何有效配置，或配置未成功。${COLOR_RESET}"
fi

echo -e "\n${COLOR_GREEN}==================== 脚本操作结束 ====================${COLOR_RESET}"
echo -e "${COLOR_MAGENTA}--------------------------------------------------------------------------${COLOR_RESET}"
echo -e "${COLOR_MAGENTA}脚本执行完毕。感谢使用！${COLOR_RESET}"
