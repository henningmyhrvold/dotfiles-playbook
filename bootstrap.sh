#!/usr/bin/env bash

# Script to run on a new system to configure it.
# 1. First, check if the distribution is Arch, Debian, Fedora, or MacOS. If it is not one of those, the script exits.
# 2. Installs any prequisites needed for the Ansible playbook and software more easily installed in command line.
# 3. Checks if an SSH RSA key exists. If it doesn't, create one.
# 4. If the bootstrap script has an argument "-r" and there are Ansible requirements, install them.
# 5. Run the Ansible playbook.

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

# Restart shell flag
restartShell="false"

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

# Installs Ansible using pipx if it's not already installed.
install_ansible() {
  # Check if Ansible is installed
  if ! [ -x "$(command -v ansible)" ]; then
    echo "Ansible is not installed. Installing Ansible using pipx..."

    if [ "$isDebian" = "true" ]; then
      sudo apt update
      sudo apt install pipx -y
    fi

    if [ "$isArch" = "true" ]; then
      sudo pacman -S --noconfirm python python-pipx
    fi

    if [ "$isFedora" = "true" ]; then
      sudo dnf install pipx -y
    fi

    if [ "$isMacOS" = "true" ]; then
      echo "Installing Homebrew and pipx..."
      # Install Brew package manager if not found
      if ! [ -x "$(command -v brew)" ]; then
          /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      fi
      # from https://github.com/pypa/pipx
      brew install pipx
      pipx ensurepath
      echo "*** You may need to manually add Homebrew to your path. ***"
    fi

    pipx install --include-deps ansible
    # Add pipx bin path to shell
    echo "export PATH=$PATH:$HOME/.local/bin" >>~/.bashrc
    restartShell="true"
  fi
}

# Installs commands and tools that the Ansible playbook needs.
install_prequisites() {
  install_ansible

  # if restartShell is true, tell user to restart shell and exit script
  if [ "$restartShell" = "true" ]; then
    # Sourcing does not work for some programs and a shell restart is needed to get PATH changes
    echo "Restart shell to get PATH changes for Ansible."
    echo "Then re-run with: bootstrap.sh -r"
    exit 0
  fi
}

# Install Ansible requirements from a requirements file.
install_ansible_requirements() {
  if [ -f requirements.yml ]; then
    echo "Ansible requirements file found. Installing Ansible requirements..."
    ansible-galaxy install -r requirements.yml
  else
    echo "No 'requirements.yml' file found. Skipping."
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

install_prequisites

# Check if shell script has an argument "-r" (for requirements), if yes, install them.
if [ "$1" = "-r" ]; then
  install_ansible_requirements
fi

setup_RSA_key

cd "$DOTFILES"

# ==== Run Ansible Playbook ====
echo "Running Ansible playbook..."

if [ -f "$DOTFILES/vault-password.txt" ]; then
  VAULT_ARGS="--vault-password-file $DOTFILES/vault-password.txt"
else
  # --ask-become-pass : ask for privilege escalation password
  VAULT_ARGS="--ask-become-pass"
fi

# --diff : when changing files/templates, show the differences in files
# -v : low verbose mode, can increase with -vvv...
COMMON_ARGS="--diff -v"

if [ "$isDebian" = "true" ]; then
  ansible-playbook $COMMON_ARGS "$DOTFILES/debian.yml" $VAULT_ARGS
fi

if [ "$isFedora" = "true" ]; then
  ansible-playbook $COMMON_ARGS "$DOTFILES/fedora.yml" $VAULT_ARGS
fi

if [ "$isArch" = "true" ]; then
  ansible-playbook $COMMON_ARGS "$DOTFILES/arch.yml" $VAULT_ARGS
fi

if [ "$isMacOS" = "true" ]; then
  ansible-playbook $COMMON_ARGS "$DOTFILES/macos.yml" $VAULT_ARGS
fi

echo "Script finished."
