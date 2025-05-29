#!/bin/bash

# Author: Joey
# Blog: joeyblog.net
# Feedback TG (Feedback Telegram): https://t.me/+ft-zI76oovgwNmRh
# Core Functionality By:
#   - https://github.com/eooce
#   - https://github.com/qwer-search
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

# Function: Detect and install Node.js
check_and_install_nodejs() {
    echo -e "\n${COLOR_YELLOW}--- Checking Node.js Environment ---${COLOR_RESET}"
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
            echo -e "${COLOR_RED}curl installation failed. Cannot continue Node.js installation.${COLOR_RESET}"
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
        echo -e "${COLOR_YELLOW}Node.js installation script executed, but returned a non-zero exit status ($install_status). Will proceed to check if Node.js and npm are available.${COLOR_RESET}"
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

# Function: Configure firewall - "Allow All" mode
configure_firewall() {
    echo -e "\n${COLOR_RED}--- Warning: Firewall 'Allow All' Configuration ---${COLOR_RESET}"
    echo -e "${COLOR_RED}You have requested to configure the firewall to 'allow all'. This means all types of inbound and outbound network connections will be permitted.${COLOR_RESET}"
    echo -e "${COLOR_RED}This will significantly increase the security risk to your server. It is strongly recommended to use this configuration only in absolutely trusted internal networks or temporary testing environments.${COLOR_RESET}"
    echo -e "${COLOR_RED}In a production environment, you should configure the firewall to allow only necessary ports and services.${COLOR_RESET}"
    
    local confirmation=""
    while [[ "$confirmation" != "yes" && "$confirmation" != "no" ]]; do
        read -p "Are you sure you want to proceed with configuring the firewall to 'allow all'? (Please enter 'yes' or 'no'): " confirmation
        confirmation=$(echo "$confirmation" | tr '[:upper:]' '[:lower:]') # Convert to lowercase
    done

    if [[ "$confirmation" != "yes" ]]; then
        echo -e "${COLOR_YELLOW}Operation cancelled. Firewall configuration unchanged.${COLOR_RESET}"
        return 1 # User cancelled
    fi

    echo -e "\n${COLOR_YELLOW}--- Attempting to configure firewall to 'allow all' ---${COLOR_RESET}"
    firewall_action_taken=false

    if command -v ufw &>/dev/null; then
        echo -e "${COLOR_CYAN}Detected UFW...${COLOR_RESET}"
        if sudo ufw status | grep -qw active; then
            echo -e "${COLOR_YELLOW}UFW is currently active. Attempting to disable UFW...${COLOR_RESET}"
            if sudo ufw disable; then
                echo -e "${COLOR_GREEN}UFW has been disabled.${COLOR_RESET}"
                firewall_action_taken=true
            else
                echo -e "${COLOR_RED}Failed to disable UFW. Please check manually.${COLOR_RESET}"
            fi
        else
            echo -e "${COLOR_GREEN}UFW is currently inactive.${COLOR_RESET}"
        fi
    fi

    if command -v firewall-cmd &>/dev/null; then
        echo -e "${COLOR_CYAN}Detected firewalld...${COLOR_RESET}"
        if systemctl is-active --quiet firewalld; then
            echo -e "${COLOR_YELLOW}firewalld is currently active. Attempting to stop and disable firewalld...${COLOR_RESET}"
            if sudo systemctl stop firewalld && sudo systemctl disable firewalld; then
                echo -e "${COLOR_GREEN}firewalld has been stopped and disabled.${COLOR_RESET}"
                firewall_action_taken=true
            else
                echo -e "${COLOR_RED}Failed to stop or disable firewalld. Please check manually.${COLOR_RESET}"
            fi
        else
            echo -e "${COLOR_GREEN}firewalld is currently inactive or does not exist.${COLOR_RESET}"
            if systemctl is-enabled --quiet firewalld ; then
                sudo systemctl disable firewalld >/dev/null 2>&1
            fi
        fi
    fi

    if command -v iptables &>/dev/null; then
        echo -e "${COLOR_CYAN}Detected iptables... Setting default policies to ACCEPT and flushing all rules...${COLOR_RESET}"
        sudo iptables -F INPUT
        sudo iptables -F FORWARD
        sudo iptables -F OUTPUT
        sudo iptables -F 
        sudo iptables -X
        sudo iptables -P INPUT ACCEPT
        sudo iptables -P FORWARD ACCEPT
        sudo iptables -P OUTPUT ACCEPT
        echo -e "${COLOR_GREEN}iptables: Default policies set to ACCEPT, rules for all chains flushed, non-default chains deleted.${COLOR_RESET}"
        echo -e "${COLOR_YELLOW}Note: These iptables changes may be lost on reboot unless you use 'iptables-persistent' or a similar tool to save rules.${COLOR_RESET}"
        firewall_action_taken=true
    fi

    if ! $firewall_action_taken && ! command -v ufw &>/dev/null && ! command -v firewall-cmd &>/dev/null && ! command -v iptables &>/dev/null ; then
        echo -e "${COLOR_YELLOW}UFW, firewalld, or iptables commands not detected.${COLOR_RESET}"
        echo -e "${COLOR_YELLOW}Please ensure your system firewall (if any) is configured to allow all traffic.${COLOR_RESET}"
    elif $firewall_action_taken; then
        echo -e "${COLOR_GREEN}Firewall 'allow all' configuration attempt completed.${COLOR_RESET}"
    else
        echo -e "${COLOR_YELLOW}It seems no active firewall (UFW/firewalld inactive) was modified, and iptables commands were executed (if present).${COLOR_RESET}"
    fi
    
    echo -e "${COLOR_RED}To reiterate: Server security risk has been significantly increased. Please proceed with caution.${COLOR_RESET}"
    return 0
}


# Execute environment preparation
check_and_install_nodejs
configure_firewall # User will be prompted
echo -e "${COLOR_MAGENTA}--------------------------------------------------------------------------${COLOR_RESET}"


echo -e "${COLOR_GREEN}==================== Webhostmost-ws-nodejs Configuration Script ====================${COLOR_RESET}"

# --- Global Variables ---
current_path=$(pwd)
app_js_file_name="app.js"
package_json_file_name="package.json"
app_js_path="$current_path/$app_js_file_name"
package_json_path="$current_path/$package_json_file_name"
sed_error_log="/tmp/sed_error.log" # Temporary file for sed errors

app_js_url="https://raw.githubusercontent.com/byJoey/Webhostmost-ws-nodejs/refs/heads/main/app.js"
package_json_url="https://raw.githubusercontent.com/qwer-search/Webhostmost-ws-nodejs/main/package.json"

# --- Function Definitions ---

# Download file function
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

# Function to modify configuration items in app.js
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

    # Escape special characters for sed: &, #, /, \
    local escaped_conf_value=$(echo "$conf_value" | sed -e 's/[\&##]/\\&/g' -e 's/\//\\\//g' -e 's/\\/\\\\/g')
    # Replace placeholder in template with escaped value
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
        echo -e "${COLOR_YELLOW}Warning: Configuration item '$conf_name' did not find a matching pattern in $app_js_file_name or the value was unchanged.${COLOR_RESET}"
        echo -e "${COLOR_YELLOW}Used sed command template: $sed_script_template${COLOR_RESET}"
        echo -e "${COLOR_YELLOW}Actual sed script executed: $final_sed_script${COLOR_RESET}"
    else
        printf '%s' "$new_content" > "$filepath"
        echo -e "${COLOR_GREEN}'$conf_name' in $app_js_file_name has been updated to '$conf_value'.${COLOR_RESET}"
    fi
    return 0
}

