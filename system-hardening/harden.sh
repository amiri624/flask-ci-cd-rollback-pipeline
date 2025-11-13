
cat > harden.sh <<'SH'
#!/usr/bin/env bash
# ----------------------------------------
# Linux System Hardening Script
# ----------------------------------------

set -euo pipefail

# ------- Configurable variables -------
ADMIN_USER="secureadmin"
ADMIN_PASS="ChangeMe123!"
SSH_SERVICE="sshd"
BACKUP_DIR="./backup"
LOG_FILE="./logs/harden_$(date +%Y%m%d_%H%M%S).log"
# --------------------------------------

# create logs and backup directories if missing
mkdir -p "$BACKUP_DIR"
mkdir -p ./logs

exec > >(tee -a "$LOG_FILE") 2>&1

echo "🔒 Starting System Hardening..."

if [ "$(id -u)" -ne 0 ]; then
  echo "Run as root or sudo."
  exit 1
fi

# 1) Update & Upgrade
echo "[1/9] Updating system packages..."
if command -v apt >/dev/null 2>&1; then
  apt update -y && apt upgrade -y
fi

# 2) Backup and disable root SSH login
echo "[2/9] Backup sshd_config..."
if [ -f /etc/ssh/sshd_config ]; then
  cp /etc/ssh/sshd_config "$BACKUP_DIR/sshd_config.bak"
  sed -i.bak -E 's/^#?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
  systemctl restart "$SSH_SERVICE"  service "$SSH_SERVICE" restart  true
fi

# 3) SSH hardening
echo "[3/9] Enforcing SSH protocol 2 and disable empty passwords..."
if [ -f /etc/ssh/sshd_config ]; then
  sed -i -E 's/^#?Protocol.*/Protocol 2/' /etc/ssh/sshd_config || true
  sed -i -E 's/^#?PermitEmptyPasswords.*/PermitEmptyPasswords no/' /etc/ssh/sshd_config || true
fi

# 4) Create admin user
echo "[4/9] Creating admin user '${ADMIN_USER}'..."
if ! id "${ADMIN_USER}" >/dev/null 2>&1; then
  useradd -m -s /bin/bash "${ADMIN_USER}"
  echo "${ADMIN_USER}:${ADMIN_PASS}" | chpasswd
  usermod -aG sudo "${ADMIN_USER}" || true
else
  echo "User exists, skipping."
fi

# 5) Configure UFW
echo "[5/9] Configuring firewall..."
if command -v apt >/dev/null 2>&1; then
  apt install -y ufw || true
  cp /etc/ufw/ufw.conf "$BACKUP_DIR/ufw.conf.bak" || true
  ufw default deny incoming
  ufw default allow outgoing
  ufw allow OpenSSH
  ufw --force enable
fi

# 6) Remove insecure packages
echo "[6/9] Removing insecure packages..."
if command -v apt >/dev/null 2>&1; then
  apt purge -y telnet rsh-client rsh-server inetutils-inetd || true
  apt autoremove -y || true
fi

# 7) Secure permissions
echo "[7/9] Securing critical files..."
chmod 600 /etc/shadow || true
chmod 600 /etc/ssh/sshd_config || true

# 8) Enable unattended upgrades
echo "[8/9] Enabling automatic security updates..."
if command -v apt >/dev/null 2>&1; then
  apt install -y unattended-upgrades apt-listchanges || true
  dpkg-reconfigure -plow unattended-upgrades || true
fi

# 9) Scan world-writable files
echo "[9/9] Scanning for world-writable files..."
find / -xdev -type f -perm -0002 -print 2>/dev/null > ./logs/world_writable_files.txt

echo "✅ Hardening complete. Logs in $LOG_FILE"
SH
