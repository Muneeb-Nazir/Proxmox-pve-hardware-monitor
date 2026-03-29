cat > /tmp/remove-pve-monitor.sh << 'EOF'
#!/bin/bash

# =============================================================================
# PVE Monitor Complete Removal Script
# Removes ONLY PVE Monitor components, leaves Proxmox email system intact
# =============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo -e "${RED}════════════════════════════════════════════════════════════════${NC}"
echo -e "${RED}           PVE MONITOR COMPLETE REMOVAL SCRIPT                   ${NC}"
echo -e "${RED}════════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}This will remove:${NC}"
echo "  • PVE Monitor dashboard script"
echo "  • Temperature logger script"
echo "  • Alert script"
echo "  • Systemd services"
echo "  • Configuration files"
echo "  • Cron jobs"
echo "  • Log files"
echo ""
echo -e "${GREEN}This will NOT remove:${NC}"
echo "  • Postfix (Proxmox email system)"
echo "  • lm-sensors (can be kept for other uses)"
echo "  • Any VMs or containers"
echo "  • Proxmox core functionality"
echo ""
read -p "Are you sure you want to remove PVE Monitor? (y/N): " confirm

if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo -e "${GREEN}Removal cancelled.${NC}"
    exit 0
fi

echo ""
echo -e "${BLUE}[*] Stopping services...${NC}"
systemctl stop pve-monitor.service 2>/dev/null
systemctl stop temp-logger.service 2>/dev/null
systemctl disable pve-monitor.service 2>/dev/null
systemctl disable temp-logger.service 2>/dev/null
echo -e "${GREEN}[+] Services stopped${NC}"

echo ""
echo -e "${BLUE}[*] Removing systemd service files...${NC}"
rm -f /etc/systemd/system/pve-monitor.service
rm -f /etc/systemd/system/temp-logger.service
systemctl daemon-reload
echo -e "${GREEN}[+] Service files removed${NC}"

echo ""
echo -e "${BLUE}[*] Removing scripts...${NC}"
rm -f /usr/local/bin/pve-monitor
rm -f /usr/local/bin/temp-logger
rm -f /usr/local/bin/temp-alert
rm -f /usr/local/bin/pve-monitor-version
echo -e "${GREEN}[+] Scripts removed${NC}"

echo ""
echo -e "${BLUE}[*] Removing configuration files...${NC}"
rm -f /etc/pve-monitor.conf
rm -f /etc/pve-monitor.conf.backup
rm -f /etc/pve-monitor-version
echo -e "${GREEN}[+] Configuration files removed${NC}"

echo ""
echo -e "${BLUE}[*] Removing cron jobs...${NC}"
crontab -l 2>/dev/null | grep -v "temp-alert" | grep -v "pve-monitor" | crontab - 2>/dev/null
echo -e "${GREEN}[+] Cron jobs removed${NC}"

echo ""
echo -e "${BLUE}[*] Removing log files...${NC}"
rm -f /var/log/pve-temperatures.log
rm -f /var/log/pve-temperatures.log.old
rm -f /var/log/pve-monitor-email.log
echo -e "${GREEN}[+] Log files removed${NC}"

echo ""
echo -e "${BLUE}[*] Removing temporary files...${NC}"
rm -f /tmp/pve-monitor.sh 2>/dev/null
rm -f /tmp/temp_last_alert 2>/dev/null
rm -f /tmp/last_temp_alert 2>/dev/null
echo -e "${GREEN}[+] Temporary files removed${NC}"

echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}           PVE MONITOR REMOVAL COMPLETE!                         ${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}Note:${NC} The following remain installed (for Proxmox functionality):"
echo "  • Postfix (email system)"
echo "  • lm-sensors (can be removed with: apt remove lm-sensors -y)"
echo ""
echo -e "${BLUE}To verify removal:${NC}"
echo "  systemctl status pve-monitor.service 2>/dev/null || echo 'Service not found'"
echo "  ls /usr/local/bin/pve-monitor 2>/dev/null || echo 'Script not found'"
echo ""

EOF

chmod +x /tmp/remove-pve-monitor.sh
/tmp/remove-pve-monitor.sh
