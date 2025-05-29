#!/bin/bash

# Author: Joey
# Blog: joeyblog.net
# Feedback TG (Feedback TG): https://t.me/+ft-zI76oovgwNmRh
# Core Functionality By (Core Functionality By):
#   - https://github.com/eooce
#   - https://github.com/qwer-search
# Version: 2.4.8.sh (macOS - sed delimiter, panel URL opening with https default) - Modified by User Request
# English Translation & Firewall Modification (Ports 22, 80 only) - by AI Assistant for User
# Further refined configure_firewall for debugging iptables - v2
# Node information output moved to the very end - User Request

display_welcome_message() {
    clear
    echo -e "${COLOR_CYAN}===================================================================${COLOR_RESET}"
    echo -e "${COLOR_MAGENTA}      Welcome to the IBM-ws-nodejs Application Management Script (${SCRIPT_VERSION})${COLOR_RESET}"
    echo -e "${COLOR_CYAN}===================================================================${COLOR_RESET}"
    echo ""
    echo -e "${COLOR_GREEN}This script will help you install, configure, and manage the IBM-ws-nodejs application.${COLOR_RESET}"
    echo -e "${COLOR_GREEN}The application will be managed by PM2 to ensure stable operation and easy management.${COLOR_RESET}"
    echo ""
    echo -e "${COLOR_YELLOW}Author (Script Author): Joey (joeyblog.net)${COLOR_RESET}"
    echo -e "${COLOR_YELLOW}Core Functionality By: eooce, qwer-search${COLOR_RESET}"
    echo -e "${COLOR_YELLOW}Feedback TG (Feedback TG): https://t.me/+ft-zI76oovgwNmRh${COLOR_RESET}"
}

