# Dotfiles-Playbook

Ansible playbooks for Managing my Linux (Debian, Fedora, Arch), and MacOS Machines

## Usage

Run `bootstrap.sh`.

### What the Script Does

- Script will check the Linux distribution and run the appropriate Ansible playbook and install required software and Ansible requirements for the target system.
- Playbook is designed to work with a repository containing dotfiles and configuration files like my [dotfiles](https://github.com/henningmyhrvold/dotfiles.git) repository. These are configured in the configuration `yaml` files in the `group_vars` and `host_vars` folders.

### Overriding Defaults

- Variables used by Ansible can be overridden with a `config.yml` file in the root of the repository. Optionally, another configuration `yaml` file specified in a repository that contains vars files such as `dotfiles-overlay` defined in the `default-config.yml`.
- These files can be helpful to override variables for different machines or environments and manage secrets outside of this repository.

