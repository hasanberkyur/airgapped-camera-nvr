#!/usr/bin/env bash
set -euo pipefail

IF_CAMERA="${IF_CAMERA:-wlan1}"
PCAP="${PCAP:-camera_wlan1.pcap}"
CAMERA_IP="${CAMERA_IP:-}"

if [[ $EUID -ne 0 ]]; then
  echo "Run as root: sudo $0"
  exit 1
fi

echo "[*] Capturing on $IF_CAMERA -> $PCAP"
if [[ -n "$CAMERA_IP" ]]; then
  echo "    Filter: host $CAMERA_IP"
  tcpdump -i "$IF_CAMERA" -nn -s0 "host $CAMERA_IP" -w "$PCAP"
else
  echo "    Filter: (none)"
  tcpdump -i "$IF_CAMERA" -nn -s0 -w "$PCAP"
fi
