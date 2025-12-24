#!/usr/bin/env bash
set -euo pipefail

IF_CAMERA="${IF_CAMERA:-wlan1}"
IF_HOME="${IF_HOME:-wlan0}"
CAMERA_IP="${CAMERA_IP:-}"
CAMERA_SUBNET="${CAMERA_SUBNET:-}"

PCAP_WLAN1="${PCAP_WLAN1:-wlan1_camera_attempts.pcap}"
PCAP_WLAN0="${PCAP_WLAN0:-wlan0_camera_egress.pcap}"

if [[ $EUID -ne 0 ]]; then
  echo "Run as root: sudo $0"
  exit 1
fi

if [[ -z "$CAMERA_IP" ]]; then
  echo "Set CAMERA_IP, e.g.: sudo CAMERA_IP=192.168.30.123 $0"
  exit 1
fi

echo "[*] Starting dual capture..."
echo "    CAMERA_IP=$CAMERA_IP"
echo "    IF_CAMERA=$IF_CAMERA -> $PCAP_WLAN1"
echo "    IF_HOME=$IF_HOME -> $PCAP_WLAN0"

# Capture egress attempts seen on CAMERA_LAN (dest outside camera subnet)
tcpdump -i "$IF_CAMERA" -nn -s0 \
  "src $CAMERA_IP and not dst net $CAMERA_SUBNET" \
  -w "$PCAP_WLAN1" &
PID1=$!

# Capture anything from the camera that reaches uplink (should be empty)
tcpdump -i "$IF_HOME" -nn -s0 \
  "src $CAMERA_IP" \
  -w "$PCAP_WLAN0" &
PID2=$!

cleanup() {
  echo "[*] Stopping captures..."
  kill "$PID1" "$PID2" 2>/dev/null || true
  wait "$PID1" "$PID2" 2>/dev/null || true
  echo "[+] Saved: $PCAP_WLAN1 and $PCAP_WLAN0"
}
trap cleanup INT TERM

wait "$PID1" "$PID2"
