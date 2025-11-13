# flask-ci-cd-rollback-pipeline

cat > README.md <<'MD'
# Linux System Hardening Script

A small Bash script to apply basic hardening on Debian/Ubuntu systems:
- Update & upgrade packages
- Disable root SSH login
- Create admin user
- Configure UFW firewall
- Remove insecure packages
- Lock file permissions
- Enable unattended upgrades
- Scan for world-writable files

## Usage
Run as root (or with sudo):

chmod +x harden.sh
sudo ./harden.sh

Warning

Run this in a test environment first. The script changes SSH and firewall settings which may lock you out if not prepared.

MD

---