# --- Color Definitions ---
COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[0;33m'
COLOR_MAGENTA='\033[0;35m'
COLOR_CYAN='\033[0;36m'
COLOR_RESET='\033[0m' # No Color

# Initialize SCRIPT_VERSION (example, can be dynamic if needed)
SCRIPT_VERSION="2.4.8-EN-FWMod2-NodeInfoEnd"

display_welcome_message # Call the welcome message function

echo ""
echo -e "${COLOR_MAGENTA}Welcome to the IBM-ws-nodejs Configuration Script!${COLOR_RESET}"
echo -e "${COLOR_MAGENTA}This script is provided by Joey (joeyblog.net) to simplify the configuration process.${COLOR_RESET}"
echo -e "${COLOR_MAGENTA}Core functionality is based on the work of eooce and qwer-search.${COLOR_RESET}"
echo -e "${COLOR_MAGENTA}If you have any feedback on this script, please contact via Telegram: https://t.me/+ft-zI76oovgwNmRh${COLOR_RESET}"
echo -e "${COLOR_MAGENTA}--------------------------------------------------------------------------${COLOR_RESET}"

# --- Environment Preparation and Detection ---

# Function: Detect and install Node.js
check_and_install_nodejs() {
    echo -e "\n${COLOR_YELLOW}--- Checking Node.js environment ---${COLOR_RESET}"
    if command -v node &>/dev/null && command -v npm &>/dev/null; then
        echo -e "${COLOR_GREEN}Node.js is already installed. Node version: $(node -v), NPM version: $(npm -v)${COLOR_RESET}"
        return 0
    fi

    echo -e "${COLOR_YELLOW}Node.js or npm not detected, attempting to install automatically...${COLOR_RESET}"

    if ! command -v curl &>/dev/null; then
        echo -e "${COLOR_YELLOW}curl is not installed. Attempting to install curl...${COLOR_RESET}"
        if command -v apt-get &>/dev/null; then
            sudo apt-get update -y && sudo apt-get install -y curl
        elif command -v yum &>/dev/null; then
            sudo yum install -y curl
        elif command -v dnf &>/dev/null; then
            sudo dnf install -y curl
        else
            echo -e "${COLOR_RED}Could not automatically install curl. Please install curl manually and rerun the script.${COLOR_RESET}"
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
        echo -e "${COLOR_YELLOW}Node.js installation script completed but returned a non-zero exit status ($install_status). Will continue to check if Node.js and npm are available.${COLOR_RESET}"
    fi

    if command -v node &>/dev/null && command -v npm &>/dev/null; then
        echo -e "${COLOR_GREEN}Node.js installed/updated successfully (or was already present).${COLOR_RESET}"
        echo -e "${COLOR_GREEN}Node version: $(node -v), NPM version: $(npm -v)${COLOR_RESET}"
    else
        echo -e "${COLOR_RED}Node.js or npm still not found after running the installation script.${COLOR_RESET}"
        echo -e "${COLOR_RED}Please check the output of the installation process above, or try installing Node.js and npm manually.${COLOR_RESET}"
        return 1
    fi
    return 0
}

# Function: Configure firewall to allow only ports 22 (SSH) and 80 (HTTP)
configure_firewall() {
    echo -e "\n${COLOR_YELLOW}--- Firewall Configuration: Allowing Ports 22 (SSH) and 80 (HTTP) ---${COLOR_RESET}"
    echo -e "${COLOR_CYAN}This script will attempt to configure your firewall (UFW, firewalld, or iptables) to allow incoming traffic on TCP ports 22 and 80.${COLOR_RESET}"
    echo -e "${COLOR_CYAN}All other incoming ports will be blocked by default, while outgoing traffic will generally be allowed.${COLOR_RESET}"

    local confirmation=""
    while [[ "$confirmation" != "yes" && "$confirmation" != "no" ]]; do
        read -p "Do you want to proceed with this firewall configuration? (Enter 'yes' or 'no'): " confirmation
        confirmation=$(echo "$confirmation" | tr '[:upper:]' '[:lower:]') # Convert to lowercase
    done

    if [[ "$confirmation" != "yes" ]]; then
        echo -e "${COLOR_YELLOW}Operation cancelled. Firewall configuration has not been changed.${COLOR_RESET}"
        return 1 # User cancelled
    fi

    echo -e "\n${COLOR_YELLOW}--- Attempting to configure firewall for ports 22 and 80 ---${COLOR_RESET}"
    local firewall_action_taken=false
    local processed_firewall_tool_name="" # To store which tool was used: ufw, firewalld, iptables

    # Try UFW first
    if command -v ufw &>/dev/null; then
        echo -e "${COLOR_CYAN}UFW detected. Attempting configuration...${COLOR_RESET}"
        echo -e "${COLOR_CYAN}Setting UFW default policies: deny incoming, allow outgoing.${COLOR_RESET}"
        sudo ufw default deny incoming
        sudo ufw default allow outgoing
        echo -e "${COLOR_CYAN}Allowing TCP port 22 (SSH)...${COLOR_RESET}"
        sudo ufw allow 22/tcp comment 'SSH access'
        echo -e "${COLOR_CYAN}Allowing TCP port 80 (HTTP)...${COLOR_RESET}"
        sudo ufw allow 80/tcp comment 'HTTP access'

        local ufw_enabled_successfully=false
        if sudo ufw status | grep -qw active; then
            echo -e "${COLOR_YELLOW}UFW is active, reloading rules...${COLOR_RESET}"
            if sudo ufw reload; then
                echo -e "${COLOR_GREEN}UFW rules reloaded successfully.${COLOR_RESET}"
                ufw_enabled_successfully=true
            else
                echo -e "${COLOR_RED}Failed to reload UFW rules. Please check UFW status and logs manually.${COLOR_RESET}"
            fi
        else
            echo -e "${COLOR_YELLOW}UFW is not active, enabling it now with the new rules...${COLOR_RESET}"
            if yes | sudo ufw enable; then
                echo -e "${COLOR_GREEN}UFW enabled successfully.${COLOR_RESET}"
                ufw_enabled_successfully=true
            else
                echo -e "${COLOR_RED}Failed to enable UFW. Please check UFW status and logs manually.${COLOR_RESET}"
            fi
        fi

        if $ufw_enabled_successfully; then
            firewall_action_taken=true
            processed_firewall_tool_name="ufw"
            echo -e "${COLOR_GREEN}UFW is now active and configured for ports 22 and 80.${COLOR_RESET}"
        else
            echo -e "${COLOR_YELLOW}UFW configuration attempted, but UFW might not be active or fully set up.${COLOR_RESET}"
        fi
    fi

    # Try firewalld if UFW was not successfully processed
    if [ -z "$processed_firewall_tool_name" ] && command -v firewall-cmd &>/dev/null; then
        echo -e "${COLOR_CYAN}firewalld detected. Attempting configuration...${COLOR_RESET}"
        local firewalld_configured_successfully=false
        if ! systemctl is-active --quiet firewalld; then
            echo -e "${COLOR_YELLOW}firewalld is not active. Attempting to start and enable...${COLOR_RESET}"
            if sudo systemctl start firewalld && sudo systemctl enable firewalld; then
                echo -e "${COLOR_GREEN}firewalld started and enabled successfully.${COLOR_RESET}"
            else
                echo -e "${COLOR_RED}Failed to start or enable firewalld. Please check system logs.${COLOR_RESET}"
            fi
        fi

        if systemctl is-active --quiet firewalld; then
            echo -e "${COLOR_CYAN}Configuring firewalld to allow SSH (port 22) and HTTP (port 80)...${COLOR_RESET}"
            sudo firewall-cmd --permanent --add-service=ssh >/dev/null 2>&1 || echo -e "${COLOR_YELLOW}Warning: Failed to add ssh service to firewalld or already added.${COLOR_RESET}"
            sudo firewall-cmd --permanent --add-port=80/tcp >/dev/null 2>&1 || echo -e "${COLOR_YELLOW}Warning: Failed to add port 80/tcp to firewalld or already added.${COLOR_RESET}"
            echo -e "${COLOR_CYAN}Reloading firewalld rules...${COLOR_RESET}"
            if sudo firewall-cmd --reload; then
                echo -e "${COLOR_GREEN}firewalld rules reloaded. SSH and HTTP (port 80) access is now configured.${COLOR_RESET}"
                firewalld_configured_successfully=true
            else
                echo -e "${COLOR_RED}Failed to reload firewalld. Please check 'journalctl -xe' or 'systemctl status firewalld'.${COLOR_RESET}"
            fi
        else
            echo -e "${COLOR_YELLOW}firewalld is not active. Skipping firewalld rule configuration.${COLOR_RESET}"
        fi

        if $firewalld_configured_successfully; then
            firewall_action_taken=true
            processed_firewall_tool_name="firewalld"
        fi
    fi

    # Try iptables if no other tool was successfully processed, or if explicitly desired.
    if [ -z "$processed_firewall_tool_name" ] && command -v iptables &>/dev/null; then
        echo -e "${COLOR_CYAN}iptables detected. No other primary firewall tool (UFW/firewalld) was fully configured by this script.${COLOR_RESET}"
        echo -e "${COLOR_YELLOW}Configuring iptables rules for ports 22 (SSH) and 80 (HTTP) step-by-step...${COLOR_RESET}"
        echo -e "${COLOR_YELLOW}If script hangs, note the last successful 'Done.' message to identify the problematic command.${COLOR_RESET}"

        local iptables_step_ok=true

        echo -n "Step 1: Flushing INPUT chain... "
        sudo iptables -F INPUT || iptables_step_ok=false
        if $iptables_step_ok; then echo -e "${COLOR_GREEN}Done.${COLOR_RESET}"; else echo -e "${COLOR_RED}Failed!${COLOR_RESET}"; fi

        if $iptables_step_ok; then
            echo -n "Step 2: Flushing FORWARD chain... "
            sudo iptables -F FORWARD || iptables_step_ok=false
            if $iptables_step_ok; then echo -e "${COLOR_GREEN}Done.${COLOR_RESET}"; else echo -e "${COLOR_RED}Failed!${COLOR_RESET}"; fi
        fi

        if $iptables_step_ok; then
            echo -n "Step 3: Flushing OUTPUT chain... "
            sudo iptables -F OUTPUT || iptables_step_ok=false
            if $iptables_step_ok; then echo -e "${COLOR_GREEN}Done.${COLOR_RESET}"; else echo -e "${COLOR_RED}Failed!${COLOR_RESET}"; fi
        fi

        if $iptables_step_ok; then
            echo -n "Step 4: Flushing all non-default chains (general -F)... "
            sudo iptables -F || iptables_step_ok=false
            if $iptables_step_ok; then echo -e "${COLOR_GREEN}Done.${COLOR_RESET}"; else echo -e "${COLOR_RED}Failed!${COLOR_RESET}"; fi
        fi

        if $iptables_step_ok; then
            echo -n "Step 5: Deleting all non-default chains (-X)... "
            sudo iptables -X || iptables_step_ok=false # This can fail if chains are still in use (shouldn't be after -F)
            if $iptables_step_ok; then echo -e "${COLOR_GREEN}Done.${COLOR_RESET}"; else echo -e "${COLOR_RED}Failed (possibly no custom chains to delete or a chain is in use).${COLOR_RESET}"; iptables_step_ok=true; fi # Non-critical if it fails harmlessly
        fi

        # Set default policies
        if $iptables_step_ok; then
            echo -n "Step 6: Setting INPUT policy to DROP... "
            sudo iptables -P INPUT DROP || iptables_step_ok=false
            if $iptables_step_ok; then echo -e "${COLOR_GREEN}Done.${COLOR_RESET}"; else echo -e "${COLOR_RED}Failed!${COLOR_RESET}"; fi
        fi

        if $iptables_step_ok; then
            echo -n "Step 7: Setting FORWARD policy to DROP... "
            sudo iptables -P FORWARD DROP || iptables_step_ok=false
            if $iptables_step_ok; then echo -e "${COLOR_GREEN}Done.${COLOR_RESET}"; else echo -e "${COLOR_RED}Failed!${COLOR_RESET}"; fi
        fi

        if $iptables_step_ok; then
            echo -n "Step 8: Setting OUTPUT policy to ACCEPT... "
            sudo iptables -P OUTPUT ACCEPT || iptables_step_ok=false
            if $iptables_step_ok; then echo -e "${COLOR_GREEN}Done.${COLOR_RESET}"; else echo -e "${COLOR_RED}Failed!${COLOR_RESET}"; fi
        fi

        # Allow loopback traffic
        if $iptables_step_ok; then
            echo -n "Step 9: Allowing loopback INPUT... "
            sudo iptables -A INPUT -i lo -j ACCEPT || iptables_step_ok=false
            if $iptables_step_ok; then echo -e "${COLOR_GREEN}Done.${COLOR_RESET}"; else echo -e "${COLOR_RED}Failed!${COLOR_RESET}"; fi
        fi

        # Allow established and related connections
        if $iptables_step_ok; then
            echo -n "Step 10: Allowing RELATED,ESTABLISHED INPUT... "
            sudo iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT || iptables_step_ok=false
            if $iptables_step_ok; then echo -e "${COLOR_GREEN}Done.${COLOR_RESET}"; else echo -e "${COLOR_RED}Failed!${COLOR_RESET}"; fi
        fi

        # Allow SSH on port 22
        if $iptables_step_ok; then
            echo -n "Step 11: Allowing TCP port 22 (SSH) INPUT... "
            sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT || iptables_step_ok=false
            if $iptables_step_ok; then echo -e "${COLOR_GREEN}Done.${COLOR_RESET}"; else echo -e "${COLOR_RED}Failed!${COLOR_RESET}"; fi
        fi

        # Allow HTTP on port 80
        if $iptables_step_ok; then
            echo -n "Step 12: Allowing TCP port 80 (HTTP) INPUT... "
            sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT || iptables_step_ok=false
            if $iptables_step_ok; then echo -e "${COLOR_GREEN}Done.${COLOR_RESET}"; else echo -e "${COLOR_RED}Failed!${COLOR_RESET}"; fi
        fi

        if $iptables_step_ok; then
            echo -e "${COLOR_GREEN}iptables: Default policies set and rules added for ports 22 & 80.${COLOR_RESET}"
            echo -e "${COLOR_YELLOW}Note: These iptables changes might be lost on reboot unless you use 'iptables-persistent' (Debian/Ubuntu) or 'iptables-services' (CentOS/RHEL) to save them.${COLOR_RESET}"
            echo -e "${COLOR_YELLOW}For Debian/Ubuntu: 'sudo apt install iptables-persistent' then 'sudo netfilter-persistent save'.${COLOR_RESET}"
            echo -e "${COLOR_YELLOW}For CentOS/RHEL: 'sudo yum install iptables-services', 'sudo systemctl enable iptables', 'sudo systemctl start iptables', then 'sudo iptables-save > /etc/sysconfig/iptables'.${COLOR_RESET}"
            firewall_action_taken=true
            processed_firewall_tool_name="iptables"
        else
            echo -e "${COLOR_RED}One or more iptables commands failed. Firewall may not be configured correctly.${COLOR_RESET}"
        fi
    elif command -v iptables &>/dev/null && [ -n "$processed_firewall_tool_name" ]; then
        echo -e "${COLOR_CYAN}iptables detected, but ${processed_firewall_tool_name} was already configured. Skipping direct iptables commands.${COLOR_RESET}"
        echo -e "${COLOR_CYAN}${processed_firewall_tool_name} usually manages iptables rules. Manual iptables changes might conflict or be overwritten.${COLOR_RESET}"
    fi

    # Final status messages
    if [ -n "$processed_firewall_tool_name" ] && $firewall_action_taken; then
        echo -e "${COLOR_GREEN}Firewall configuration using ${processed_firewall_tool_name} for ports 22 and 80 appears to be completed.${COLOR_RESET}"
    elif ! command -v ufw &>/dev/null && ! command -v firewall-cmd &>/dev/null && ! command -v iptables &>/dev/null ; then
        echo -e "${COLOR_YELLOW}No common firewall management tools (UFW, firewalld, iptables) were detected.${COLOR_RESET}"
        echo -e "${COLOR_YELLOW}Please ensure your system firewall (if any) is configured to allow incoming traffic on TCP ports 22 and 80.${COLOR_RESET}"
    else
        echo -e "${COLOR_YELLOW}Firewall configuration may not be complete. Please review messages above and check your firewall settings manually.${COLOR_RESET}"
    fi

    echo -e "${COLOR_GREEN}Firewall setup attempt finished. Please verify connectivity and security.${COLOR_RESET}"
    return 0
}


# Execute environment preparation
check_and_install_nodejs || exit 1 # Exit if Node.js setup fails
configure_firewall || echo -e "${COLOR_YELLOW}Firewall configuration was skipped by user or encountered an issue, proceeding with caution.${COLOR_RESET}"
echo -e "${COLOR_MAGENTA}--------------------------------------------------------------------------${COLOR_RESET}"


echo -e "${COLOR_GREEN}==================== IBM-ws-nodejs Configuration Generation Script ====================${COLOR_RESET}"

# --- Global Variables ---
current_path=$(pwd)
app_js_file_name="app.js"
package_json_file_name="package.json"
app_js_path="$current_path/$app_js_file_name"
package_json_path="$current_path/$package_json_file_name"
sed_error_log="/tmp/sed_error.log" # Temporary file for sed errors

app_js_url="https://raw.githubusercontent.com/byJoey/Webhostmost-ws-nodejs/refs/heads/main/app.js"
package_json_url="https://raw.githubusercontent.com/qwer-search/Webhostmost-ws-nodejs/main/package.json"

# Variables to store configuration details for final output
DOMAIN_CONFIGURED=""
UUID_CONFIGURED=""
PORT_CONFIGURED="" # Internal app.js port
SUB_PATH_CONFIGURED=""
SUB_LINK=""


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

# Modify configuration items in app.js function
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

    # Escape for sed: & first, then #, then /, then \
    local escaped_conf_value=$(echo "$conf_value" | sed -e 's/[\&]/\\&/g' -e 's/[\#]/\\#/g' -e 's/\//\\\//g' -e 's/\\/\\\\/g')
    local final_sed_script=$(echo "$sed_script_template" | sed "s#{VALUE_PLACEHOLDER}#$escaped_conf_value#g")


    original_content=$(cat "$filepath")
    # Use printf to avoid issues with echo and backslashes if original_content contains them
    new_content=$(printf '%s' "$original_content" | sed -E "$final_sed_script" 2>"$sed_error_log")
    sed_exit_status=$?

    if [ $sed_exit_status -ne 0 ]; then
        echo -e "${COLOR_RED}Error: sed command failed while modifying '$conf_name', exit status: $sed_exit_status.${COLOR_RESET}"
        if [[ -s "$sed_error_log" ]]; then
            echo -e "${COLOR_RED}Sed error messages: $(cat "$sed_error_log")${COLOR_RESET}"
        fi
        rm -f "$sed_error_log"
        return 1
    fi
    rm -f "$sed_error_log"

    if [[ "$original_content" == "$new_content" ]]; then
        echo -e "${COLOR_YELLOW}Warning: Configuration item '$conf_name' did not find a matching pattern in $app_js_file_name or the value was unchanged.${COLOR_RESET}"
        echo -e "${COLOR_YELLOW}Sed command template used: $sed_script_template${COLOR_RESET}"
        echo -e "${COLOR_YELLOW}Actual sed script executed: $final_sed_script${COLOR_RESET}"
    else
        printf '%s' "$new_content" > "$filepath"
        echo -e "${COLOR_GREEN}'$conf_name' in $app_js_file_name has been updated to '$conf_value'.${COLOR_RESET}"
    fi
    return 0
}

