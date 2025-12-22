# Air-Gapped Home Camera NVR

## Overview

This project documents the design, implementation, and verification of an _air-gapped IP_ camera system using consumer hardware.
The goal was to build a camera setup that can be accessed locally and remotely without allowing the camera itself any internet access, and to verify this claim using packet-level analysis.

The project evolved iteratively as real-world constraints (hardware limitations, network topology, WAN restrictions) were discovered and addressed.

_(PHOTO OF THE SETUP)_

## Motivation

The project began with a practical question: How secure are consumer baby monitors and IP cameras in real-world deployments?

When my family considered purchasing a baby monitor, I wanted to understand whether such devices could be operated safely without exposing video streams or metadata to external cloud services. Rather than relying on vendor documentation, I decided to analyze this problem hands-on by building and testing a local camera system.

## Hardware Used

| Component        | Model / Details              | Role in Setup                          |
|------------------|------------------------------|----------------------------------------|
| Single-board PC  | Raspberry Pi 3               | NVR host, AP, firewall, VPN endpoint   |
| IP Camera        | Reolink E330 (RTSP-capable model) | Video source                      |
| Storage          | microSD card                 | OS, Docker, Frigate data               |
| USB WiFi Adapter | TP-Link TL-WN722N            | Isolated camera WLAN                   |
| Client Device    | Laptop / Phone               | Local & remote monitoring              |








```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Enable PCIe Gen 3 for Hailo (if using AI HAT)
sudo raspi-config nonint do_pcie_speed 3
```