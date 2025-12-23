# Security Hardening & Verification
 
This document describes the security design decisions used to isolate an IP camera from the home network and the internet, while still allowing controlled local access and secure remote monitoring.

The focus of this document is **hardening by architecture** rather than operational verification. Packet-level verification and testing were performed during development but are intentionally not fully included here.

## Scope and Security Objectives

- The IP camera must have **no routable path to the internet**
- Camera traffic must be restricted to **RTSP access only**
- Security must not depend on camera firmware configuration
- Remote access must not expose inbound WAN services

## Network Overview

- **CAMERA_LAN:** `192.168.30.0/24`
- **Raspberry Pi interfaces:**
  - `wlan1`: Camera access point (CAMERA_LAN)
  - `wlan0`: Home network uplink (HOME_LAN)
  - `tailscale0`: Encrypted VPN interface
- **NVR:** Frigate running in Docker on Raspberry Pi
- **Remote access:** Tailscale (WireGuard-based) using SSO login

![Project setup](docs/images/network-diagram.png)

---

## 1. CAMERA_LAN Isolation

### Threat Model
Consumer IP cameras commonly attempt:
- Cloud registration
- Telemetry uploads
- DNS and UDP-based discovery

### Hardening Measures
- The camera is connected to a dedicated WLAN hosted by the Raspberry Pi
- The camera has no direct connectivity to the home router
- All camera traffic must traverse the Raspberry Pi

This establishes a single, auditable control point.

## 2. Explicit RTSP-Only Access to the Server

### Security Goal
The camera may communicate **only** for video streaming purposes and only with the local NVR.

### Threat Model
Consumer IP cameras can attempt:
- To communicate with other cameras or the Raspberry Pi server beyond video streaming
- To generate excessive or unnecessary traffic, potentially causing congestion within CAMERA_LAN

### Hardening Measures
Traffic from CAMERA_LAN is restricted to RTSP-related ports on the Raspberry Pi.  
All other traffic is implicitly disallowed by forwarding restrictions.

RTSP communication is limited to:
- TCP port `554` (RTSP)
- Locally exposed NVR ports as required by Frigate

No DNS, NTP, or generic outbound connectivity is permitted.

```bash
# Allow established and related connections
sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Allow RTSP traffic (dest port 554) from CAMERA_LAN to the Raspberry Pi
sudo iptables -A INPUT -i wlan1 -s 192.168.30.0/24 -p tcp --dport 554 -j ACCEPT

# Drop all other traffic originating from CAMERA_LAN
sudo iptables -A INPUT -i wlan1 -s 192.168.30.0/24 -j DROP
```

```bash
hasan@pi3:~ $ sudo iptables -L INPUT -v -n --line-numbers
Chain INPUT (policy ACCEPT 107 packets, 7645 bytes)
num   pkts bytes target     prot opt in     out     source               destination
1      129 11065 ACCEPT     all  --  *      *       0.0.0.0/0            0.0.0.0/0            ctstate RELATED,ESTABLISHED
2        0     0 ACCEPT     tcp  --  wlan1  *       192.168.30.0/24      0.0.0.0/0            tcp dpt:554
3        0     0 DROP       all  --  wlan1  *       192.168.30.0/24      0.0.0.0/0
```

This ensures that even if the camera firmware attempts non-video communication, those attempts cannot succeed.

## 3. Forwarding Boundary on the Raspberry Pi

### Threat Model
If the Raspberry Pi forwards packets indiscriminately:
- Camera traffic could reach the home network
- WAN access could be restored unintentionally

### Hardening Measures
The Raspberry Pi enforces a strict forwarding boundary between CAMERA_LAN and HOME_LAN.

An explicit iptables rule drops all forwarded packets originating from `wlan1` (CAMERA_LAN) toward `wlan0`:

```bash
# Drop all forwarded packets from CAMERA_LAN to HOME_LAN
sudo iptables -I FORWARD 1 -i wlan1 -o wlan0 -j DROP
```
```bash
hasan@pi3:~ $ sudo iptables -L FORWARD -v -n --line-numbers
Chain FORWARD (policy ACCEPT 26 packets, 2424 bytes)
num   pkts bytes target     prot opt in     out     source               destination
1    41727   28M DOCKER-USER  all  --  *      *       0.0.0.0/0            0.0.0.0/0
2    41727   28M DOCKER-FORWARD  all  --  *      *       0.0.0.0/0            0.0.0.0/0
3       27  3132 DROP       all  --  wlan1  wlan0   0.0.0.0/0            0.0.0.0/0
```
**Note**: It is important to note that the first two Docker-related rules do not shadow the third rule added above.

## 5. Secure Remote Access via VPN

### Threat Model
Traditional VPN servers require inbound WAN access, which:
- Is not feasible under carrier-grade NAT
- Increases the attack surface

### Hardening Measures
Remote access is provided using Tailscale:
- The Raspberry Pi initiates outbound encrypted WireGuard connections
- NAT state is created by outbound traffic
- No inbound ports are exposed
- VPN traffic is isolated from CAMERA_LAN
- The camera never gains access to the VPN interface and cannot use it as an outgoing path.