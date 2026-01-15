# Dotfiles-Playbook

Ansible playbook for configuring my Arch Linux workstation.

## Quick Start

```bash
# Change username to yours
git grep -l henning | xargs sed -i 's/henning/youruser/g'

# Run the playbook
./bootstrap.sh
```

## What It Does

- Installs packages from official repos (pacman) and AUR (paru)
- Sets up Hyprland (Wayland compositor), Waybar, Wofi, etc.
- Configures Zsh with Oh-My-Zsh and Powerlevel10k
- Links dotfiles from the [dotfiles repo](https://github.com/henningmyhrvold/dotfiles.git)
- Sets up Docker, development tools, and Claude AI tools

## Structure

```
.
├── bootstrap.sh      # Entry point - installs requirements and runs playbook
├── playbook.yml      # Main Ansible playbook
├── config.yml        # All configuration variables
├── inventory         # Ansible inventory (localhost)
├── requirements.yml  # Ansible Galaxy collections
├── roles/            # Ansible roles
└── ansible.cfg       # Ansible configuration
```

## Usage

```bash
# Run everything
./bootstrap.sh

# Run specific roles
ansible-playbook playbook.yml --tags "zsh,nvim,tmux"

# Dry run
ansible-playbook playbook.yml --check

# Verbose output
ansible-playbook playbook.yml -v
```

## Adding Packages

Edit `config.yml`:

```yaml
# Official repos
pacman_installed_packages:
  - package-name

# AUR
aur_installed_packages:
  - aur-package-name
```

## Adding Dotfile Symlinks

Edit `config.yml`:

```yaml
dotfiles_links:
  - { src: "app/config", dest: ".config/app/config" }
```

## Requirements

- Arch Linux
- Ansible (`sudo pacman -S ansible`)
- sudo privileges

## Companion Repository

[dotfiles](https://github.com/henningmyhrvold/dotfiles.git) - Contains the actual configuration files that get symlinked.
