# Hidden SSH via Tor

This Bash script allows you to securely connect to your VPS through the Tor network using proxychains4. It provides a simple menu-driven interface to install and configure required tools, connect via Tor, check system status, and clean up installations.

## Prerequisites
- A Debian/Ubuntu-based Linux system with `sudo` privileges
- Internet access to install packages

## Installation & Configuration
1. Run the script as root:
   ```bash
   sudo ./connect_vps_tor.sh
   ```
2. Select **1) Install & configure tools** to:
   - Install Tor and proxychains4
   - Configure Tor (`/etc/tor/torrc`)
   - Configure proxychains (`/etc/proxychains.conf`)
   - Prepare `~/.ssh/known_hosts`

## Connect to VPS
After installation, choose **2) Connect to VPS via Tor**, then:
1. Enter your SSH target (e.g., `root@1.2.3.4`).
2. The script will:
   - Test TCP connectivity to port 22 over Tor
   - Retrieve and add the host key to `~/.ssh/known_hosts`
   - Initiate an interactive SSH session through Tor

## Uninstall
Select **3) Uninstall tools** to:
- Stop and disable Tor service
- Remove Tor and proxychains4 packages
- Remove configuration files and SSH directory

## Show Status
Select **4) Show status** to view:
- Tor service status
- Proxychains configuration check
- Number of entries in `known_hosts`

## Exit
Select **0) Exit** to quit the script.

## License
This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details. 