# Basic configuration function
invoke_basic_configuration() {
    echo -e "\n${COLOR_YELLOW}--- Configuring Basic Deployment Parameters (UUID, Domain, Port, Subscription Path) ---${COLOR_RESET}"

    local domain_val=""
    while true; do
        read -p "Please enter your domain (e.g., yourdomain.com): " domain_val
        if [[ -n "$domain_val" ]]; then
            break
        else
            echo -e "${COLOR_YELLOW}Domain cannot be empty, please re-enter.${COLOR_RESET}"
        fi
    done
    DOMAIN_CONFIGURED="$domain_val" # Store globally

    local uuid_val=""
    read -p "Please enter UUID (leave blank to auto-generate): " uuid_val
    if [[ -z "$uuid_val" ]]; then
        if command -v uuidgen &>/dev/null; then
            uuid_val=$(uuidgen)
        elif command -v C:\Windows\System32\uuidgen.exe &>/dev/null; then # For Windows Git Bash or similar
            uuid_val=$(C:\Windows\System32\uuidgen.exe)
        elif command -v pwgen &>/dev/null; then
            uuid_val=$(pwgen -s 36 1) # Generate a 36-char string
        else # Fallback for minimal systems
            uuid_val=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 36)
        fi
        echo -e "${COLOR_CYAN}Auto-generated UUID: $uuid_val${COLOR_RESET}"
    fi
    UUID_CONFIGURED="$uuid_val" # Store globally

    local vl_port_val="80" # Defaulting to port 80 as per common practice for this app
    echo -e "${COLOR_CYAN}The HTTP server listening port for app.js is fixed to: $vl_port_val (This is the internal app port, not necessarily the public-facing port if behind a reverse proxy).${COLOR_RESET}"
    PORT_CONFIGURED="$vl_port_val" # Store globally

    local subscription_path_input=""
    read -p "Please enter a custom subscription path (e.g., sub, mypath. Leave blank to auto-generate. Do not start with /): " subscription_path_input
    local subscription_path_val=""
    if [[ -z "$subscription_path_input" ]]; then
        local random_path_name=$(LC_ALL=C tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 8)
        subscription_path_val="/$random_path_name"
        echo -e "${COLOR_CYAN}Auto-generated subscription path: $subscription_path_val${COLOR_RESET}"
    else
        # Remove leading/trailing slashes and then add a single leading slash
        local cleaned_path=$(echo "$subscription_path_input" | sed -E 's#^/+##; s#/*$##')
        if [[ -z "$cleaned_path" ]]; then # If input was just slashes or empty after cleaning
            local random_path_name=$(LC_ALL=C tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 8)
            subscription_path_val="/$random_path_name"
            echo -e "${COLOR_CYAN}Invalid path entered, auto-generated subscription path: $subscription_path_val${COLOR_RESET}"
        else
            subscription_path_val="/$cleaned_path"
        fi
    fi
    echo -e "${COLOR_CYAN}The final subscription path will be: $subscription_path_val${COLOR_RESET}"
    SUB_PATH_CONFIGURED="$subscription_path_val" # Store globally

    echo "Modifying basic parameters in $app_js_file_name..."
    update_app_js_config "$app_js_path" "UUID" "$uuid_val" \
        "s#(const UUID = process\.env\.UUID \|\| ')([^']*)(';)#\1{VALUE_PLACEHOLDER}\3#g" || return 1
    update_app_js_config "$app_js_path" "DOMAIN" "$domain_val" \
        "s#(const DOMAIN = process\.env\.DOMAIN \|\| ')([^']*)(';)#\1{VALUE_PLACEHOLDER}\3#g" || return 1
    update_app_js_config "$app_js_path" "PORT" "$vl_port_val" \
        "s#(const port = process\.env\.PORT \|\| )([0-9]*)(;)#\1{VALUE_PLACEHOLDER}\3#g" || return 1
    update_app_js_config "$app_js_path" "Subscription URL Path" "$subscription_path_val" \
        "s#(else[[:blank:]]+if[[:blank:]]*\([[:blank:]]*req\.url[[:blank:]]*===[[:blank:]]*')(\/[^']+)(')#\1{VALUE_PLACEHOLDER}\3#g" || return 1

    # Prepare the subscription link
    local sub_link_protocol="https" # Default to https for panel link
    SUB_LINK="${sub_link_protocol}://$DOMAIN_CONFIGURED$SUB_PATH_CONFIGURED"

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
        echo -e "${COLOR_RED}Error: $package_json_file_name download failed. This is required for installing dependencies.${COLOR_RESET}"
        error_occurred=true # package.json is critical for this app
    fi
