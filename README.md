# Proxmox-pve-hardware-monitor
PVE Universal Hardware Monitor - Complete Installation &amp; Update Script
One-line Installation from GitHub:
bash
# Install from GitHub (replace YOUR_USERNAME)
curl -sSL https://raw.githubusercontent.com/YOUR_USERNAME/pve-hardware-monitor/main/pve-monitor-installer.sh | bash

# Or with wget
wget -qO- https://raw.githubusercontent.com/YOUR_USERNAME/pve-hardware-monitor/main/pve-monitor-installer.sh | bash
Update existing installation:
bash
# Run the installer with update flag
curl -sSL https://raw.githubusercontent.com/YOUR_USERNAME/pve-hardware-monitor/main/pve-monitor-installer.sh | bash -s -- --update

# Or just run the installer and choose option 2
pve-monitor-installer.sh
# Then select "Update" from menu

Features of This Script:
Self-Updating
Checks GitHub for new versions
Downloads and installs updates automatically
Preserves configuration during updates
Progress Indicators
Spinner animations for background tasks
Progress bars for long operations
Color-coded status messages
Complete Management Menu
Install / Reinstall
Update (check for updates)
Uninstall
Show status
View live dashboard
View logs
Configure settings
Test email alert
Restart services
GitHub Integration
Version tracking
Automatic update detection
Changelog display
Remote installation capability
Safe Operations
Backup configuration before update
Confirm destructive operations
Preserve settings during reinstall

# PVE Hardware Monitor

Universal hardware monitoring for Proxmox VE with LXC/VM detection and email alerts.

## Quick Install
```bash
curl -sSL https://raw.githubusercontent.com/YOUR_USERNAME/pve-hardware-monitor/main/pve-monitor-installer.sh | bash

Features
CPU temperature monitoring
Fan speed detection (ThinkPad & desktops)
LXC container detection
QEMU VM detection
Email alerts (75°C warning, 85°C critical)
Auto-start on boot
Self-updating

Commands
monitor - View live dashboard
systemctl status pve-monitor - Check service status
tail -f /var/log/pve-temperatures.log - View logs
License
MIT

Now you have a complete, professional monitoring solution that:
- ✅ Installs from GitHub with one command
- ✅ Self-updates when new versions are available
- ✅ Shows progress bars and animations
- ✅ Detects LXC containers and VMs
- ✅ Sends email alerts (same as Proxmox backups)
- ✅ Auto-starts on boot
- ✅ Has a full management menu
