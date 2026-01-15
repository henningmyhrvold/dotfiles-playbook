#!/bin/bash
# Bootstrap script for Arch Linux dotfiles-playbook
# Simplified version - Arch Linux only

set -e

DOTFILES="$HOME/src/dotfiles-playbook"
DOTSSH="$HOME/.ssh"

# Verify we're on Arch Linux
if [ ! -f /etc/os-release ] || ! grep -q 'ID=arch' /etc/os-release; then
    echo "Error: This script only supports Arch Linux."
    exit 1
fi

# Check if Ansible is installed
if ! command -v ansible &> /dev/null; then
    echo "Error: Ansible is not installed."
    echo "Install it with: sudo pacman -S ansible"
    exit 1
fi

# Create SSH key if it doesn't exist
if [ ! -f "$DOTSSH/id_ed25519" ]; then
    echo "Creating SSH Ed25519 key..."
    mkdir -p "$DOTSSH"
    chmod 700 "$DOTSSH"
    ssh-keygen -t ed25519 -f "$DOTSSH/id_ed25519" -N "" -C "$USER@$(uname -n)"
    cat "$DOTSSH/id_ed25519.pub" >> "$DOTSSH/authorized_keys"
    chmod 600 "$DOTSSH/authorized_keys"
    echo "SSH key created."
fi

# Install Ansible requirements
echo "Installing Ansible requirements..."
ansible-galaxy install -r "$DOTFILES/requirements.yml"

# Run playbook
echo "Running Ansible playbook..."
cd "$DOTFILES"
ansible-playbook playbook.yml --diff -v --ask-become-pass

echo "Done!"
