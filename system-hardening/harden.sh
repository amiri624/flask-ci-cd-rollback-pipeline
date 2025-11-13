cat > harden.sh <<'SH'
#!/usr/bin/env bash
# ----------------------------------------
# Linux System Hardening Script
# (Debian/Ubuntu focused)
# Author: Your Name
# ----------------------------------------

set -euo pipefail

# ------- Configurable variables -------
ADMIN_USER="secureadmin"
ADMIN_PASS="ChangeMe123!"
SSH_SERVICE="sshd"   # on some distros this is ssh, adjust if needed
# --------------------------------------

echo "🔒 Starting System Hardening..."

# 0. must run as root
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root (or via sudo). Exiting."
  exit 1
fi

# 1) Update and upgrade system (Debian/Ubuntu)
echo "[1/9] Updating system packages..."
if command -v apt >/dev/null 2>&1; then
  apt update -y && apt upgrade -y
else
  echo "apt not found — skipping package update step (non-Debian system)."
fi

# 2) Disable root SSH login
echo "[2/9] Disabling root SSH login..."
if [ -f /etc/ssh/sshd_config ]; then
  sed -i.bak -E 's/^#?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
  systemctl restart "$SSH_SERVICE"  service "$SSH_SERVICE" restart  true
fi

# 3) Ensure SSH uses protocol 2 and strong ciphers (basic)
echo "[3/9] Enforcing SSH protocol 2 and recommended configs..."
if [ -f /etc/ssh/sshd_config ]; then
  sed -i -E 's/^#?Protocol.*/Protocol 2/' /etc/ssh/sshd_config || true
  # disable empty passwords
  sed -i.bak -E 's/^#?PermitEmptyPasswords.*/PermitEmptyPasswords no/' /etc/ssh/sshd_config || true
  # optional: restrict root login by password only (we disabled root login above)
fi

# 4) Create a new admin user if not exists
echo "[4/9] Creating admin user '${ADMIN_USER}' (if missing)..."
if ! id "${ADMIN_USER}" >/dev/null 2>&1; then
  useradd -m -s /bin/bash "${ADMIN_USER}"
  echo "${ADMIN_USER}:${ADMIN_PASS}" | chpasswd
  usermod -aG sudo "${ADMIN_USER}"  usermod -aG wheel "${ADMIN_USER}"  true
  echo "User ${ADMIN_USER} created. Please change the password immediately after login."
else
  echo "User ${ADMIN_USER} already exists — skipping creation."
fi

# 5) Install and enable UFW (firewall) — Debian/Ubuntu
echo "[5/9] Installing and configuring UFW..."
if command -v apt >/dev/null 2>&1; then
  apt install -y ufw || true
  ufw default deny incoming
  ufw default allow outgoing
  ufw allow OpenSSH
  # allow HTTP as example (comment out if not needed)
  # ufw allow 80/tcp
  ufw --force enable
fi

# 6) Remove insecure/unneeded packages
echo "[6/9] Removing insecure/unneeded packages (telnet, rsh)..."
if command -v apt >/dev/null 2>&1; then
  apt purge -y telnet rsh-client rsh-server inetutils-inetd || true
  apt autoremove -y || true
fi

# 7) Secure permissions for critical files
echo "[7/9] Locking down critical file permissions..."
chmod 600 /etc/shadow || true
chmod 600 /etc/ssh/sshd_config || true

# 8) Enable automatic security updates (unattended-upgrades)
echo "[8/9] Enabling unattended-upgrades (auto security updates)..."
if command -v apt >/dev/null 2>&1; then
  apt install -y unattended-upgrades apt-listchanges || true
  dpkg-reconfigure -plow unattended-upgrades || true
fi