# Basic configuration function
invoke_basic_configuration() {
    echo -e "\n${COLOR_YELLOW}--- Configuring Basic Deployment Parameters (UUID, Domain, Port,  Path) ---${COLOR_RESET}"

    while true; do
        read -p "Please enter your domain name (e.g., yourdomain.com): " domain_val
        if [[ -n "$domain_val" ]]; then
            break
        else
            echo -e "${COLOR_YELLOW}Domain name cannot be empty, please re-enter.${COLOR_RESET}"
        fi
    done
    DOMAIN_CONFIGURED="$domain_val"

    read -p "Please enter UUID (leave blank to auto-generate): " uuid_val
    if [[ -z "$uuid_val" ]]; then
        if command -v uuidgen &>/dev/null; then
            uuid_val=$(uuidgen)
        elif command -v C:\Windows\System32\uuidgen.exe &>/dev/null; then # For Windows/WSL environments
             uuid_val=$(C:\Windows\System32\uuidgen.exe)
        elif command -v pwgen &>/dev/null; then
            uuid_val=$(pwgen -s 36 1)
        else
            # Fallback for systems without uuidgen or pwgen
            uuid_val=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 36)
        fi
        echo -e "${COLOR_CYAN}Auto-generated UUID: $uuid_val${COLOR_RESET}"
    fi
    UUID_CONFIGURED="$uuid_val"

    local vl_port_val="80" # Fixed port for the app.js server itself. External mapping handled by CF or similar.
    echo -e "${COLOR_CYAN}The HTTP server listening port for app.js is fixed to: $vl_port_val${COLOR_RESET}"
    PORT_CONFIGURED="$vl_port_val"

    read -p "Please enter a custom  path (e.g., sub, mypath. Leave blank for auto-generation, do not start with /): " _path_input
    local _path_val=""
    if [[ -z "$_path_input" ]]; then
        local random_path_name=$(LC_ALL=C tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 8)
        _path_val="/$random_path_name"
        echo -e "${COLOR_CYAN}Auto-generated  path: $_path_val${COLOR_RESET}"
    else
        # Remove leading and trailing slashes if user added them
        local cleaned_path=$(echo "$_path_input" | sed -E 's#^/+##; s#/*$##')
        if [[ -z "$cleaned_path" ]]; then # If input was just slashes or became empty
            local random_path_name=$(LC_ALL=C tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 8)
            _path_val="/$random_path_name"
            echo -e "${COLOR_CYAN}Invalid path entered, auto-generated  path: $_path_val${COLOR_RESET}"
        else
            _path_val="/$cleaned_path"
        fi
    fi
    echo -e "${COLOR_CYAN}The final  path will be: $_path_val${COLOR_RESET}"
    SUB_PATH_CONFIGURED="$_path_val"

    echo "Modifying basic parameters in $app_js_file_name..."
    update_app_js_config "$app_js_path" "UUID" "$uuid_val" \
        "s#(const UUID = process\.env\.UUID \|\| ')([^']*)(';)#\1{VALUE_PLACEHOLDER}\3#g" || return 1
    update_app_js_config "$app_js_path" "DOMAIN" "$domain_val" \
        "s#(const DOMAIN = process\.env\.DOMAIN \|\| ')([^']*)(';)#\1{VALUE_PLACEHOLDER}\3#g" || return 1
    update_app_js_config "$app_js_path" "PORT" "$vl_port_val" \
        "s#(const port = process\.env\.PORT \|\| )([0-9]*)(;)#\1{VALUE_PLACEHOLDER}\3#g" || return 1
    # Update  URL path. This regex looks for `else if (req.url === '/current_path')`
    update_app_js_config "$app_js_path" " URL Path" "$_path_val" \
        "s#(else[[:blank:]]+if[[:blank:]]*\([[:blank:]]*req\.url[[:blank:]]*===[[:blank:]]*')(\/[^']+)(')#\1{VALUE_PLACEHOLDER}\3#g" || return 1
    return 0
}

