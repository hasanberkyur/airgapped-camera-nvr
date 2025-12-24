#!/usr/bin/env bash
set -euo pipefail

# Re-enables and starts Docker again (after firewall work).

if [[ $EUID -ne 0 ]]; then
  echo "Run as root: sudo $0"
  exit 1
fi

echo "[*] Enabling Docker autostart..."
systemctl enable docker.service docker.socket || true

echo "[*] Starting Docker..."
systemctl start docker.service docker.socket || true

echo "[+] Docker status:"
systemctl status docker.service docker.socket --no-pager || true
