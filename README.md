# 🦜 Parrot VM Toolkit

**Comprehensive verification and optimization toolkit for Parrot Security OS & Kali Linux VirtualBox VMs**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/Platform-Linux-blue.svg)](https://www.parrotsec.org/)
[![VirtualBox](https://img.shields.io/badge/VirtualBox-6.x%20|%207.x-orange.svg)](https://www.virtualbox.org/)

---

## 📖 Overview

Setting up a penetration testing VM in VirtualBox comes with many challenges: clipboard not working, slow performance, display issues, and more. This toolkit automates the detection and fixing of these common issues.

### Features

✅ **17+ System Checks** — Guest Additions, clipboard, graphics, performance, and more  
✅ **Automatic Issue Detection** — Identifies problems and their severity  
✅ **Fix Commands Provided** — Copy-paste solutions for every issue  
✅ **Performance Optimization** — Reduce boot time and improve responsiveness  
✅ **Interactive Optimizer** — Menu-driven optimization script  
✅ **Wayland Detection** — Identifies the #1 cause of VirtualBox issues  

---

## 🚀 Quick Start

### One-Liner Installation & Run

```bash
wget -O parrot_vm_check.sh https://raw.githubusercontent.com/yourusername/parrot-vm-toolkit/main/parrot_vm_check_v2.sh && chmod +x parrot_vm_check.sh && sudo ./parrot_vm_check.sh
```

### Manual Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/parrot-vm-toolkit.git
cd parrot-vm-toolkit

# Make scripts executable
chmod +x parrot_vm_check_v2.sh

# Run the verification script
sudo ./parrot_vm_check_v2.sh
```

---

## 📋 What It Checks

| Category | Checks Performed |
|----------|-----------------|
| **System Info** | OS version, kernel, VM detection |
| **Desktop Session** | KDE/GNOME, X11 vs Wayland detection |
| **Guest Additions** | Kernel modules, VBoxService, VBoxClient |
| **Clipboard** | Service status, bidirectional functionality |
| **Drag & Drop** | Service status, common issues |
| **Graphics** | 3D acceleration, resolution, drivers |
| **CPU** | Cores allocated, usage, features (PAE/NX) |
| **Memory** | RAM allocation, swap usage, availability |
| **Storage** | Disk space, I/O performance |
| **Network** | Connectivity, DNS resolution |
| **Shared Folders** | vboxsf module, user permissions |
| **Boot Time** | Duration analysis, slow services |
| **Startup Services** | Optional services that can be disabled |
| **Performance** | Swappiness, preload, tracker, KDE effects |
| **Browsers** | Installed browsers, resource usage |
| **System Logs** | VirtualBox errors, Guest Additions logs |

---

## 📊 Sample Output

```
╔═══════════════════════════════════════════════════════════════════╗
║     🦜 Parrot OS VirtualBox Verification Suite v2.0 🦜           ║
║                      Lambda Tech                                  ║
╚═══════════════════════════════════════════════════════════════════╝

┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃  3. VIRTUALBOX GUEST ADDITIONS
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

  [Kernel Modules]
  [✓ PASS] vboxguest module loaded (Core Guest Additions) - v7.0.18
  [✓ PASS] vboxsf module loaded (Shared Folders support)
  [✓ PASS] vboxvideo module loaded (Video driver)

  [VBoxClient Features]
  [✓ PASS] VBoxClient --clipboard is running
  [✓ PASS] VBoxClient --draganddrop is running
  [✓ PASS] VBoxClient --seamless is running
  [✓ PASS] VBoxClient --vmsvga is running

  ► Guest Additions Status: INSTALLED & RUNNING

📊 VERIFICATION SUMMARY

  Passed:   42
  Warnings: 3
  Failed:   0
  Issues:   2

  ╔═══════════════════════════════════════════════════════════════╗
  ║  ⚠ VM is functional but has some issues - review fixes above ║
  ╚═══════════════════════════════════════════════════════════════╝
```

---

## 🔧 Generated Scripts

The main script generates additional helper scripts:

### 1. Auto-Fix Script (`/tmp/parrot_autofix.sh`)

Automatically applies fixes for detected issues:

```bash
sudo bash /tmp/parrot_autofix.sh
```

### 2. Optimization Script (`/tmp/parrot_optimize.sh`)

Interactive menu for performance optimization:

```bash
sudo bash /tmp/parrot_optimize.sh
```

**Menu Options:**
```
  1) Disable unnecessary startup services
  2) Optimize system settings (swappiness)
  3) Install preload (faster app launching)
  4) Install lighter browser (Chromium)
  5) Disable KDE desktop effects
  6) Disable tracker file indexer
  7) Clean system (apt cache, old packages)
  8) Clear RAM cache (temporary boost)
  9) Apply ALL optimizations
  0) Exit
```

---

## 🛠️ Common Issues & Quick Fixes

### Clipboard Not Working

```bash
# Check session type
echo $XDG_SESSION_TYPE

# If "wayland", switch to X11 at login screen

# Restart clipboard service
VBoxClient --clipboard &
```

### Slow Boot Time

```bash
# Disable slow services
sudo systemctl disable postgresql docker cups bluetooth
sudo systemctl disable NetworkManager-wait-online
```

### Poor Performance

```bash
# Reduce swappiness
echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Install preload
sudo apt install -y preload
```

### Guest Additions Not Working

```bash
# Reinstall Guest Additions
sudo apt install -y build-essential dkms linux-headers-$(uname -r)
# VirtualBox Menu: Devices → Insert Guest Additions CD
sudo mount /dev/cdrom /mnt/cdrom
sudo /mnt/cdrom/VBoxLinuxAdditions.run
sudo reboot
```

---

## 📚 Documentation

- [Full Blog Post](./docs/blog.md) — Detailed walkthrough of all issues and solutions
- [VirtualBox Settings Guide](./docs/virtualbox-settings.md) — Optimal VM configuration
- [Performance Tuning](./docs/performance.md) — Advanced optimization techniques

---

## 🖥️ Compatibility

### Tested On

| Distribution | Version | Status |
|--------------|---------|--------|
| Parrot Security OS | 7.1 KDE | ✅ Fully Tested |
| Parrot Security OS | 6.x | ✅ Compatible |
| Kali Linux | 2024.x | ✅ Compatible |
| Kali Linux | 2023.x | ✅ Compatible |
| Ubuntu | 22.04+ | ✅ Compatible |
| Debian | 11+ | ✅ Compatible |

### VirtualBox Versions

- VirtualBox 7.x — ✅ Recommended
- VirtualBox 6.x — ✅ Compatible

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👨‍💻 Author

**Lambda Tech** — Cybersecurity & AI Academy

- Website: [lambdatech.sa](https://lambdatech.sa)
- GitHub: [@lambdatech](https://github.com/lambdatech)

---

## ⭐ Support

If this toolkit helped you, please consider:

- ⭐ Starring this repository
- 🐛 Reporting issues you encounter
- 📢 Sharing with others in the infosec community

---

## 📜 Changelog

### v2.0 (2025)
- Added boot time analysis
- Added startup services check
- Added performance metrics (swappiness, preload, tracker)
- Added browser analysis
- Added comprehensive issues table
- Added optimization guide table
- Added auto-optimization script generator
- Improved Wayland detection
- Added quick commands reference table

### v1.0 (2025)
- Initial release
- Guest Additions verification
- Basic system checks
- Issue detection and fixes
