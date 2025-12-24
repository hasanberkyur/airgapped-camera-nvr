#!/usr/bin/env bash
set -euo pipefail

# Resets iptables to a clean slate (no persistence).
# WARNING: This will flush all iptables rules on the host.

if [[ $EUID -ne 0 ]]; then
  echo "Run as root: sudo $0"
  exit 1
fi

echo "[*] Flushing filter table..."
iptables -F
iptables -X

echo "[*] Flushing nat table..."
iptables -t nat -F
iptables -t nat -X

echo "[*] Flushing mangle table..."
iptables -t mangle -F
iptables -t mangle -X

echo "[*] Flushing raw table..."
iptables -t raw -F
iptables -t raw -X

echo "[*] Setting default policies to ACCEPT (safe for iterative setup)..."
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

echo "[+] Done. Current rules:"
iptables -S
