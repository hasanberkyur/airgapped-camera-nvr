# Lessons Learned

This project started as a practical experiment to evaluate the security of consumer IP cameras and evolved into a deeper exploration of network isolation, firewall design, and remote access under real-world constraints. The following lessons summarize the most important technical and conceptual insights gained throughout the process.

---

## 1. Network Architecture Matters More Than Individual Tools

The strongest security guarantees in this project did not come from a specific firewall rule or software component, but from the overall network architecture. By placing the camera on a dedicated network and making the Raspberry Pi the sole enforcement point, security properties emerged naturally and remained robust even as components were changed.

This reinforced the idea that **architecture defines the security baseline**, while tools merely implement it.

---

## 2. Why Network Isolation Matters (Two Separate Networks)

The single most important security improvement in this project came from **isolating the camera into its own network** (CAMERA_LAN) and treating the Raspberry Pi as the only controlled boundary between networks. This separation reduces the “blast radius” of a compromised device: even if the camera firmware is buggy or malicious, it cannot laterally move into the home network or reach the internet.

Separating the setup into two networks also makes security easier to reason about. Instead of relying on vendor settings (cloud toggles, P2P options) or trusting default router behavior, isolation creates a clear trust boundary: the camera is an untrusted endpoint, the home network is trusted, and the Pi enforces the policy. This turns the problem from “Is the camera safe?” into “Can the camera physically and logically reach anything sensitive?”—which can be answered and enforced with deterministic network controls.

---

## 3. Egress Control Is as Important as Ingress Control

Before isolation, the camera attempted cloud communication, P2P connections, and vendor-specific discovery. Preventing inbound access alone would not have stopped these behaviors.

By removing the camera’s ability to resolve DNS and reach a default gateway, outbound communication effectively disappeared. This demonstrated that **controlling where a device can talk to is often more important than controlling who can talk to it**.

---

## 4. Blocking DNS Can Be a Powerful Control

Once DNS access was restricted, the camera could no longer bootstrap cloud or peer-to-peer services. As a result, no public IP traffic was observed at all.

This showed that higher-level services often depend on a small number of foundational network capabilities, and that selectively removing those capabilities can have a large security impact without complex filtering.

---

## 5. NAT Traversal Changes the Threat Model for Remote Access

Traditional VPN setups rely on inbound WAN access and port forwarding, which increases the exposed attack surface. Using an outbound-only VPN model demonstrated how remote access can be achieved without weakening the default-deny behavior of NAT and firewalls.

This clarified the difference between *being reachable* and *being accessible*, and why outbound-initiated tunnels are often safer in residential environments.

---

## Closing Reflection

The most important outcome of this project was not a specific configuration, but a deeper understanding of how networking, firewalls, and real-world constraints interact. The project demonstrated that meaningful security improvements are achievable with commodity hardware when **design decisions** are intentional and grounded in first principles.
