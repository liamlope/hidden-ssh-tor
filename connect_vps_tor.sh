#!/usr/bin/env bash
set -e

# Simple VPS connection via Tor using proxychains4

# Configuration
TOR_SOCKS_PORT=9050
PROXYCHAINS_CONF=/etc/proxychains.conf
KNOWN_HOSTS_FILE="$HOME/.ssh/known_hosts"

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

log()    { echo -e "${BLUE}➜${NC} $*"; }
success(){ echo -e "${GREEN}✅${NC} $*"; }
error()  { echo -e "${RED}❌${NC} $*" >&2; }

check_root(){
  if [[ $EUID -ne 0 ]]; then
    error "Run as root"
    exit 1
  fi
}

install_tools(){
  log "Updating package list..."
  apt update
  log "Installing Tor and proxychains4..."
  apt install -y tor proxychains4

  log "Configuring Tor..."
  tee /etc/tor/torrc <<EOF
SocksPort ${TOR_SOCKS_PORT}
DataDirectory /var/lib/tor
RunAsDaemon 1
EOF
  systemctl enable tor
  systemctl restart tor

  log "Configuring proxychains..."
  tee "$PROXYCHAINS_CONF" <<EOF
strict_chain
proxy_dns

[ProxyList]
socks5 127.0.0.1 ${TOR_SOCKS_PORT}
EOF

  log "Preparing SSH known_hosts..."
  mkdir -p "${HOME}/.ssh"
  touch "$KNOWN_HOSTS_FILE"
  success "Installation and configuration complete"
}

uninstall_tools(){
  log "Stopping Tor service..."
  systemctl stop tor || true
  systemctl disable tor || true

  log "Removing packages..."
  apt remove -y tor proxychains4
  apt autoremove -y

  log "Cleaning up config files..."
  rm -f /etc/tor/torrc "$PROXYCHAINS_CONF"
  rm -rf "${HOME}/.ssh"

  success "Uninstallation complete"
}

connect_vps(){
  log "Enter user@host (e.g., root@1.2.3.4):"
  read -rp "> " target
  host="${target##*@}"

  log "Checking SSH port via Tor..."
  proxychains4 nc -vz -w 10 "$host" 22 || {
    error "Cannot reach SSH port on $host"
    return 1
  }

  log "Scanning host key..."
  proxychains4 ssh-keyscan -H -T 10 "$host" >> "$KNOWN_HOSTS_FILE"
  success "Host key added to known_hosts"

  log "Connecting to $target..."
  proxychains4 ssh -o StrictHostKeyChecking=yes -o HashKnownHosts=yes "$target"
}

status(){
  echo -e "\n📡 Tor service: $(systemctl is-active tor)"
  command -v tor &>/dev/null && success "Tor installed" || error "Tor missing"

  echo -e "\n🔗 Proxychains config:"
  grep -q "socks5 127.0.0.1 ${TOR_SOCKS_PORT}" "$PROXYCHAINS_CONF" && success "OK" || error "Not configured"

  echo -e "\n📝 known_hosts entries: $(wc -l < "$KNOWN_HOSTS_FILE" 2>/dev/null || echo 0)"
}

show_menu(){
  cat <<EOF

=============================
1) Install & configure tools
2) Connect to VPS via Tor
3) Uninstall tools
4) Show status
0) Exit
=============================
EOF
}

main(){
  check_root
  while true; do
    show_menu
    read -rp "> " choice
    case "$choice" in
      1) install_tools ;;
      2) connect_vps ;;
      3) uninstall_tools ;;
      4) status ;;
      0) exit 0 ;;
      *) error "Invalid choice" ;;
    esac
  done
}

main
