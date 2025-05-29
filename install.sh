# Function: Configure firewall to allow only essential ports (80 for HTTP, 22 for SSH)
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
        if sudo ufw reset; then # Disables firewall and resets rules
            sudo ufw default deny incoming
            sudo ufw default allow outgoing
            echo -e "${COLOR_GREEN}UFW default policies set (deny incoming, allow outgoing).${COLOR_RESET}"
            sudo ufw allow 22/tcp comment 'Allow SSH'
            echo -e "${COLOR_GREEN}UFW: Allowed TCP port 22 (SSH).${COLOR_RESET}"
            sudo ufw allow 80/tcp comment 'Allow HTTP'
            echo -e "${COLOR_GREEN}UFW: Allowed TCP port 80 (HTTP).${COLOR_RESET}"
            if echo "y" | sudo ufw enable; then # Enable UFW non-interactively
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
                # Do not set firewall_action_taken to true if firewalld could not be started/enabled
                # but continue to attempt rule addition if it was already active before this block
            fi
        else
             echo -e "${COLOR_GREEN}firewalld is active.${COLOR_RESET}"
        fi
        
        # Proceed if firewalld is now active
        if systemctl is-active --quiet firewalld; then
            echo -e "${COLOR_YELLOW}Adding rules for ports 22/tcp (SSH) and 80/tcp (HTTP) to firewalld...${COLOR_RESET}"
            # Using public zone by default. Make sure it's reasonably configured.
            # For a truly clean setup, one might create a new zone or clear existing services/ports.
            # This approach just adds the necessary ports.
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
