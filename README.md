# 🌐 speedtest.sh

A lightweight internet speed test that runs entirely from a single bash script. No installation, no Python, and no heavy dependencies—just pure `curl`.

---

## 🚀 Quick Start

Run it instantly without cloning:

```bash

curl -sL https://raw.githubusercontent.com/knightfury16/speedtest/refs/heads/master/speedtest.sh | bash

```

Or, if you prefer the traditional way:

```bash
git clone https://github.com/knightfury16/speedtest.git
cd speedtest

# Default (Cloudflare Anycast). Testing local speed similar to fast.com
bash ./speedtest.sh

# Global Test (Tele2 Sweden). Testing the long distance hop speed.
bash ./speedtest.sh global

# Help
bash ./speedtest.sh -h

```

---

## 🛠️ How it Works

| Feature | Method |
| --- | --- |
| **Ping** | TCP connect time to Google |
| **Download** | Fetches a 10 MB file from Tele2 |
| **Upload** | Sends a 2 MB payload to httpbin.org |
| **IP & Info** | Queries ipinfo.io for ISP and location |

> [!NOTE]
> Results are automatically scaled to human-readable units (**Kbps**, **Mbps**, or **Gbps**) based on your connection speed.

---

## 📋 Requirements

This script is designed to run on almost any Unix-like system (Linux, macOS, WSL) using tools you already have:

* `curl`
* `awk`
* `dd`

---