# --- Main Program Logic ---
basic_config_performed=false
error_occurred=false # Global error flag

echo -e "\n${COLOR_YELLOW}Preparing configuration files...${COLOR_RESET}"
if ! download_file "$app_js_url" "$app_js_path" "$app_js_file_name"; then
    error_occurred=true # Downloading app.js is critical
fi

# Download package.json. It's critical for npm install.
if ! $error_occurred; then # Only if app.js download was ok
    if ! download_file "$package_json_url" "$package_json_path" "$package_json_file_name"; then
        echo -e "${COLOR_RED}Error: $package_json_file_name download failed. This is necessary for installing dependencies.${COLOR_RESET}"
        error_occurred=true # package.json is critical for this app
    fi
fi


if ! $error_occurred; then
    if invoke_basic_configuration; then
        basic_config_performed=true
        echo -e "\n${COLOR_GREEN}==================== Basic Configuration Complete ====================${COLOR_RESET}"
        echo -e "Domain: ${COLOR_CYAN}$DOMAIN_CONFIGURED${COLOR_RESET}"
        echo -e "UUID: ${COLOR_CYAN}$UUID_CONFIGURED${COLOR_RESET}"
        echo -e "app.js Listening Port: ${COLOR_CYAN}$PORT_CONFIGURED${COLOR_RESET}"
        echo -e " Path: ${COLOR_CYAN}$SUB_PATH_CONFIGURED${COLOR_RESET}"
        sub_link_protocol="https" # Default to https for panel links
        sub_link="${sub_link_protocol}://$DOMAIN_CONFIGURED$SUB_PATH_CONFIGURED"
        echo -e " Link: ${COLOR_CYAN}$sub_link${COLOR_RESET}"
        echo -e "${COLOR_GREEN}--------------------------------------------------------${COLOR_RESET}"
    else
        echo -e "${COLOR_RED}An error occurred during basic configuration.${COLOR_RESET}"
        error_occurred=true
    fi
