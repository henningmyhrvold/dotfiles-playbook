# Dotfiles-Playbook

Ansible playbooks for Managing my Linux (Debian, Fedora, Arch), and MacOS Machines

## Usage

**Change myuser name with youruser name**
```bash
git grep -l myuser | xargs sed -i 's/myuser/youruser/g'
```

Run `bootstrap.sh -r`

### What the Script Does

- Script will check the Linux distribution and run the appropriate Ansible playbook and install required software and Ansible requirements for the target system.
- Playbook is designed to work with a repository containing dotfiles and configuration files like my [dotfiles](https://github.com/henningmyhrvold/dotfiles.git) repository. These are configured in the configuration `yaml` files in the `group_vars` and `host_vars` folders.


