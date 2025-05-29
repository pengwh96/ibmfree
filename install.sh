#!/bin/bash

COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[0;33m'
COLOR_MAGENTA='\033[0;35m'
COLOR_CYAN='\033[0;36m'
COLOR_RESET='\033[0m'

display_welcome_message() {
    clear
    echo -e "${COLOR_CYAN}===================================================================${COLOR_RESET}"
    echo -e "${COLOR_MAGENTA}      Welcome to the IBM-ws-nodejs Application Management Script (${SCRIPT_VERSION})${COLOR_RESET}"
    echo -e "${COLOR_CYAN}===================================================================${COLOR_RESET}"
    echo ""
    echo -e "${COLOR_GREEN}This script will help you install, configure, and manage the IBM-ws-nodejs application.${COLOR_RESET}"
    echo -e "${COLOR_GREEN}The application will be managed by PM2 to ensure stable operation and easy management.${COLOR_RESET}"
    echo ""
    echo -e "${COLOR_YELLOW}Script Author: Joey (joeyblog.net)${COLOR_RESET}"
    echo -e "${COLOR_YELLOW}Core Functionality By: eooce, qwer-search${COLOR_RESET}"
    echo -e "${COLOR_YELLOW}Feedback TG: https://t.me/+ft-zI76oovgwNmRh${COLOR_RESET}"
}

echo ""
echo -e "${COLOR_MAGENTA}Welcome to the IBM-ws-nodejs Configuration Script!${COLOR_RESET}"
echo -e "${COLOR_MAGENTA}This script is provided by Joey (joeyblog.net) to simplify the configuration process.${COLOR_RESET}"
echo -e "${COLOR_MAGENTA}Core functionality is based on the work of eooce and qwer-search.${COLOR_RESET}"
echo -e "${COLOR_MAGENTA}If you have any feedback on this script, please contact via Telegram: https://t.me/+ft-zI76oovgwNmRh${COLOR_RESET}"
echo -e "${COLOR_MAGENTA}--------------------------------------------------------------------------${COLOR_RESET}"

check_and_install_nodejs() {
    echo -e "\n${COLOR_YELLOW}--- Checking Node.js environment ---${COLOR_RESET}"
    if command -v node &>/dev/null && command -v npm &>/dev/null; then
        echo -e "${COLOR_GREEN}Node.js is already installed. Node version: $(node -v), NPM version: $(npm -v)${COLOR_RESET}"
        return 0
    fi

    echo -e "${COLOR_YELLOW}Node.js or npm not detected, attempting automatic installation...${COLOR_RESET}"

    if ! command -v curl &>/dev/null; then
        echo -e "${COLOR_YELLOW}curl is not installed. Attempting to install curl...${COLOR_RESET}"
        if command -v apt-get &>/dev/null; then
            sudo apt-get update -y && sudo apt-get install -y curl
        elif command -v yum &>/dev/null; then
            sudo yum install -y curl
        elif command -v dnf &>/dev/null; then
            sudo dnf install -y curl
        else
            echo -e "${COLOR_RED}Cannot automatically install curl. Please install curl manually and re-run the script.${COLOR_RESET}"
            return 1
        fi
        if ! command -v curl &>/dev/null; then
            echo -e "${COLOR_RED}curl installation failed. Cannot proceed with Node.js installation.${COLOR_RESET}"
            return 1
        fi
        echo -e "${COLOR_GREEN}curl installed successfully.${COLOR_RESET}"
    fi

    echo -e "${COLOR_CYAN}Attempting to install/update Node.js using script from nodejs-install.netlify.app...${COLOR_RESET}"
    echo -e "${COLOR_YELLOW}This will execute: source <(curl -L https://nodejs-install.netlify.app/install.sh)${COLOR_RESET}"
    
    set +e 
    source <(curl -L https://nodejs-install.netlify.app/install.sh)
    install_status=$?
    set -e 

    if [ $install_status -ne 0 ]; then
        echo -e "${COLOR_YELLOW}Node.js installation script finished but returned a non-zero exit status ($install_status). Will proceed to check if Node.js and npm are available.${COLOR_RESET}"
    fi
    
    if command -v node &>/dev/null && command -v npm &>/dev/null; then
        echo -e "${COLOR_GREEN}Node.js installation/update successful (or already existed).${COLOR_RESET}"
        echo -e "${COLOR_GREEN}Node version: $(node -v), NPM version: $(npm -v)${COLOR_RESET}"
    else
        echo -e "${COLOR_RED}Node.js or npm still not found after executing the installation script.${COLOR_RESET}"
        echo -e "${COLOR_RED}Please check the output of the installation process above, or try to install Node.js and npm manually.${COLOR_RESET}"
        return 1
    fi
    return 0
}

configure_firewall() {
    echo -e "\n${COLOR_YELLOW}--- Firewall Configuration: Allowing Specific Ports ---${COLOR_RESET}"
    echo -e "${COLOR_CYAN}This script will attempt to configure your firewall to:${COLOR_RESET}"
    echo -e "${COLOR_CYAN}  1. Deny all incoming connections by default.${COLOR_RESET}"
    echo -e "${COLOR_CYAN}  2. Allow all outgoing connections by default.${COLOR_RESET}"
    echo -e "${COLOR_CYAN}  3. Specifically allow incoming TCP traffic on port 80 (HTTP).${COLOR_RESET}"
    echo -e "${COLOR_CYAN}  4. Specifically allow incoming TCP traffic on port 22 (SSH - essential for server access).${COLOR_RESET}"
    echo -e "${COLOR_YELLOW}This is a more secure approach than allowing all traffic.${COLOR_RESET}"
    
    local confirmation=""
    while [[ "$confirmation" != "yes" && "$confirmation" != "no" ]]; do
        read -p "Do you want to proceed with this firewall configuration? (Please enter 'yes' or 'no'): " confirmation
        confirmation=$(echo "$confirmation" | tr '[:upper:]' '[:lower:]')
    done

    if [[ "$confirmation" != "yes" ]]; then
        echo -e "${COLOR_YELLOW}Operation cancelled. Firewall configuration has not been changed.${COLOR_RESET}"
        return 1
    fi

    echo -e "\n${COLOR_YELLOW}--- Attempting to configure firewall for ports 80 (HTTP) and 22 (SSH) ---${COLOR_RESET}"
    firewall_action_taken=false

    if command -v ufw &>/dev/null; then
        echo -e "${COLOR_CYAN}UFW detected... Configuring UFW...${COLOR_RESET}"
        echo -e "${COLOR_YELLOW}Resetting UFW to defaults...${COLOR_RESET}"
        if sudo ufw reset; then 
            sudo ufw default deny incoming
            sudo ufw default allow outgoing
            echo -e "${COLOR_GREEN}UFW default policies set (deny incoming, allow outgoing).${COLOR_RESET}"
            sudo ufw allow 22/tcp comment 'Allow SSH'
            echo -e "${COLOR_GREEN}UFW: Allowed TCP port 22 (SSH).${COLOR_RESET}"
            sudo ufw allow 80/tcp comment 'Allow HTTP'
            echo -e "${COLOR_GREEN}UFW: Allowed TCP port 80 (HTTP).${COLOR_RESET}"
            if echo "y" | sudo ufw enable; then 
                 echo -e "${COLOR_GREEN}UFW enabled successfully.${COLOR_RESET}"
                 firewall_action_taken=true
            else
                echo -e "${COLOR_RED}Failed to enable UFW. Please check manually. You may need to run 'sudo ufw enable' and confirm.${COLOR_RESET}"
            fi
        else
            echo -e "${COLOR_RED}Failed to reset UFW. Please check UFW status and configure manually.${COLOR_RESET}"
        fi
    fi

    if command -v firewall-cmd &>/dev/null; then
        echo -e "${COLOR_CYAN}firewalld detected... Configuring firewalld...${COLOR_RESET}"
        if ! systemctl is-active --quiet firewalld; then
            echo -e "${COLOR_YELLOW}firewalld is not active. Attempting to start and enable it...${COLOR_RESET}"
            if sudo systemctl start firewalld && sudo systemctl enable firewalld; then
                echo -e "${COLOR_GREEN}firewalld started and enabled successfully.${COLOR_RESET}"
            else
                echo -e "${COLOR_RED}Failed to start or enable firewalld. Please check manually.${COLOR_RESET}"
            fi
        else
             echo -e "${COLOR_GREEN}firewalld is active.${COLOR_RESET}"
        fi
        
        if systemctl is-active --quiet firewalld; then
            echo -e "${COLOR_YELLOW}Adding rules for ports 22/tcp (SSH) and 80/tcp (HTTP) to firewalld...${COLOR_RESET}"
            if sudo firewall-cmd --permanent --zone=public --add-port=22/tcp && \
               sudo firewall-cmd --permanent --zone=public --add-port=80/tcp; then
                echo -e "${COLOR_GREEN}firewalld: Ports 22/tcp and 80/tcp added to permanent configuration.${COLOR_RESET}"
                if sudo firewall-cmd --reload; then
                    echo -e "${COLOR_GREEN}firewalld reloaded successfully. Rules are active.${COLOR_RESET}"
                    firewall_action_taken=true
                else
                    echo -e "${COLOR_RED}firewalld failed to reload. Please check 'sudo firewall-cmd --reload' and 'sudo systemctl status firewalld'.${COLOR_RESET}"
                fi
            else
                 echo -e "${COLOR_RED}firewalld: Failed to add ports 22/tcp or 80/tcp to permanent configuration.${COLOR_RESET}"
            fi
        else
            echo -e "${COLOR_RED}firewalld is not active. Skipping firewalld configuration for rules.${COLOR_RESET}"
        fi
    fi

    if command -v iptables &>/dev/null; then
        echo -e "${COLOR_CYAN}iptables detected... Configuring iptables...${COLOR_RESET}"
        echo -e "${COLOR_YELLOW}Flushing existing rules and setting secure default policies...${COLOR_RESET}"
        sudo iptables -F INPUT
        sudo iptables -F FORWARD
        sudo iptables -F OUTPUT
        sudo iptables -F 
        sudo iptables -X 

        sudo iptables -P INPUT DROP
        sudo iptables -P FORWARD DROP
        sudo iptables -P OUTPUT ACCEPT
        echo -e "${COLOR_GREEN}iptables: Default policies set (INPUT/FORWARD DROP, OUTPUT ACCEPT).${COLOR_RESET}"

        sudo iptables -A INPUT -i lo -j ACCEPT
        echo -e "${COLOR_GREEN}iptables: Allowed loopback traffic.${COLOR_RESET}"

        sudo iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
        echo -e "${COLOR_GREEN}iptables: Allowed RELATED/ESTABLISHED connections.${COLOR_RESET}"

        sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT
        echo -e "${COLOR_GREEN}iptables: Allowed incoming TCP traffic on port 22 (SSH).${COLOR_RESET}"
        
        sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
        echo -e "${COLOR_GREEN}iptables: Allowed incoming TCP traffic on port 80 (HTTP).${COLOR_RESET}"
        
        echo -e "${COLOR_YELLOW}Note: These iptables changes may be lost after a reboot unless you use 'iptables-persistent' or a similar tool to save rules.${COLOR_RESET}"
        firewall_action_taken=true
    fi

    if ! $firewall_action_taken && ! command -v ufw &>/dev/null && ! command -v firewall-cmd &>/dev/null && ! command -v iptables &>/dev/null ; then
        echo -e "${COLOR_YELLOW}No UFW, firewalld, or iptables command detected.${COLOR_RESET}"
        echo -e "${COLOR_YELLOW}Please ensure your system firewall (if any) is configured to allow TCP traffic on ports 80 and 22.${COLOR_RESET}"
    elif $firewall_action_taken; then
        echo -e "${COLOR_GREEN}Firewall configuration for ports 80 (HTTP) and 22 (SSH) attempted.${COLOR_RESET}"
    else
        echo -e "${COLOR_YELLOW}No known firewall utility was successfully configured. Please check firewall status manually.${COLOR_RESET}"
    fi
    
    echo -e "${COLOR_GREEN}Firewall configuration attempt complete. Please verify your connectivity and firewall status.${COLOR_RESET}"
    return 0
}

check_and_install_nodejs
configure_firewall
echo -e "${COLOR_MAGENTA}--------------------------------------------------------------------------${COLOR_RESET}"

echo -e "${COLOR_GREEN}==================== IBM-ws-nodejs Configuration Generation Script ====================${COLOR_RESET}"

current_path=$(pwd)
app_js_file_name="app.js"
package_json_file_name="package.json"
app_js_path="$current_path/$app_js_file_name"
package_json_path="$current_path/$package_json_file_name"
sed_error_log="/tmp/sed_error.log"

app_js_url="https://raw.githubusercontent.com/byJoey/IBM-ws-nodejs/refs/heads/main/app.js"
package_json_url="https://raw.githubusercontent.com/qwer-search/IBM-ws-nodejs/main/package.json"

download_file() {
    local url="$1"
    local output_path="$2"
    local file_name="$3"

    echo "Downloading $file_name (from $url)..."
    if curl -fsSL -o "$output_path" "$url"; then
        echo -e "${COLOR_GREEN}$file_name downloaded successfully.${COLOR_RESET}"
    else
        echo -e "${COLOR_RED}Failed to download $file_name. Error code: $?${COLOR_RESET}"
        echo -e "${COLOR_RED}Please check your network connection or if the URL is correct: $url${COLOR_RESET}"
        return 1
    fi
    return 0
}

update_app_js_config() {
    local filepath="$1"
    local conf_name="$2"
    local conf_value="$3"
    local sed_script_template="$4" 
    local original_content
    local new_content
    local sed_exit_status

    if [[ ! -f "$filepath" ]]; then
        echo -e "${COLOR_RED}Error: $app_js_file_name file not found at path '$filepath'. Cannot modify '$conf_name'.${COLOR_RESET}"
        return 1
    fi

    local escaped_conf_value=$(echo "$conf_value" | sed -e 's/[\&##]/\\&/g' -e 's/\//\\\//g' -e 's/\\/\\\\/g')
    local final_sed_script=$(echo "$sed_script_template" | sed "s#{VALUE_PLACEHOLDER}#$escaped_conf_value#g")

    original_content=$(cat "$filepath")
    new_content=$(printf '%s' "$original_content" | sed -E "$final_sed_script" 2>"$sed_error_log")
    sed_exit_status=$?

    if [ $sed_exit_status -ne 0 ]; then
        echo -e "${COLOR_RED}Error: sed command failed while modifying '$conf_name', exit status: $sed_exit_status.${COLOR_RESET}"
        if [[ -s "$sed_error_log" ]]; then
            echo -e "${COLOR_RED}Sed error message: $(cat "$sed_error_log")${COLOR_RESET}"
        fi
        rm -f "$sed_error_log"
        return 1
    fi
    rm -f "$sed_error_log"

    if [[ "$original_content" == "$new_content" ]]; then
        echo -e "${COLOR_YELLOW}Warning: Configuration item '$conf_name' did not find a matching pattern or the value was unchanged in $app_js_file_name.${COLOR_RESET}"
        echo -e "${COLOR_YELLOW}sed command template used: $sed_script_template${COLOR_RESET}"
        echo -e "${COLOR_YELLOW}Actual sed script executed: $final_sed_script${COLOR_RESET}"
    else
        printf '%s' "$new_content" > "$filepath"
        echo -e "${COLOR_GREEN}'$conf_name' in $app_js_file_name has been updated to '$conf_value'.${COLOR_RESET}"
    fi
    return 0
}

invoke_basic_configuration() {
    echo -e "\n${COLOR_YELLOW}--- Configuring basic deployment parameters (UUID, Domain, Port, Subscription Path) ---${COLOR_RESET}"

    while true; do
        read -p "Please enter your domain (e.g., yourdomain.freeIBM.com): " domain_val
        if [[ -n "$domain_val" ]]; then
            break
        else
            echo -e "${COLOR_YELLOW}Domain cannot be empty, please re-enter.${COLOR_RESET}"
        fi
    done
    DOMAIN_CONFIGURED="$domain_val"

    read -p "Please enter UUID (leave blank to auto-generate): " uuid_val
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
        echo -e "${COLOR_CYAN}Auto-generated UUID: $uuid_val${COLOR_RESET}"
    fi
    UUID_CONFIGURED="$uuid_val"

    local vl_port_val="80"
    echo -e "${COLOR_CYAN}The HTTP server listening port for app.js is fixed to: $vl_port_val${COLOR_RESET}"
    PORT_CONFIGURED="$vl_port_val"

    read -p "Please enter custom subscription path (e.g. sub, mypath. Leave blank for auto-generation, do not start with /): " subscription_path_input
    local subscription_path_val=""
    if [[ -z "$subscription_path_input" ]]; then
        local random_path_name=$(LC_ALL=C tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 8)
        subscription_path_val="/$random_path_name"
        echo -e "${COLOR_CYAN}Auto-generated subscription path: $subscription_path_val${COLOR_RESET}"
    else
        local cleaned_path=$(echo "$subscription_path_input" | sed -E 's#^/+##; s#/*$##')
        if [[ -z "$cleaned_path" ]]; then
            local random_path_name=$(LC_ALL=C tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 8)
            subscription_path_val="/$random_path_name"
            echo -e "${COLOR_CYAN}Invalid path entered, auto-generated subscription path: $subscription_path_val${COLOR_RESET}"
        else
            subscription_path_val="/$cleaned_path"
        fi
    fi
    echo -e "${COLOR_CYAN}The final subscription path will be: $subscription_path_val${COLOR_RESET}"
    SUB_PATH_CONFIGURED="$subscription_path_val"

    echo "Modifying basic parameters in $app_js_file_name..."
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

basic_config_performed=false
error_occurred=false

echo -e "\n${COLOR_YELLOW}Preparing configuration files...${COLOR_RESET}"
if ! download_file "$app_js_url" "$app_js_path" "$app_js_file_name"; then
    error_occurred=true
fi

if ! $error_occurred; then
    if ! download_file "$package_json_url" "$package_json_path" "$package_json_file_name"; then
        echo -e "${COLOR_RED}Error: $package_json_file_name download failed. This is necessary for installing dependencies.${COLOR_RESET}"
        error_occurred=true
    fi
fi

if ! $error_occurred; then
    if invoke_basic_configuration; then
        basic_config_performed=true
        echo -e "\n${COLOR_GREEN}==================== Basic Configuration Complete ====================${COLOR_RESET}"
        echo -e "Domain: ${COLOR_CYAN}$DOMAIN_CONFIGURED${COLOR_RESET}"
        echo -e "UUID: ${COLOR_CYAN}$UUID_CONFIGURED${COLOR_RESET}"
        echo -e "app.js Listening Port: ${COLOR_CYAN}$PORT_CONFIGURED${COLOR_RESET}"
        echo -e "Subscription Path: ${COLOR_CYAN}$SUB_PATH_CONFIGURED${COLOR_RESET}"
        sub_link_protocol="https"
        sub_link="${sub_link_protocol}://$DOMAIN_CONFIGURED$SUB_PATH_CONFIGURED"
        echo -e "VLESS Subscription Link: ${COLOR_CYAN}$sub_link${COLOR_RESET}"
        echo -e "${COLOR_GREEN}--------------------------------------------------------${COLOR_RESET}"
    else
        echo -e "${COLOR_RED}An error occurred during basic configuration.${COLOR_RESET}"
        error_occurred=true
    fi
else
    echo -e "${COLOR_RED}Cannot continue configuration due to critical file download failure.${COLOR_RESET}"
fi

if $basic_config_performed && ! $error_occurred; then
    echo -e "\n${COLOR_GREEN}==================== All Configuration Operations Complete ====================${COLOR_RESET}"
    echo -e "Configuration files have been saved to the current directory: ${COLOR_CYAN}$current_path${COLOR_RESET}"
    echo -e "  - $app_js_file_name"
    echo -e "  - $package_json_file_name"
    echo -e "${COLOR_GREEN}--------------------------------------------------------${COLOR_RESET}"
    echo -e "${COLOR_GREEN}Basic parameters configured.${COLOR_RESET}"
    if [[ -n "$SUB_PATH_CONFIGURED" ]]; then
        echo -e "${COLOR_GREEN}Custom/auto-generated subscription path is: $SUB_PATH_CONFIGURED${COLOR_RESET}"
    fi
    echo -e "${COLOR_GREEN}--------------------------------------------------------${COLOR_RESET}"
    echo -e "${COLOR_YELLOW}Important Note: If the modified $app_js_file_name file appears garbled in a text editor,${COLOR_RESET}"
    echo -e "${COLOR_YELLOW}please ensure your text editor is using UTF-8 encoding to open and view the file.${COLOR_RESET}"

    if [[ -f "$app_js_path" ]]; then
        echo -e "\n${COLOR_YELLOW}--- Setting up PM2 process manager and starting the application ---${COLOR_RESET}"
        PM2_APP_NAME="IBM-app"
        pm2_error_occurred=false

        if ! command -v pm2 &>/dev/null; then
            echo -e "${COLOR_CYAN}PM2 is not installed, installing PM2 globally... (This may take some time)${COLOR_RESET}"
            if sudo npm install -g pm2; then
                echo -e "${COLOR_GREEN}PM2 installed successfully.${COLOR_RESET}"
            else
                echo -e "${COLOR_RED}PM2 installation failed. Please check error messages and try to install manually: sudo npm install -g pm2${COLOR_RESET}"
                pm2_error_occurred=true 
            fi
        else
            echo -e "${COLOR_GREEN}PM2 is already installed. Path: $(command -v pm2)${COLOR_RESET}"
        fi

        if ! $pm2_error_occurred; then
            cd "$current_path" || { echo -e "${COLOR_RED}Cannot change to application directory: $current_path${COLOR_RESET}"; pm2_error_occurred=true; }
        fi

        if ! $pm2_error_occurred; then 
            echo -e "${COLOR_CYAN}Current working directory: $(pwd)${COLOR_RESET}"
            if [[ -f "$package_json_file_name" ]]; then 
                echo -e "${COLOR_CYAN}Found $package_json_file_name, installing project dependencies (npm install)... This may take some time.${COLOR_RESET}"
                if npm install; then
                    echo -e "${COLOR_GREEN}Project dependencies installed successfully.${COLOR_RESET}"
                else
                    echo -e "${COLOR_RED}Project dependencies installation failed (npm install). Please check the error messages above.${COLOR_RESET}"
                    echo -e "${COLOR_RED}The application might not start correctly.${COLOR_RESET}"
                    pm2_error_occurred=true 
                fi
            else
                echo -e "${COLOR_RED}Error: $package_json_file_name not found in $current_path directory.${COLOR_RESET}"
                echo -e "${COLOR_RED}Cannot install project dependencies, application '${app_js_file_name}' will likely fail to start due to missing modules.${COLOR_RESET}"
                pm2_error_occurred=true 
            fi
        fi

        if ! $pm2_error_occurred; then
            echo -e "${COLOR_CYAN}Starting/Restarting application ($PM2_APP_NAME) using PM2...${COLOR_RESET}"
            if pm2 describe "$PM2_APP_NAME" &>/dev/null; then
                echo -e "${COLOR_CYAN}Application '$PM2_APP_NAME' is already running in PM2, attempting restart...${COLOR_RESET}"
                if pm2 restart "$PM2_APP_NAME"; then
                    echo -e "${COLOR_GREEN}Application '$PM2_APP_NAME' restarted successfully.${COLOR_RESET}"
                else
                    echo -e "${COLOR_RED}Application '$PM2_APP_NAME' restart failed. Attempting force reload...${COLOR_RESET}"
                    if pm2 reload "$PM2_APP_NAME"; then
                         echo -e "${COLOR_GREEN}Application '$PM2_APP_NAME' reloaded successfully.${COLOR_RESET}"
                    else
                        echo -e "${COLOR_RED}Application '$PM2_APP_NAME' reload also failed. Please check PM2 logs: pm2 logs $PM2_APP_NAME${COLOR_RESET}"
                    fi
                fi
            else
                echo -e "${COLOR_CYAN}Application '$PM2_APP_NAME' is not running in PM2 or does not exist, attempting to start...${COLOR_RESET}"
                if pm2 start "$app_js_file_name" --name "$PM2_APP_NAME"; then
                    echo -e "${COLOR_GREEN}Application '$app_js_file_name' started successfully via PM2 with name '$PM2_APP_NAME'.${COLOR_RESET}"
                else
                    echo -e "${COLOR_RED}Application '$app_js_file_name' failed to start via PM2. Please check PM2 logs: pm2 logs $PM2_APP_NAME${COLOR_RESET}"
                fi
            fi
        fi

        if ! $pm2_error_occurred; then
            echo -e "${COLOR_CYAN}Saving PM2 process list...${COLOR_RESET}"
            if pm2 save; then
                echo -e "${COLOR_GREEN}PM2 process list saved.${COLOR_RESET}"
            else
                echo -e "${COLOR_RED}PM2 save command execution failed.${COLOR_RESET}"
            fi

            echo -e "${COLOR_CYAN}Setting up PM2 to start on boot...${COLOR_RESET}"
            echo -e "${COLOR_YELLOW}PM2 will detect your init system and provide corresponding setup commands.${COLOR_RESET}"
            sudo_cmd_for_pm2_startup="sudo"
            echo -e "${COLOR_YELLOW}The PM2 'startup' command will usually output another command that you need to copy and execute manually to complete the setup.${COLOR_RESET}"
            echo -e "${COLOR_MAGENTA}Please carefully read the output from 'pm2 startup' below and execute the command it prompts:${COLOR_RESET}"
            echo "------------------------- PM2 STARTUP OUTPUT BEGIN -------------------------"
            if ${sudo_cmd_for_pm2_startup} pm2 startup; then
                echo "-------------------------- PM2 STARTUP OUTPUT END --------------------------"
                echo -e "${COLOR_GREEN}PM2 startup command executed.${COLOR_RESET}"
                echo -e "${COLOR_YELLOW}▲▲▲ ${COLOR_RED}IMPORTANT: ${COLOR_YELLOW}Please copy and execute the command starting with 'sudo' generated by 'pm2 startup' above to complete boot setup! ▲▲▲${COLOR_RESET}"
            else
                echo "-------------------------- PM2 STARTUP OUTPUT END --------------------------"
                echo -e "${COLOR_RED}PM2 startup command execution failed. Please try running '${sudo_cmd_for_pm2_startup} pm2 startup' manually and follow the prompts.${COLOR_RESET}"
            fi
        fi
    else
        echo -e "${COLOR_YELLOW}$app_js_file_name file not found, skipping PM2 application startup steps.${COLOR_RESET}"
    fi

elif $error_occurred; then
    echo -e "\n${COLOR_RED}Due to errors, configuration was not fully completed or PM2 setup was not finished.${COLOR_RESET}"
else
    echo -e "\n${COLOR_YELLOW}No effective configuration was performed, or configuration was not successful.${COLOR_RESET}"
fi

echo -e "\n${COLOR_GREEN}==================== Script Operations Ended ====================${COLOR_RESET}"
echo -e "${COLOR_MAGENTA}--------------------------------------------------------------------------${COLOR_RESET}"
echo -e "${COLOR_MAGENTA}Script execution finished. Thank you for using!${COLOR_RESET}"
