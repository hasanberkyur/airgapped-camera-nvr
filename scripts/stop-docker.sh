#!/usr/bin/env bash
set -euo pipefail

# Stops Docker and disables it to prevent it from injecting iptables rules.

if [[ $EUID -ne 0 ]]; then
  echo "Run as root: sudo $0"
  exit 1
fi

echo "[*] Stopping Docker..."
systemctl stop docker.service docker.socket || true

echo "[*] Disabling Docker autostart..."
systemctl disable docker.service docker.socket || true

echo "[+] Docker status:"
systemctl status docker.service docker.socket --no-pager || true