fi


if ! $error_occurred; then
    if invoke_basic_configuration; then
        basic_config_performed=true
        echo -e "\n${COLOR_GREEN}Basic configuration parameters have been set and $app_js_file_name updated.${COLOR_RESET}"
        # Node information will be displayed at the very end of the script
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
    echo -e "Configuration files have been saved to the current directory: ${COLOR_CYAN}$current_path${COLOR_RESET}"


    echo -e "  - $app_js_file_name"
    echo -e "  - $package_json_file_name"
    echo -e "${COLOR_GREEN}--------------------------------------------------------${COLOR_RESET}"
    echo -e "${COLOR_GREEN}Basic parameters have been configured.${COLOR_RESET}"
    if [[ -n "$SUB_PATH_CONFIGURED" ]]; then # SUB_PATH_CONFIGURED is now a global variable
        echo -e "${COLOR_GREEN}Custom/auto-generated subscription path is: $SUB_PATH_CONFIGURED${COLOR_RESET}"
    fi
    echo -e "${COLOR_GREEN}--------------------------------------------------------${COLOR_RESET}"
    echo -e "${COLOR_YELLOW}Important: If the modified $app_js_file_name file appears garbled in a text editor,${COLOR_RESET}"
    echo -e "${COLOR_YELLOW}please ensure your text editor uses UTF-8 encoding to open and view the file.${COLOR_RESET}"

    # --- PM2 Process Management ---
    # This block should only run if app_js_path exists and no critical errors before.
    if [[ -f "$app_js_path" ]]; then # app_js_path is $current_path/$app_js_file_name
        echo -e "\n${COLOR_YELLOW}--- Setting up PM2 process manager and starting the application ---${COLOR_RESET}"
        PM2_APP_NAME="IBM-app" # Define a consistent PM2 application name
        pm2_error_occurred=false # Local error flag for PM2 block

        if ! command -v pm2 &>/dev/null; then
            echo -e "${COLOR_CYAN}PM2 is not installed, installing PM2 globally... (This may take some time)${COLOR_RESET}"
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
            # Change to the application directory before npm install and pm2 start
            cd "$current_path" || { echo -e "${COLOR_RED}Cannot change to application directory: $current_path${COLOR_RESET}"; pm2_error_occurred=true; }
        fi

        # --- NEW: Install project dependencies ---
        if ! $pm2_error_occurred; then
            echo -e "${COLOR_CYAN}Current working directory: $(pwd)${COLOR_RESET}"
            if [[ -f "$package_json_file_name" ]]; then
                echo -e "${COLOR_CYAN}Found $package_json_file_name, installing project dependencies (npm install)... This may take some time.${COLOR_RESET}"
                if npm install; then
                    echo -e "${COLOR_GREEN}Project dependencies installed successfully.${COLOR_RESET}"
                else
                    echo -e "${COLOR_RED}Project dependency installation failed (npm install). Please check the error messages above.${COLOR_RESET}"
                    echo -e "${COLOR_RED}The application might not start correctly.${COLOR_RESET}"
                    pm2_error_occurred=true
                fi
            else
                echo -e "${COLOR_RED}Error: $package_json_file_name not found in directory $current_path.${COLOR_RESET}"
                echo -e "${COLOR_RED}Cannot install project dependencies. Application '${app_js_file_name}' will likely fail to start due to missing modules.${COLOR_RESET}"
                pm2_error_occurred=true
            fi
        fi
        # --- END: Install project dependencies ---

        if ! $pm2_error_occurred; then
            echo -e "${COLOR_CYAN}Starting/Restarting application ($PM2_APP_NAME) using PM2...${COLOR_RESET}"
            # Check if the app is already managed by PM2
            if pm2 describe "$PM2_APP_NAME" &>/dev/null; then
                echo -e "${COLOR_CYAN}Application '$PM2_APP_NAME' is already running in PM2, attempting restart...${COLOR_RESET}"
                if pm2 restart "$PM2_APP_NAME"; then
                    echo -e "${COLOR_GREEN}Application '$PM2_APP_NAME' restarted successfully.${COLOR_RESET}"
                else
                    echo -e "${COLOR_RED}Application '$PM2_APP_NAME' restart failed. Attempting force reload...${COLOR_RESET}"
                    if pm2 reload "$PM2_APP_NAME"; then # reload is a graceful restart
                         echo -e "${COLOR_GREEN}Application '$PM2_APP_NAME' reloaded successfully.${COLOR_RESET}"
                    else
                        echo -e "${COLOR_RED}Application '$PM2_APP_NAME' reload also failed. Please check PM2 logs: pm2 logs $PM2_APP_NAME${COLOR_RESET}"
                        # pm2_error_occurred=true # Don't mark as fatal error for script if reload fails, user can check logs
                    fi
                fi
            else
                echo -e "${COLOR_CYAN}Application '$PM2_APP_NAME' is not running or does not exist in PM2, attempting to start...${COLOR_RESET}"
                # Start the application using the app.js file name, but name it PM2_APP_NAME
                if pm2 start "$app_js_file_name" --name "$PM2_APP_NAME"; then
                    echo -e "${COLOR_GREEN}Application '$app_js_file_name' started successfully via PM2 as '$PM2_APP_NAME'.${COLOR_RESET}"
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
                echo -e "${COLOR_RED}PM2 save command failed.${COLOR_RESET}"
            fi

            echo -e "${COLOR_CYAN}Setting up PM2 to start on system boot...${COLOR_RESET}"
            echo -e "${COLOR_YELLOW}PM2 will detect your init system and provide the corresponding setup command.${COLOR_RESET}"
            sudo_cmd_for_pm2_startup="sudo" # Most init systems require sudo for pm2 startup
            # On some systems, pm2 startup might suggest a command that doesn't need sudo if user has permissions,
            # but it's safer to assume sudo is needed for the command pm2 generates.
            echo -e "${COLOR_YELLOW}The PM2 'startup' command usually outputs another command that you need to copy and execute manually to complete the setup.${COLOR_RESET}"
            echo -e "${COLOR_MAGENTA}Please carefully read the output from 'pm2 startup' below and execute the command it prompts:${COLOR_RESET}"
            echo "------------------------- PM2 STARTUP OUTPUT BEGIN -------------------------"
            if ${sudo_cmd_for_pm2_startup} pm2 startup; then
                echo "-------------------------- PM2 STARTUP OUTPUT END --------------------------"
                echo -e "${COLOR_GREEN}PM2 startup command executed.${COLOR_RESET}"
                echo -e "${COLOR_YELLOW}▲▲▲ ${COLOR_RED}IMPORTANT: ${COLOR_YELLOW}Please copy and execute the command starting with 'sudo' (usually) generated by 'pm2 startup' above to complete the auto-start setup! ▲▲▲${COLOR_RESET}"
            else
                echo "-------------------------- PM2 STARTUP OUTPUT END --------------------------"
                echo -e "${COLOR_RED}PM2 startup command failed. Please try running '${sudo_cmd_for_pm2_startup} pm2 startup' manually and follow the prompts.${COLOR_RESET}"
            fi
        fi
    else
        # This case means app_js_path was not found, which should have been caught by error_occurred earlier.
        echo -e "${COLOR_YELLOW}$app_js_file_name file not found, skipping PM2 application startup steps.${COLOR_RESET}"
    fi

