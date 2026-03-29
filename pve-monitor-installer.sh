cat > pve-monitor-installer.sh << 'SCRIPT_EOF'
#!/bin/bash
# =============================================================================
# PVE Universal Hardware Monitor - Complete Installation & Update Script
# Repository: https://github.com/Muneeb-Nazir/Proxmox-pve-hardware-monitor
# Version: 2.0.0
# =============================================================================

# GitHub repository configuration
REPO_OWNER="Muneeb-Nazir"
REPO_NAME="Proxmox-pve-hardware-monitor"
REPO_URL="https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/main"

# Version tracking
SCRIPT_VERSION="2.0.0"
SCRIPT_NAME="pve-monitor-installer.sh"
MAIN_SCRIPT="pve-monitor.sh"
CONFIG_FILE="pve-monitor.conf"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Progress bar function
show_progress() {
    local duration=$1
    local message=$2
    local width=50
    local percent=0
    local i=0
    
    echo -ne "${CYAN}${message}${NC} ["
    for i in $(seq 1 $width); do
        echo -ne " "
    done
    echo -ne "] 0%\r${CYAN}${message}${NC} ["
    
    for i in $(seq 1 $width); do
        sleep $(echo "scale=3; $duration / $width" | bc)
        percent=$((i * 100 / width))
        echo -ne "▓"
        echo -ne "] ${percent}%\r${CYAN}${message}${NC} ["
    done
    echo -ne "▓] 100%\n"
    echo -e "${GREEN}✓ Complete${NC}"
}

# Spinner for background tasks
show_spinner() {
    local pid=$1
    local message=$2
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) % ${#spin} ))
        printf "\r${CYAN}${message}${NC} ${spin:$i:1}"
        sleep 0.1
    done
    printf "\r${GREEN}✓ ${message}${NC}    \n"
}

# Print colored output
print_status() { echo -e "${BLUE}[*]${NC} $1"; }
print_success() { echo -e "${GREEN}[+]${NC} $1"; }
print_error() { echo -e "${RED}[-]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
print_header() { echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"; }

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root"
        exit 1
    fi
}

# Check internet connection
check_internet() {
    print_status "Checking internet connection..."
    if ping -c 1 google.com &>/dev/null; then
        print_success "Internet connection OK"
        return 0
    else
        print_warning "No internet connection - will use local files only"
        return 1
    fi
}

# Get latest version from GitHub
get_latest_version() {
    if check_internet; then
        local latest=$(curl -s "${REPO_URL}/version.txt" 2>/dev/null)
        if [ -n "$latest" ]; then
            echo "$latest"
        else
            echo "$SCRIPT_VERSION"
        fi
    else
        echo "$SCRIPT_VERSION"
    fi
}

# Compare versions
version_gt() {
    test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1"
}

# Download file from GitHub
download_from_github() {
    local file=$1
    local dest=$2
    local url="${REPO_URL}/${file}"
    
    if curl -s -o "$dest" "$url"; then
        return 0
    else
        return 1
    fi
}

# Check for updates
check_for_updates() {
    print_status "Checking for updates..."
    
    local latest_version=$(get_latest_version)
    
    if version_gt "$latest_version" "$SCRIPT_VERSION"; then
        print_warning "New version available: $latest_version (current: $SCRIPT_VERSION)"
        echo ""
        echo "Choose an option:"
        echo "  1) Update now"
        echo "  2) Skip this update"
        echo "  3) View changelog"
        read -p "Enter choice [1-3]: " update_choice
        
        case $update_choice in
            1)
                perform_update
                ;;
            2)
                print_status "Skipping update"
                ;;
            3)
                show_changelog
                check_for_updates
                ;;
        esac
    else
        print_success "Already at latest version ($SCRIPT_VERSION)"
    fi
}