else
    # error_occurred was true from file download stage
    echo -e "${COLOR_RED}Cannot continue configuration due to critical file download failure.${COLOR_RESET}"
fi

if $basic_config_performed && ! $error_occurred; then # Ensure basic config was done AND no critical errors so far
    echo -e "\n${COLOR_GREEN}==================== All Configuration Operations Complete ====================${COLOR_RESET}"
    echo -e "Configuration files saved to the current directory: ${COLOR_CYAN}$current_path${COLOR_RESET}"
    
    echo -e "  - $app_js_file_name"
    echo -e "  - $package_json_file_name"
    echo -e "${COLOR_GREEN}--------------------------------------------------------${COLOR_RESET}"
    echo -e "${COLOR_GREEN}Basic parameters configured.${COLOR_RESET}"
    if [[ -n "$SUB_PATH_CONFIGURED" ]]; then
        echo -e "${COLOR_GREEN}Custom/auto-generated  path is: $SUB_PATH_CONFIGURED${COLOR_RESET}"
    fi
    echo -e "${COLOR_GREEN}--------------------------------------------------------${COLOR_RESET}"
    echo -e "${COLOR_YELLOW}Important Note: If the modified $app_js_file_name file appears garbled in a text editor,${COLOR_RESET}"
    echo -e "${COLOR_YELLOW}please ensure your text editor uses UTF-8 encoding to open and view the file.${COLOR_RESET}"

    # --- PM2 Process Management ---
    # This block should only run if app_js_path exists and no critical errors before.
    if [[ -f "$app_js_path" ]]; then # app_js_path is $current_path/$app_js_file_name
        echo -e "\n${COLOR_YELLOW}--- Setting up PM2 Process Manager and Starting Application ---${COLOR_RESET}"
        PM2_APP_NAME="IBM-app" # Name for the PM2 process
        pm2_error_occurred=false # Local error flag for PM2 block

        if ! command -v pm2 &>/dev/null; then
            echo -e "${COLOR_CYAN}PM2 not installed, installing PM2 globally... (This may take some time)${COLOR_RESET}"
            if sudo npm install -g pm2; then
                echo -e "${COLOR_GREEN}PM2 installed successfully.${COLOR_RESET}"
            else
                echo -e "${COLOR_RED}PM2 installation failed. Please check error messages and try installing manually: sudo npm install -g pm2${COLOR_RESET}"
                pm2_error_occurred=true 
            fi
        else
            echo -e "${COLOR_GREEN}PM2 is already installed. Path: $(command -v pm2)${COLOR_RESET}"
        fi

        if ! $pm2_error_occurred; then
            cd "$current_path" || { echo -e "${COLOR_RED}Cannot change to application directory: $current_path${COLOR_RESET}"; pm2_error_occurred=true; }
        fi

        # --- New: Install project dependencies ---
        if ! $pm2_error_occurred; then 
            echo -e "${COLOR_CYAN}Current working directory: $(pwd)${COLOR_RESET}"
            if [[ -f "$package_json_file_name" ]]; then 
                echo -e "${COLOR_CYAN}Found $package_json_file_name, installing project dependencies (npm install)... This may take some time.${COLOR_RESET}"
                if npm install; then
                    echo -e "${COLOR_GREEN}Project dependencies installed successfully.${COLOR_RESET}"
                else
                    echo -e "${COLOR_RED}Project dependencies installation failed (npm install). Please check the error messages above.${COLOR_RESET}"
                    echo -e "${COLOR_RED}The application may not start correctly.${COLOR_RESET}"
                    pm2_error_occurred=true 
                fi
            else
                echo -e "${COLOR_RED}Error: $package_json_file_name not found in $current_path directory.${COLOR_RESET}"
                echo -e "${COLOR_RED}Cannot install project dependencies. The application '${app_js_file_name}' will likely fail to start due to missing modules.${COLOR_RESET}"
                pm2_error_occurred=true 
            fi
        fi
        # --- End: Install project dependencies ---

        if ! $pm2_error_occurred; then
            echo -e "${COLOR_CYAN}Starting/Restarting application ($PM2_APP_NAME) using PM2...${COLOR_RESET}"
            if pm2 describe "$PM2_APP_NAME" &>/dev/null; then
                echo -e "${COLOR_CYAN}Application '$PM2_APP_NAME' is already running in PM2, attempting restart...${COLOR_RESET}"
                if pm2 restart "$PM2_APP_NAME"; then
                    echo -e "${COLOR_GREEN}Application '$PM2_APP_NAME' restarted successfully.${COLOR_RESET}"
                else
                    echo -e "${COLOR_RED}Application '$PM2_APP_NAME' restart failed. Attempting forceful reload...${COLOR_RESET}"
                    if pm2 reload "$PM2_APP_NAME"; then
                         echo -e "${COLOR_GREEN}Application '$PM2_APP_NAME' reloaded successfully.${COLOR_RESET}"
                    else
                        echo -e "${COLOR_RED}Application '$PM2_APP_NAME' reload also failed. Please check PM2 logs: pm2 logs $PM2_APP_NAME${COLOR_RESET}"
                        # pm2_error_occurred=true # Don't mark as fatal error for script if reload fails, user can check logs
                    fi
                fi
            else
                echo -e "${COLOR_CYAN}Application '$PM2_APP_NAME' not running in PM2 or does not exist, attempting to start...${COLOR_RESET}"
                if pm2 start "$app_js_file_name" --name "$PM2_APP_NAME"; then
                    echo -e "${COLOR_GREEN}Application '$app_js_file_name' started successfully via PM2 with name '$PM2_APP_NAME'.${COLOR_RESET}"
                else
                    echo -e "${COLOR_RED}Application '$app_js_file_name' failed to start via PM2. Please check PM2 logs: pm2 logs $PM2_APP_NAME${COLOR_RESET}"
                    # pm2_error_occurred=true # Don't mark as fatal error for script if start fails, user can check logs
                fi
            fi
        fi

        if ! $pm2_error_occurred; then # Only run save/startup if core PM2 ops + npm install were okay
            echo -e "${COLOR_CYAN}Saving PM2 process list...${COLOR_RESET}"
            if pm2 save; then
                echo -e "${COLOR_GREEN}PM2 process list saved.${COLOR_RESET}"
            else
                echo -e "${COLOR_RED}PM2 save command execution failed.${COLOR_RESET}"
            fi

            echo -e "${COLOR_CYAN}Setting up PM2 to start on boot...${COLOR_RESET}"
            echo -e "${COLOR_YELLOW}PM2 will detect your init system and provide the corresponding setup command.${COLOR_RESET}"
            sudo_cmd_for_pm2_startup="sudo" # Assume sudo is needed, PM2 will instruct if not
            echo -e "${COLOR_YELLOW}The PM2 'startup' command will typically output another command that you need to copy and execute manually to complete the setup.${COLOR_RESET}"
            echo -e "${COLOR_MAGENTA}Please carefully read the output from 'pm2 startup' below and execute the command it provides:${COLOR_RESET}"
            echo "------------------------- PM2 STARTUP OUTPUT BEGIN -------------------------"
            if ${sudo_cmd_for_pm2_startup} pm2 startup; then
                echo "-------------------------- PM2 STARTUP OUTPUT END --------------------------"
                echo -e "${COLOR_GREEN}PM2 startup command executed.${COLOR_RESET}"
                echo -e "${COLOR_YELLOW}▲▲▲ ${COLOR_RED}IMPORTANT: ${COLOR_YELLOW}Please copy and execute the command starting with 'sudo' generated by 'pm2 startup' above to complete the boot startup setup! ▲▲▲${COLOR_RESET}"
            else
                echo "-------------------------- PM2 STARTUP OUTPUT END --------------------------"
                echo -e "${COLOR_RED}PM2 startup command execution failed. Please try running '${sudo_cmd_for_pm2_startup} pm2 startup' manually and follow the prompts.${COLOR_RESET}"
            fi
        fi
    else
        # This case means app_js_path was not found, which should have been caught by error_occurred earlier.
        echo -e "${COLOR_YELLOW}$app_js_file_name file not found, skipping PM2 application startup steps.${COLOR_RESET}"
    fi

