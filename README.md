# Air-Gapped Home Camera NVR

## Overview

This project documents the design, implementation, and verification of an ==air-gapped== IP camera system using consumer hardware.
The goal was to build a camera setup that can be accessed locally and remotely without allowing the camera itself any internet access, and to verify this claim using packet-level analysis.

The project evolved iteratively as real-world constraints (hardware limitations, network topology, WAN restrictions) were discovered and addressed.

==(PHOTO OF THE SETUP)==

## Motivation

The project began with a practical question: How secure are consumer baby monitors and IP cameras in real-world deployments?

When my family considered purchasing a baby monitor, I wanted to understand whether such devices could be operated safely without exposing video streams or metadata to external cloud services. Rather than relying on vendor documentation, I decided to analyze this problem hands-on by building and testing a local camera system.