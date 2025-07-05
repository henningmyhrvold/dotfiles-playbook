#!/usr/bin/env bash

# Script to run on a new system to configure it.
# 1. First, check if the distribution is Arch, Debian, Fedora, or MacOS. If it is not one of those, the script exits.
# 2. Checks if Ansible is installed; exits with an error if not (Ansible is expected to be installed by post_install.sh).
# 3. Checks if an SSH RSA key exists. If it doesn't, create one.
# 4. Installs Ansible requirements based on the distribution.
# 5. Runs the Ansible playbook, prompting for sudo password.

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
    ssh-keygen -b 4096 -t rsa -f "$DOTSSH/id_rsa" -N "" -C "$USER@$(hostname)"
    cat "$DOTSSH/id_rsa.pub" >>"$DOTSSH/authorized_keys"
    chmod 600 "$DOTSSH/authorized_keys"
    echo "SSH key created and added to authorized_keys."
  fi
}

#################################
## Main Start of Script
#################################

check_ansible

install_ansible_requirements

setup_RSA_key

cd "$DOTFILES"

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