elif $error_occurred; then # Handles errors from download or basic config
    echo -e "\n${COLOR_RED}Configuration was not fully completed or PM2 setup was not finished due to errors.${COLOR_RESET}"
else # basic_config_performed is false, and no error_occurred means it was skipped (e.g. user aborted firewall config).
    echo -e "\n${COLOR_YELLOW}No effective configuration was performed or configuration was not successful.${COLOR_RESET}"
fi

# Re-display basic config info if it was performed, regardless of later PM2 issues
if $basic_config_performed; then
    echo -e "\n${COLOR_GREEN}==================== Basic Configuration Summary ====================${COLOR_RESET}"
    echo -e "Domain: ${COLOR_CYAN}$DOMAIN_CONFIGURED${COLOR_RESET}"
    echo -e "UUID: ${COLOR_CYAN}$UUID_CONFIGURED${COLOR_RESET}"
    echo -e "app.js Listening Port: ${COLOR_CYAN}$PORT_CONFIGURED${COLOR_RESET}"
    echo -e " Path: ${COLOR_CYAN}$SUB_PATH_CONFIGURED${COLOR_RESET}"
    sub_link_protocol="https"
    sub_link="${sub_link_protocol}://$DOMAIN_CONFIGURED$SUB_PATH_CONFIGURED"
    echo -e " Link: ${COLOR_CYAN}$sub_link${COLOR_RESET}"
    echo -e "${COLOR_GREEN}--------------------------------------------------------${COLOR_RESET}"
fi

echo -e "\n${COLOR_GREEN}==================== Script Operations Ended ====================${COLOR_RESET}"
echo -e "${COLOR_MAGENTA}--------------------------------------------------------------------------${COLOR_RESET}"
echo -e "${COLOR_MAGENTA}Script execution finished. Thank you for using!${COLOR_RESET}"
rm -- "$0"
