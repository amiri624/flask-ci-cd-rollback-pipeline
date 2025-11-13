# Backup Folder

This folder stores backup copies of important configuration files before the hardening script modifies them.

- Examples:
  - sshd_config.bak — backup of SSH configuration
  - ufw.conf.bak — backup of UFW firewall configuration (if applicable)
- Always review backup files before restoring.
- Restore example:

sudo cp backup/sshd_config.bak /etc/ssh/sshd_config sudo systemctl restart sshd

- It is recommended to keep backups safe in case of errors or rollback needs.