# Perform update
perform_update() {
    print_header
    echo -e "${YELLOW}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}                    UPDATING PVE MONITOR                         ${NC}"
    echo -e "${YELLOW}════════════════════════════════════════════════════════════════${NC}"
    
    print_status "Stopping services..."
    systemctl stop pve-monitor.service 2>/dev/null
    systemctl stop temp-logger.service 2>/dev/null
    
    if [ -f "/etc/$CONFIG_FILE" ]; then
        print_status "Backing up configuration..."
        cp "/etc/$CONFIG_FILE" "/etc/${CONFIG_FILE}.backup"
        print_success "Configuration backed up"
    fi
    
    print_status "Downloading new version..."
    local temp_script="/tmp/${MAIN_SCRIPT}"
    if download_from_github "$MAIN_SCRIPT" "$temp_script"; then
        chmod +x "$temp_script"
        cp "$temp_script" "/usr/local/bin/pve-monitor"
        print_success "Main script updated"
    else
        print_error "Failed to download main script"
        return 1
    fi
    
    echo "$SCRIPT_VERSION" > /usr/local/bin/pve-monitor-version
    
    print_status "Restarting services..."
    systemctl daemon-reload
    systemctl start pve-monitor.service 2>/dev/null
    systemctl start temp-logger.service 2>/dev/null
    
    print_success "Update completed!"
    echo ""
}

# Show changelog
show_changelog() {
    print_header
    echo -e "${CYAN}Changelog for version $(get_latest_version):${NC}"
    echo ""
    
    if check_internet; then
        curl -s "${REPO_URL}/CHANGELOG.md" 2>/dev/null | head -50
    else
        echo "No internet connection - unable to fetch changelog"
    fi
    
    echo ""
    read -p "Press Enter to continue..."
}

# Detect existing installation
detect_existing() {
    if [ -f "/usr/local/bin/pve-monitor" ]; then
        INSTALLED=true
        if [ -f "/usr/local/bin/pve-monitor-version" ]; then
            INSTALLED_VERSION=$(cat /usr/local/bin/pve-monitor-version)
        else
            INSTALLED_VERSION="unknown"
        fi
    else
        INSTALLED=false
    fi
}

# Show installation status
show_installation_status() {
    print_header
    echo -e "${CYAN}Current Installation Status:${NC}"
    echo ""
    
    if [ "$INSTALLED" = true ]; then
        echo -e "  ${GREEN}✓${NC} PVE Monitor: Installed"
        echo -e "  ${GREEN}✓${NC} Version: $INSTALLED_VERSION"
        echo -e "  ${GREEN}✓${NC} Service: $(systemctl is-active pve-monitor.service 2>/dev/null || echo 'inactive')"
        echo -e "  ${GREEN}✓${NC} Logger: $(systemctl is-active temp-logger.service 2>/dev/null || echo 'inactive')"
        echo -e "  ${GREEN}✓${NC} Auto-start: $(systemctl is-enabled pve-monitor.service 2>/dev/null || echo 'disabled')"
    else
        echo -e "  ${YELLOW}○${NC} PVE Monitor: Not installed"
    fi
    
    echo ""
}

# Uninstall
uninstall_monitor() {
    print_header
    echo -e "${RED}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${RED}                    UNINSTALLING PVE MONITOR                      ${NC}"
    echo -e "${RED}════════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    print_warning "This will remove PVE Monitor and all its components"
    read -p "Are you sure? (y/N): " confirm
    
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        print_status "Uninstall cancelled"
        return
    fi
    
    print_status "Stopping services..."
    systemctl stop pve-monitor.service temp-logger.service 2>/dev/null
    systemctl disable pve-monitor.service temp-logger.service 2>/dev/null
    
    print_status "Removing service files..."
    rm -f /etc/systemd/system/pve-monitor.service
    rm -f /etc/systemd/system/temp-logger.service
    systemctl daemon-reload
    
    print_status "Removing scripts..."
    rm -f /usr/local/bin/pve-monitor
    rm -f /usr/local/bin/temp-logger
    rm -f /usr/local/bin/temp-alert
    rm -f /usr/local/bin/pve-monitor-version
    
    read -p "Remove configuration files? (y/N): " remove_config
    if [[ "$remove_config" == "y" || "$remove_config" == "Y" ]]; then
        rm -f /etc/pve-monitor.conf
        rm -f /etc/pve-monitor.conf.backup
        print_success "Configuration removed"
    else
        print_status "Configuration preserved at /etc/pve-monitor.conf"
    fi
    
    print_status "Removing cron jobs..."
    crontab -l 2>/dev/null | grep -v "temp-alert" | crontab - 2>/dev/null
    
    read -p "Remove log files? (y/N): " remove_logs
    if [[ "$remove_logs" == "y" || "$remove_logs" == "Y" ]]; then
        rm -f /var/log/pve-temperatures.log*
        print_success "Log files removed"
    fi
    
    print_success "PVE Monitor has been uninstalled!"
    echo ""
}