elif $error_occurred; then # Handles errors from download or basic config
    echo -e "\n${COLOR_RED}Due to errors, configuration was not fully completed or PM2 setup was not finished.${COLOR_RESET}"
else # basic_config_performed is false, and no error_occurred means it was skipped (e.g. user cancelled an early step)
    echo -e "\n${COLOR_YELLOW}No valid configuration was performed, or configuration was not successful.${COLOR_RESET}"
fi

echo -e "\n${COLOR_GREEN}==================== Script operations finished ====================${COLOR_RESET}"
echo -e "${COLOR_MAGENTA}--------------------------------------------------------------------------${COLOR_RESET}"
echo -e "${COLOR_MAGENTA}Script execution complete. Thank you for using!${COLOR_RESET}"


# --- Final Node Information Output ---
if $basic_config_performed && ! $error_occurred; then
    echo -e "\n${COLOR_GREEN}==================== Final Node Information ====================${COLOR_RESET}"
    echo -e "Domain: ${COLOR_CYAN}$DOMAIN_CONFIGURED${COLOR_RESET}"
    echo -e "UUID: ${COLOR_CYAN}$UUID_CONFIGURED${COLOR_RESET}"
    echo -e "app.js Listening Port (Internal): ${COLOR_CYAN}$PORT_CONFIGURED${COLOR_RESET}"
    echo -e "Public Facing Port (Firewall): ${COLOR_CYAN}80 (HTTP)${COLOR_RESET}"
    echo -e "Subscription Path: ${COLOR_CYAN}$SUB_PATH_CONFIGURED${COLOR_RESET}"
    echo -e "Node Sharing Link (VLESS Subscription Link): ${COLOR_CYAN}$SUB_LINK${COLOR_RESET}"
    echo -e "${COLOR_GREEN}--------------------------------------------------------${COLOR_RESET}"
fi
