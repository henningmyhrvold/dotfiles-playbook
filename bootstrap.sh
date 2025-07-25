#!/usr/bin/env bash

# Script to run on a new system to configure it.
# 1. First, check if the distribution is Arch, Debian, Fedora, or MacOS. If it is not one of those, the script exits.
# 2. Checks if Ansible is installed; exits with an error if not (Ansible is expected to be installed by post_install.sh).
# 3. Checks if an SSH RSA key exists. If it doesn't, create one.
# 4. Installs Ansible requirements based on the distribution.
# 5. Updates the inventory to use SSH for Arch to ensure PTY allocation.
# 6. Updates ansible.cfg to disable pipelining for PTY support.
# 7. Adds localhost and 127.0.0.1 to known_hosts to avoid host key verification failures.
# 8. Ensures SSHD is running on Arch.
# 9. Runs the Ansible playbook, prompting for sudo password.

# Exit immediately if any command the script executes fails (returns a non-zero status).
set -e

##########################################
## Variables
##########################################

DOTFILES="$HOME/src/dotfiles-playbook"
DOTSSH="$HOME/.ssh"

# System Flags
isDebian="false"
isFedora="false"
isArch="false"
isMacOS="false"

current_user="$USER"

# Check the OS
if [ -f /etc/os-release ]; then
  # Get os-release variables
  # shellcheck source=/dev/null
  . /etc/os-release
  if [ "$ID" = "debian" ]; then
    isDebian="true"
  elif [ "$ID" = "fedora" ]; then
    isFedora="true"
  elif [ "$ID" = "arch" ]; then
    isArch="true"
  fi
# Detect MacOS
elif [[ "$OSTYPE" == "darwin"* ]]; then
  isMacOS="true"
fi

# If the distribution is not one of the supported ones, exit.
if [ "$isDebian" = "false" ] && [ "$isFedora" = "false" ] && [ "$isArch" = "false" ] && [ "$isMacOS" = "false" ]; then
  echo "This distribution is not supported by this script. Only Arch, Debian, Fedora, and MacOS are supported."
  exit 1
fi

##########################################
## Functions
##########################################

# Checks if Ansible is installed; exits with an error if not.
check_ansible() {
  if ! [ -x "$(command -v ansible)" ]; then
    echo "Error: Ansible is not installed. Please ensure Ansible is installed before running this script."
    exit 1
  fi
}

# Install Ansible requirements from a requirements file.
install_ansible_requirements() {
  if [ "$isArch" = "true" ]; then
    ansible-galaxy install -r requirements-arch.yml
  else
    ansible-galaxy install -r requirements-common.yml
  fi
}

# Creates an SSH RSA key if one doesn't already exist.
setup_RSA_key() {
  # Check if SSH RSA key exists
  if [ ! -f "$DOTSSH/id_rsa" ]; then
    echo "SSH RSA key does not exist. Creating a 4096-bit SSH RSA key..."
    mkdir -p "$DOTSSH"
    chmod 700 "$DOTSSH"
    ssh-keygen -b 4096 -t rsa -f "$DOTSSH/id_rsa" -N "" -C "$USER@$(uname -n)"
    cat "$DOTSSH/id_rsa.pub" >>"$DOTSSH/authorized_keys"
    chmod 600 "$DOTSSH/authorized_keys"
    echo "SSH key created and added to authorized_keys."
  fi
}

# Updates the Ansible inventory to use SSH connection for Arch
update_inventory() {
  if [ "$isArch" = "true" ]; then
    cd "$DOTFILES"
    sed -i '/\[workstation_arch\]/,+1 s/ansible_connection=local/ansible_connection=ssh ansible_host=127.0.0.1 ansible_user='"$current_user"'/' inventory
  fi
}

# Updates ansible.cfg to disable pipelining if not already set
update_ansible_cfg() {
  cd "$DOTFILES"
  if ! grep -q "^\[ssh_connection\]" ansible.cfg; then
    echo "" >> ansible.cfg
    echo "[ssh_connection]" >> ansible.cfg
    echo "pipelining = False" >> ansible.cfg
  fi
}

# Adds localhost and 127.0.0.1 host keys to known_hosts
add_localhost_known_hosts() {
  if [ "$isArch" = "true" ]; then
    echo "Adding localhost and 127.0.0.1 to known_hosts to avoid verification failures..."
    [ -f ~/.ssh/known_hosts ] || touch ~/.ssh/known_hosts
    ssh-keyscan -H localhost >> ~/.ssh/known_hosts 2>/dev/null
    ssh-keyscan -H 127.0.0.1 >> ~/.ssh/known_hosts 2>/dev/null
  fi
}

#################################
## Main Start of Script
#################################

check_ansible

install_ansible_requirements

setup_RSA_key

update_inventory

update_ansible_cfg

add_localhost_known_hosts

cd "$DOTFILES"

# Cache sudo credentials to minimize prompts during the run
echo "Please enter your sudo password to cache credentials:"
sudo -v

# Ensure SSHD is running on Arch
if [ "$isArch" = "true" ]; then
  echo "Ensuring SSHD is running..."
  sudo systemctl enable --now sshd
fi

# ==== Run Ansible Playbook ====
echo "Running Ansible playbook..."

# Common arguments for ansible-playbook
COMMON_ARGS="--diff -v"

# Arguments for privilege escalation (sudo)
BECOME_ARGS="--ask-become-pass"

if [ "$isDebian" = "true" ]; then
  ansible-playbook $COMMON_ARGS $BECOME_ARGS "$DOTFILES/debian.yml"
fi

if [ "$isFedora" = "true" ]; then
  ansible-playbook $COMMON_ARGS $BECOME_ARGS "$DOTFILES/fedora.yml"
fi

if [ "$isArch" = "true" ]; then
  ansible-playbook $COMMON_ARGS $BECOME_ARGS "$DOTFILES/arch.yml"
fi

if [ "$isMacOS" = "true" ]; then
  ansible-playbook $COMMON_ARGS $BECOME_ARGS "$DOTFILES/macos.yml"
fi

echo "Script finished."