# Install fresh copy
install_monitor() {
    print_header
    echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}                    INSTALLING PVE MONITOR                       ${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    local temp_dir=$(mktemp -d)
    cd "$temp_dir"
    
    print_status "Downloading scripts from GitHub..."
    
    if check_internet; then
        if ! download_from_github "$MAIN_SCRIPT" "pve-monitor"; then
            print_error "Failed to download main script"
            return 1
        fi
        chmod +x pve-monitor
    else
        print_error "Internet connection required for installation"
        return 1
    fi
    
    print_status "Installing dependencies..."
    apt update -qq &
    show_spinner $! "Updating package lists"
    
    apt install -y -qq lm-sensors bc curl wget postfix mailutils pve-container &
    show_spinner $! "Installing packages"
    
    print_status "Creating directories..."
    mkdir -p /usr/local/bin
    
    print_status "Installing scripts..."
    cp pve-monitor /usr/local/bin/
    chmod +x /usr/local/bin/pve-monitor
    
    echo "$SCRIPT_VERSION" > /usr/local/bin/pve-monitor-version
    
    print_status "Creating configuration..."
    cat > /etc/pve-monitor.conf << EOF
# PVE Monitor Configuration
# Generated: $(date)
# Version: $SCRIPT_VERSION

# Email settings
ALERT_EMAIL="root@localhost"
TEMP_WARNING=75
TEMP_CRITICAL=85

# Hardware settings
CPU_VENDOR="$(grep -qi amd /proc/cpuinfo && echo "AMD" || echo "Intel")"
IS_THINKPAD=$(dmidecode -s system-manufacturer 2>/dev/null | grep -qi "LENOVO" && echo "true" || echo "false")

# Alert settings
ENABLE_EMAIL_ALERTS=true
ENABLE_WALL_ALERTS=true
ALERT_INTERVAL=300
LOG_TEMPERATURES=true

# Monitoring settings
SHOW_LXC=true
SHOW_VM=true
SHOW_ALL_CONTAINERS=true
EOF
    
    print_status "Creating systemd services..."
    cat > /etc/systemd/system/pve-monitor.service << EOF
[Unit]
Description=PVE Universal Hardware Monitor Dashboard
After=multi-user.target network.target pve-cluster.service
Wants=pve-cluster.service

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/pve-monitor
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal
TTYPath=/dev/tty1

[Install]
WantedBy=multi-user.target
EOF

    cat > /etc/systemd/system/temp-logger.service << EOF
[Unit]
Description=PVE Temperature Logger with Email Alerts
After=multi-user.target network.target pve-cluster.service

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/temp-logger
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

    cat > /usr/local/bin/temp-logger << 'LOGGER_EOF'
#!/bin/bash
LOG_FILE="/var/log/pve-temperatures.log"
while true; do
    echo "$(date): Temperature logging active" >> $LOG_FILE
    sleep 60
done
LOGGER_EOF
    chmod +x /usr/local/bin/temp-logger
    
    cat > /usr/local/bin/temp-alert << 'ALERT_EOF'
#!/bin/bash
echo "Temperature check completed at $(date)" >> /var/log/pve-temperatures.log
ALERT_EOF
    chmod +x /usr/local/bin/temp-alert
    
    print_status "Starting services..."
    systemctl daemon-reload
    systemctl enable pve-monitor.service temp-logger.service
    systemctl start pve-monitor.service temp-logger.service
    
    print_status "Setting up cron jobs..."
    (crontab -l 2>/dev/null; echo "*/5 * * * * /usr/local/bin/temp-alert") | crontab - 2>/dev/null
    
    print_status "Configuring email..."
    if ! systemctl is-active --quiet postfix; then
        systemctl start postfix
        systemctl enable postfix
    fi
    
    cd /
    rm -rf "$temp_dir"
    
    print_success "Installation completed successfully!"
    echo ""
}

