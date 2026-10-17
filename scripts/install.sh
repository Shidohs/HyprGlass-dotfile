#!/usr/bin/env bash
# HyprGlass - Next Gen Declarative Installer via Ansible
# Automatically generated migration

set -euo pipefail

# Styles
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}=== HyprGlass V2 Declarative Installer ===${NC}"

# Check for Ansible
if ! command -v ansible-playbook &> /dev/null; then
    echo -e "${GREEN}Installing Ansible (requires sudo)...${NC}"
    sudo pacman -S --noconfirm ansible
fi

cd "$(dirname "${BASH_SOURCE[0]}")/../ansible"

echo -e "${GREEN}Running Ansible Playbook...${NC}"
ansible-playbook setup.yml -K

echo -e "${BLUE}=== Installation Complete ===${NC}"
echo "Please reboot your system for all changes (like default shell) to take effect."
