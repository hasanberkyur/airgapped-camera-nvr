# Air-Gapped Home Camera NVR

## Overview

This project documents the design, implementation, and verification of an _air-gapped IP_ camera system using consumer hardware.
The goal was to build a camera setup that can be accessed locally and remotely without allowing the camera itself any internet access, and to verify this claim using packet-level analysis.

The project evolved iteratively as real-world constraints (hardware limitations, network topology, WAN restrictions) were discovered and addressed.

_(PHOTO OF THE iLAB like SETUP)_

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

_(PHOTO OF THE HARDWARE)_

## Initial Setup

I began by performing the initial camera setup using the official Reolink mobile application. After connecting to the camera via Bluetooth, I set an administrator password and joined the camera to my home wireless network.

Once the camera was online, I identified its assigned IP address through the router’s management interface and applied a basic access control rule. This rule prevented unrestricted outbound routing from the IP camera to the internet, limiting its network communication from the start.

With this in place, I verified local access by connecting to the camera stream via RTSP from the Raspberry Pi, which was also connected to the same network. Using **ffmpeg**, I successfully recorded a short video segment directly from the camera stream:


```bash
# Record a short RTSP stream segment and save it locally
ffmpeg -rtsp_transport tcp \ # Force TCP transport
        -i "rtsp://admin:PASSWORD@CAMERA_IP:554/h264Preview_01_main" \ # Connected using the password I set before
        -t 10 -c copy test.mp4
```

This confirmed that the camera could be accessed and used locally without any mandatory cloud dependency.

## NVR Deployment & Video Processing using **Frigate**

In this project I used Frigate, which is an open-source, real-time Network Video Recorder (NVR) designed for IP cameras that processes RTSP video streams locally and supports object detection using hardware-accelerated or CPU-based inference. It enables users to record, restream, and analyze camera feeds without relying on cloud services, making it well-suited for privacy-focused and air-gapped camera deployments.

I deployed Frigate inside a Docker container using the provided [docker-compose.yml](configs/docker/docker-compose.yml)

After starting the container, I configured Frigate using [config/config.yaml](configs/frigate/config.yaml), referencing the official [full configuration reference](https://docs.frigate.video/configuration/reference). In addition, I followed Frigate’s [camera-spesific configuration guide](https://docs.frigate.video/configuration/camera_specific/#reolink-cameras), which proved especially helpful for achieving stable RTSP streaming and optimal compatibility. 

I experimented with several AI-based detection features, such as automatically starting a recording when the camera detected a book or when audio events (e.g., a baby crying) were recognized. While these features worked as expected, I observed that AI detection placed a significant load on the system, as Frigate was running on a Raspberry Pi with limited CPU resources.

After reviewing Frigate’s documentation, I learned that hardware acceleration could be added using the [**Raspberry Pi AI HAT+**](https://www.raspberrypi.com/products/ai-hat/), which includes a dedicated neural network accelerator. This hardware enables full use of Frigate’s advanced features, including object detection, audio detection, semantic search, generative AI capabilities, face recognition, and license plate recognition.

![Frigate detecting book and starts recording](docs/images/frigate-book-detection.gif)

![Frigate detecting book](docs/images/frigate-detect-cpu.png)

However, since the primary goal of this project was to design and verify a secure, air-gapped camera architecture rather than to build an AI-focused NVR, I decided to disable AI-based detection and continue with a lightweight, resource-efficient configuration.

_(PHOTO OF THE WEB INTERFACE)_

## Problems with the Home Network

During testing, I noticed a significant degradation in my home wireless network performance. General internet usage became unreliable, and in some cases I was unable to browse the web over WLAN from my laptop. Although I did not initially identify a single root cause, it became clear that continuous camera streaming was congesting the shared wireless network.

To address this, I decided to fully isolate the camera’s network traffic. I connected an external USB Wi-Fi adapter (TP-Link TL-WN722N) to the Raspberry Pi and configured it as a dedicated access point using [hostapd]() and [dnsmasq]().

- **wlan1**: configured as an access point
- **wlan0**: remained connected to the home network

The camera was moved onto this isolated WLAN, named CAMERA_LAN. This separation ensured predictable bandwidth for the camera stream and eliminated interference with unrelated network traffic on the home network.



yurt wifi inin yavasladigini fark ettim, bu yüzden pi3 e AP kurulumu yaptim 
birkaç optimizasyon ile LANda en kaliteli sekilde frigate kullanabiliyordum 
uzaktan güvenli erisim icin pi3 e wireguard kurdum, WAN ddad oldugum icin ulasamadigimi fark ettim 
Tailscale kullanmaya karar verdim 
en son güvenlik denemeleri yaptim, iptables kullandim, tcpdumtan trafigi analiz ettim


air-gapped-home-camera/
├─ README.md
├─ docs/
│  ├─ architecture.md
│  ├─ threat-model.md
│  ├─ verification.md
│  ├─ lessons-learned.md
│  ├─ images/
│  └─ diagrams/
├─ configs/
│  ├─ frigate/
│  ├─ go2rtc/
│  ├─ hostapd/
│  ├─ dnsmasq/
│  └─ firewall/
├─ scripts/
│  ├─ capture.sh
│  ├─ verify-no-wan.sh
│  └─ sanitize.sh
├─ evidence/
│  ├─ pcaps/              (sanitized)
│  ├─ logs/               (sanitized)
│  └─ screenshots/
├─ .gitignore
├─ LICENSE
└─ SECURITY.md




```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Enable PCIe Gen 3 for Hailo (if using AI HAT)
sudo raspi-config nonint do_pcie_speed 3
```