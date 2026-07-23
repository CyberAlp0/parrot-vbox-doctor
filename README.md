# 🦜 Parrot VM Toolkit

**Comprehensive verification and optimization toolkit for Parrot Security OS & Kali Linux VirtualBox VMs**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/Platform-Linux-blue.svg)](https://www.parrotsec.org/)
[![VirtualBox](https://img.shields.io/badge/VirtualBox-6.x%20|%207.x-orange.svg)](https://www.virtualbox.org/)

---

## 📖 Overview

Setting up a penetration testing VM in VirtualBox comes with many challenges: clipboard not working, slow performance, display issues, and more. This toolkit automates the detection and fixing of these common issues.

> ℹ️ **How it works:** The main script (`parrot_vm_check_v2.sh`) only **inspects and reports** — it never changes your system. To apply fixes, you separately run the generated optimizer (`sudo bash /tmp/parrot_optimize.sh`) and choose exactly what to apply from its menu. Nothing is disabled or stopped without your explicit choice.

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
║                       CyberSkii                                   ║
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
  1) Disable unnecessary startup services (incl. plymouth boot splash)
  2) Optimize system settings (swappiness, cache, GRUB boot timeout)
  3) Install preload (faster app launching)
  4) Install lighter browser (Chromium)
  5) Disable KDE desktop effects
  6) Disable tracker / Baloo file indexer
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
sudo systemctl disable apt-daily-upgrade lm-sensors

# Mask the boot splash (often the single biggest offender, 15-35s)
sudo systemctl mask plymouth-quit-wait.service plymouth.service

# Skip the GRUB menu countdown
sudo sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' /etc/default/grub && sudo update-grub
```

> See the full [Boot Optimization](#-boot-optimization-faster-virtualbox-startup) section below for the complete walkthrough, or just run the generated optimizer (`sudo bash /tmp/parrot_optimize.sh`) which applies all of this for you.

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

## 🚀 Boot Optimization (Faster VirtualBox Startup)

A slow-booting VM is the most common complaint when running Parrot OS (or Kali) inside VirtualBox. Boot times of **3+ minutes** are usually caused by a handful of unnecessary services, the GRUB menu countdown, and the boot splash animation. The steps below cut that down to roughly **1 minute or less**.

> 💡 The verification script detects these issues automatically, and the generated optimizer (`sudo bash /tmp/parrot_optimize.sh`) applies every fix in this section for you. This guide documents what it does so you can also do it by hand.

### Step 1 — Diagnose

```bash
# Total boot time (kernel + userspace split)
systemd-analyze

# Top 20 slowest services during boot
systemd-analyze blame | head -20
```

### Step 2 — Disable / Mask Slow Services

These services commonly waste boot time and are **not required** for a pentesting VM:

| Service | What It Does | Why You Don't Need It |
|---------|--------------|-----------------------|
| `plymouth-quit-wait.service` | Boot splash animation | Cosmetic only — often wastes 15–35s |
| `apt-daily-upgrade.service` | Auto package upgrades on boot | Run updates manually instead |
| `samba-ad-dc.service` | Samba AD domain controller | Not needed unless running AD |
| `isc-dhcp-server.service` | DHCP server daemon | Not needed unless serving DHCP |
| `cpupower-gui.service` | CPU frequency scaling GUI | Unnecessary in a VM |
| `cpupower-gui-helper.service` | Helper for the CPU frequency GUI | Unnecessary in a VM |
| `lm-sensors.service` | Hardware temperature sensors | Sensors don't work in VMs |
| `ptunnel.service` | ICMP tunneling | Only needed during specific engagements |

```bash
sudo systemctl disable apt-daily-upgrade.service samba-ad-dc.service \
    isc-dhcp-server.service cpupower-gui.service cpupower-gui-helper.service \
    lm-sensors.service ptunnel.service
```

If `plymouth-quit-wait` still appears in `systemd-analyze blame` after disabling, **mask** it — this is stronger than `disable` and prevents it starting even when another unit depends on it:

```bash
sudo systemctl mask plymouth-quit-wait.service plymouth.service
```

### Step 3 — Reduce the GRUB Timeout

By default GRUB pauses several seconds at the boot menu. Set it to zero:

```bash
sudo sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' /etc/default/grub
sudo update-grub
```

### Step 4 — Optimize VirtualBox VM Settings

Power off the VM and adjust these in **VirtualBox → Settings**:

- **Display:** Graphics Controller → **VBoxSVGA**, Video Memory → **128 MB**, enable **3D Acceleration**
- **Processor:** at least **2 CPUs** (4 if the host allows), enable **PAE/NX**
- **Memory:** at least **4 GB RAM** (8 GB recommended)
- **Storage:** put the VM disk on an **SSD**; prefer a **fixed-size** disk over dynamically allocated (faster I/O)
- **System → Boot:** uncheck **Enable EFI** (BIOS boot is faster for VMs)

### Step 5 — Install Guest Additions

Improves display performance, enables shared clipboard, and fixes display-driver issues:

```bash
sudo apt update
sudo apt install -y virtualbox-guest-x11 virtualbox-guest-utils virtualbox-guest-dkms
sudo reboot
```

### Step 6 — Reduce Swap & Disable Desktop Extras

```bash
# Use RAM more, swap less (make permanent via /etc/sysctl.conf)
sudo sysctl vm.swappiness=10
echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf

# KDE editions: disable the Baloo file indexer
balooctl disable

# XFCE editions: stop the screensaver/power manager from hanging an idle VM
xfce4-screensaver-command --disable
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/dpms-enabled -s false
```

### Fixing the `vmwgfx` Display Error

If you see this during boot:

```
vmwgfx: seems to be running on an unsupported hypervisor
vmwgfx: This configuration is likely broken
```

The VMware graphics driver (`vmwgfx`) is loaded while you're on VirtualBox. Fix it by setting the Graphics Controller to **VBoxSVGA** in the VM's Display settings.

### Expected Results

| Stage | Before | After |
|-------|--------|-------|
| Total Boot Time | ~3 min 20 s | ~1 min or less |
| Userspace | ~2 min 50 s | ~45 s |
| Top Offenders | 8+ unnecessary services | Only essential services remain |

### ⚠️ Services to KEEP (do not disable)

- `vboxadd.service` — VirtualBox Guest Additions
- `NetworkManager.service` — Network connectivity
- `systemd-modules-load.service` — Kernel modules
- `lightdm.service` / `sddm.service` — Desktop login manager
- `systemd-journald.service` — System logging
- `dbus.service` — Inter-process communication

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

**CyberSkii** — Cybersecurity Community

- Website: [cyberskii.com](https://cyberskii.com)
- GitHub: [@CyberAlp0](https://github.com/CyberAlp0)

---

## ⭐ Support

If this toolkit helped you, please consider:

- ⭐ Starring this repository
- 🐛 Reporting issues you encounter
- 📢 Sharing with others in the infosec community

---

## 📜 Changelog

### v2.1 (2025)
- Added a dedicated **Boot Optimization** guide for faster VirtualBox startup
- Detect more boot-slowing services (plymouth, apt-daily-upgrade, samba-ad-dc, isc-dhcp-server, cpupower-gui, lm-sensors, ptunnel)
- Optimizer now **masks** the Plymouth boot splash (the most common offender)
- Optimizer now reduces the **GRUB boot menu timeout** to 0
- Optimizer now disables the **Baloo** file indexer on KDE editions

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