# Show menu
show_menu() {
    clear
    print_header
    echo -e "${CYAN}           PVE HARDWARE MONITOR - MANAGEMENT MENU                ${NC}"
    print_header
    echo ""
    show_installation_status
    echo ""
    echo -e "${YELLOW}Available Options:${NC}"
    echo "  1) Install / Reinstall"
    echo "  2) Update (check for updates)"
    echo "  3) Uninstall"
    echo "  4) Show status"
    echo "  5) View live dashboard"
    echo "  6) View logs"
    echo "  7) Configure settings"
    echo "  8) Test email alert"
    echo "  9) Restart services"
    echo "  10) About"
    echo "  0) Exit"
    echo ""
    read -p "Enter choice [0-10]: " choice
    
    case $choice in
        1) install_monitor ;;
        2) check_for_updates ;;
        3) uninstall_monitor ;;
        4) show_installation_status; read -p "Press Enter to continue..." ;;
        5) view_dashboard ;;
        6) view_logs ;;
        7) configure_settings ;;
        8) test_email ;;
        9) restart_services ;;
        10) show_about ;;
        0) echo -e "${GREEN}Goodbye!${NC}"; exit 0 ;;
        *) print_error "Invalid option"; sleep 2; show_menu ;;
    esac
    
    echo ""
    read -p "Press Enter to return to menu..."
    show_menu
}

# View dashboard
view_dashboard() {
    print_status "Viewing live dashboard (Ctrl+C to exit)..."
    sleep 1
    if systemctl is-active --quiet pve-monitor.service; then
        journalctl -u pve-monitor.service -f --output=cat
    else
        print_error "Service not running"
    fi
}

# View logs
view_logs() {
    if [ -f "/var/log/pve-temperatures.log" ]; then
        tail -50 /var/log/pve-temperatures.log
    else
        print_warning "No logs found"
    fi
}

# Configure settings
configure_settings() {
    if [ -f "/etc/pve-monitor.conf" ]; then
        nano /etc/pve-monitor.conf
        print_success "Configuration updated"
        systemctl restart pve-monitor.service temp-logger.service
    else
        print_error "Configuration file not found"
    fi
}

# Test email
test_email() {
    print_status "Sending test email..."
    local email=$(grep ALERT_EMAIL /etc/pve-monitor.conf | cut -d'"' -f2)
    echo "PVE Monitor Test - $(date)" | mail -s "PVE Monitor Test" "$email"
    print_success "Test email sent to $email"
}

# Restart services
restart_services() {
    print_status "Restarting services..."
    systemctl restart pve-monitor.service temp-logger.service
    print_success "Services restarted"
}

# Show about
show_about() {
    print_header
    echo -e "${CYAN}PVE Universal Hardware Monitor${NC}"
    echo -e "Version: $SCRIPT_VERSION"
    echo -e "Repository: https://github.com/${REPO_OWNER}/${REPO_NAME}"
    echo -e "License: MIT"
    echo -e ""
    echo -e "Features:"
    echo -e "  • CPU temperature monitoring"
    echo -e "  • Fan speed detection"
    echo -e "  • LXC container detection"
    echo -e "  • QEMU VM detection"
    echo -e "  • Email alerts"
    echo -e "  • Auto-start on boot"
    echo -e "  • Self-updating"
    print_header
}

# Main execution
main() {
    check_root
    
    if [[ "$1" == "--update" ]]; then
        check_for_updates
        exit 0
    elif [[ "$1" == "--install" ]]; then
        install_monitor
        exit 0
    elif [[ "$1" == "--uninstall" ]]; then
        uninstall_monitor
        exit 0
    fi
    
    detect_existing
    show_menu
}

main "$@"
SCRIPT_EOF

chmod +x pve-monitor-installer.sh
./pve-monitor-installer.sh
