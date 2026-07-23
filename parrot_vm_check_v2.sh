#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════
# Parrot OS VirtualBox Installation & Performance Verifier
# Version: 2.0
# Author: CyberSkii
# Description: Comprehensive verification of Parrot OS VM installation,
#              Guest Additions, performance, and automatic issue detection
#              with step-by-step fix suggestions
# ═══════════════════════════════════════════════════════════════════════════

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m'
BOLD='\033[1m'

# Counters
PASS=0
WARN=0
FAIL=0
ISSUES=()

# ═══════════════════════════════════════════════════════════════════════════
# HELPER FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════

banner() {
    clear
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════════════════════╗"
    echo "║                                                                   ║"
    echo "║     🦜 Parrot OS VirtualBox Verification Suite v2.0 🦜           ║"
    echo "║                       CyberSkii                                   ║"
    echo "║                                                                   ║"
    echo "╚═══════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
}

section() {
    echo ""
    echo -e "${BOLD}${MAGENTA}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
    echo -e "${BOLD}${MAGENTA}┃  $1${NC}"
    echo -e "${BOLD}${MAGENTA}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
}

check_pass() {
    echo -e "  ${GREEN}[✓ PASS]${NC} $1"
    ((PASS++))
}

check_warn() {
    echo -e "  ${YELLOW}[⚠ WARN]${NC} $1"
    ((WARN++))
}

check_fail() {
    echo -e "  ${RED}[✗ FAIL]${NC} $1"
    ((FAIL++))
}

info() {
    echo -e "  ${CYAN}[INFO]${NC} $1"
}

add_issue() {
    ISSUES+=("$1")
}

# ═══════════════════════════════════════════════════════════════════════════
# 1. SYSTEM INFORMATION
# ═══════════════════════════════════════════════════════════════════════════
check_system_info() {
    section "1. SYSTEM INFORMATION"
    
    info "Hostname: $(hostname)"
    info "Kernel: $(uname -r)"
    info "Architecture: $(uname -m)"
    
    if [ -f /etc/os-release ]; then
        OS_NAME=$(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)
        info "OS: ${OS_NAME}"
    fi
    
    # Check if running in VirtualBox
    VIRT_TYPE=$(systemd-detect-virt 2>/dev/null)
    if echo "$VIRT_TYPE" | grep -qi "oracle\|virtualbox"; then
        check_pass "Running inside VirtualBox VM (${VIRT_TYPE})"
    elif lspci 2>/dev/null | grep -qi "virtualbox"; then
        check_pass "Running inside VirtualBox VM (detected via PCI)"
    else
        check_warn "Could not confirm VirtualBox environment (detected: ${VIRT_TYPE})"
    fi
    
    # Uptime
    UPTIME=$(uptime -p 2>/dev/null || uptime)
    info "Uptime: ${UPTIME}"
}

# ═══════════════════════════════════════════════════════════════════════════
# 2. DESKTOP ENVIRONMENT & SESSION TYPE
# ═══════════════════════════════════════════════════════════════════════════
check_desktop_session() {
    section "2. DESKTOP ENVIRONMENT & SESSION TYPE"
    
    # Detect Desktop Environment
    DE="Unknown"
    if [ -n "$XDG_CURRENT_DESKTOP" ]; then
        DE="$XDG_CURRENT_DESKTOP"
    elif [ -n "$DESKTOP_SESSION" ]; then
        DE="$DESKTOP_SESSION"
    fi
    info "Desktop Environment: ${DE}"
    
    # Check Session Type (Critical for clipboard/drag-drop)
    SESSION_TYPE="${XDG_SESSION_TYPE:-unknown}"
    info "Session Type: ${SESSION_TYPE}"
    
    if [ "$SESSION_TYPE" == "x11" ]; then
        check_pass "Running on X11 session (Best compatibility with VirtualBox)"
    elif [ "$SESSION_TYPE" == "wayland" ]; then
        check_fail "Running on Wayland session (VirtualBox features may not work!)"
        add_issue "WAYLAND_SESSION"
        echo ""
        echo -e "  ${RED}╔════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "  ${RED}║  ⚠️  WAYLAND DETECTED - This causes clipboard/drag-drop issues ║${NC}"
        echo -e "  ${RED}╚════════════════════════════════════════════════════════════════╝${NC}"
    else
        check_warn "Could not determine session type: ${SESSION_TYPE}"
    fi
    
    # Display server info
    if [ -n "$DISPLAY" ]; then
        info "DISPLAY variable: ${DISPLAY}"
    fi
    
    if [ -n "$WAYLAND_DISPLAY" ]; then
        info "WAYLAND_DISPLAY: ${WAYLAND_DISPLAY}"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
# 3. VIRTUALBOX GUEST ADDITIONS - COMPREHENSIVE CHECK
# ═══════════════════════════════════════════════════════════════════════════
check_guest_additions() {
    section "3. VIRTUALBOX GUEST ADDITIONS"
    
    GA_INSTALLED=true
    
    # Check kernel modules
    echo -e "\n  ${WHITE}[Kernel Modules]${NC}"
    
    if lsmod | grep -q "vboxguest"; then
        VBOXGUEST_VER=$(modinfo vboxguest 2>/dev/null | grep "^version:" | awk '{print $2}')
        check_pass "vboxguest module loaded (Core Guest Additions) - v${VBOXGUEST_VER}"
    else
        check_fail "vboxguest module NOT loaded"
        GA_INSTALLED=false
        add_issue "VBOXGUEST_MISSING"
    fi
    
    if lsmod | grep -q "vboxsf"; then
        check_pass "vboxsf module loaded (Shared Folders support)"
    else
        check_warn "vboxsf module not loaded (Shared Folders won't work)"
        add_issue "VBOXSF_MISSING"
    fi
    
    if lsmod | grep -q "vboxvideo"; then
        check_pass "vboxvideo module loaded (Video driver)"
    else
        check_warn "vboxvideo module not loaded (using alternative driver)"
    fi
    
    # Check VBoxControl
    echo -e "\n  ${WHITE}[Guest Additions Version]${NC}"
    
    if command -v VBoxControl &> /dev/null; then
        GA_VERSION=$(VBoxControl --version 2>/dev/null | head -1)
        check_pass "VBoxControl available - Version: ${GA_VERSION}"
    else
        check_fail "VBoxControl not found - Guest Additions may not be installed"
        GA_INSTALLED=false
        add_issue "GUEST_ADDITIONS_NOT_INSTALLED"
    fi
    
    # Check VBoxService
    echo -e "\n  ${WHITE}[VirtualBox Services]${NC}"
    
    if pgrep -x "VBoxService" > /dev/null; then
        check_pass "VBoxService is running"
    else
        check_fail "VBoxService NOT running"
        add_issue "VBOXSERVICE_NOT_RUNNING"
    fi
    
    # Check systemd service
    if systemctl is-active vboxadd-service &>/dev/null; then
        check_pass "vboxadd-service is active"
    else
        check_warn "vboxadd-service is not active"
    fi
    
    # Check VBoxClient processes
    echo -e "\n  ${WHITE}[VBoxClient Features]${NC}"
    
    VBOXCLIENT_FEATURES=("clipboard" "draganddrop" "seamless" "vmsvga")
    
    for feature in "${VBOXCLIENT_FEATURES[@]}"; do
        if pgrep -fa "VBoxClient.*--${feature}" > /dev/null; then
            check_pass "VBoxClient --${feature} is running"
        else
            check_fail "VBoxClient --${feature} is NOT running"
            add_issue "VBOXCLIENT_${feature^^}_MISSING"
        fi
    done
    
    # Overall Guest Additions status
    echo ""
    if [ "$GA_INSTALLED" = true ] && pgrep -x "VBoxService" > /dev/null; then
        echo -e "  ${GREEN}${BOLD}► Guest Additions Status: INSTALLED & RUNNING${NC}"
    else
        echo -e "  ${RED}${BOLD}► Guest Additions Status: ISSUES DETECTED${NC}"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
# 4. CLIPBOARD & DRAG-DROP FUNCTIONALITY
# ═══════════════════════════════════════════════════════════════════════════
check_clipboard_dragdrop() {
    section "4. CLIPBOARD & DRAG-DROP FUNCTIONALITY"
    
    CLIPBOARD_OK=true
    DRAGDROP_OK=true
    
    # Check clipboard service
    if pgrep -fa "VBoxClient.*--clipboard" > /dev/null; then
        check_pass "Clipboard service is running"
    else
        check_fail "Clipboard service is NOT running"
        CLIPBOARD_OK=false
        add_issue "CLIPBOARD_NOT_RUNNING"
    fi
    
    # Check drag-drop service
    if pgrep -fa "VBoxClient.*--draganddrop" > /dev/null; then
        check_pass "Drag and Drop service is running"
    else
        check_fail "Drag and Drop service is NOT running"
        DRAGDROP_OK=false
        add_issue "DRAGDROP_NOT_RUNNING"
    fi
    
    # Check for Wayland (common cause of clipboard issues)
    if [ "$XDG_SESSION_TYPE" == "wayland" ]; then
        check_fail "Wayland session detected - Clipboard/Drag-Drop may not work!"
        CLIPBOARD_OK=false
        DRAGDROP_OK=false
    fi
    
    # Check spice-vdagent (alternative clipboard tool)
    if command -v spice-vdagent &> /dev/null; then
        if systemctl is-active spice-vdagentd &>/dev/null; then
            check_pass "spice-vdagent is installed and running (backup clipboard)"
        else
            info "spice-vdagent is installed but not running"
        fi
    else
        info "spice-vdagent not installed (optional backup clipboard tool)"
    fi
    
    # Summary
    echo ""
    if [ "$CLIPBOARD_OK" = true ]; then
        echo -e "  ${GREEN}► Clipboard: Should be working (test with Ctrl+C/Ctrl+Shift+V)${NC}"
    else
        echo -e "  ${RED}► Clipboard: Issues detected - see fixes below${NC}"
    fi
    
    if [ "$DRAGDROP_OK" = true ]; then
        echo -e "  ${GREEN}► Drag-Drop: Service running (Note: Can be buggy in VirtualBox)${NC}"
    else
        echo -e "  ${RED}► Drag-Drop: Issues detected - see fixes below${NC}"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
# 5. GRAPHICS & DISPLAY CONFIGURATION
# ═══════════════════════════════════════════════════════════════════════════
check_graphics() {
    section "5. GRAPHICS & DISPLAY CONFIGURATION"
    
    # Check video driver
    echo -e "\n  ${WHITE}[Video Driver]${NC}"
    
    if lspci -k 2>/dev/null | grep -A 3 "VGA" | grep -qi "vboxvideo\|vmwgfx\|virtio"; then
        DRIVER=$(lspci -k 2>/dev/null | grep -A 3 "VGA" | grep "Kernel driver" | awk '{print $NF}')
        check_pass "Video driver loaded: ${DRIVER}"
    else
        VGA_INFO=$(lspci 2>/dev/null | grep -i "VGA")
        info "VGA Controller: ${VGA_INFO}"
    fi
    
    # Check resolution
    echo -e "\n  ${WHITE}[Display Resolution]${NC}"
    
    if command -v xrandr &> /dev/null && [ -n "$DISPLAY" ]; then
        RESOLUTION=$(xrandr 2>/dev/null | grep "*" | awk '{print $1}' | head -1)
        if [ -n "$RESOLUTION" ]; then
            check_pass "Current Resolution: ${RESOLUTION}"
            
            # Check if resolution is reasonable
            RES_WIDTH=$(echo $RESOLUTION | cut -d'x' -f1)
            if [ "$RES_WIDTH" -lt 1024 ]; then
                check_warn "Resolution seems low - consider increasing"
            fi
        else
            check_warn "Could not detect resolution"
        fi
        
        # List available resolutions
        info "Available resolutions:"
        xrandr 2>/dev/null | grep -E "^\s+[0-9]+" | head -5 | while read line; do
            echo "       $line"
        done
    else
        check_warn "Cannot detect resolution (xrandr not available or no DISPLAY)"
    fi
    
    # Check 3D acceleration
    echo -e "\n  ${WHITE}[3D Acceleration]${NC}"
    
    if command -v glxinfo &> /dev/null; then
        if glxinfo 2>/dev/null | grep -q "direct rendering: Yes"; then
            check_pass "3D Acceleration: Enabled (Direct Rendering: Yes)"
            
            # Get OpenGL info
            GL_VENDOR=$(glxinfo 2>/dev/null | grep "OpenGL vendor" | cut -d':' -f2 | xargs)
            GL_RENDERER=$(glxinfo 2>/dev/null | grep "OpenGL renderer" | cut -d':' -f2 | xargs)
            info "OpenGL Vendor: ${GL_VENDOR}"
            info "OpenGL Renderer: ${GL_RENDERER}"
        else
            check_warn "3D Acceleration: Not enabled or not working"
            add_issue "3D_ACCELERATION_DISABLED"
        fi
    else
        check_warn "glxinfo not installed - cannot check 3D acceleration"
        info "Install with: sudo apt install mesa-utils"
    fi
    
    # Check glxgears performance
    if command -v glxgears &> /dev/null && [ -n "$DISPLAY" ]; then
        FPS=$(timeout 3 glxgears 2>&1 | grep "frames in" | tail -1 | awk '{print $7}')
        if [ -n "$FPS" ]; then
            info "glxgears FPS: ~${FPS}"
            if (( $(echo "$FPS < 30" | bc -l 2>/dev/null || echo 0) )); then
                check_warn "Graphics performance seems low"
            fi
        fi
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
# 6. CPU PERFORMANCE
# ═══════════════════════════════════════════════════════════════════════════
check_cpu() {
    section "6. CPU PERFORMANCE"
    
    # CPU Info
    CPU_MODEL=$(grep "model name" /proc/cpuinfo | head -1 | cut -d':' -f2 | xargs)
    CPU_CORES=$(nproc)
    
    info "CPU Model: ${CPU_MODEL}"
    info "CPU Cores: ${CPU_CORES}"
    
    # Check core count
    if [ "$CPU_CORES" -ge 4 ]; then
        check_pass "CPU cores: ${CPU_CORES} (Excellent for pentesting)"
    elif [ "$CPU_CORES" -ge 2 ]; then
        check_warn "CPU cores: ${CPU_CORES} (Consider allocating 4+ cores)"
        add_issue "LOW_CPU_CORES"
    else
        check_fail "CPU cores: ${CPU_CORES} (Too low - performance will suffer)"
        add_issue "VERY_LOW_CPU_CORES"
    fi
    
    # CPU features
    if grep -q "hypervisor" /proc/cpuinfo; then
        check_pass "Running under hypervisor (expected for VM)"
    fi
    
    if grep -q " pae " /proc/cpuinfo; then
        check_pass "PAE (Physical Address Extension) enabled"
    fi
    
    if grep -q " nx " /proc/cpuinfo; then
        check_pass "NX (No-Execute) bit enabled"
    fi
    
    # Current CPU usage
    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'.' -f1)
    info "Current CPU Usage: ${CPU_USAGE}%"
    
    if [ "$CPU_USAGE" -gt 80 ]; then
        check_warn "High CPU usage detected: ${CPU_USAGE}%"
    fi
    
    # Load average
    LOAD_AVG=$(cat /proc/loadavg | awk '{print $1, $2, $3}')
    info "Load Average (1/5/15 min): ${LOAD_AVG}"
}

# ═══════════════════════════════════════════════════════════════════════════
# 7. MEMORY PERFORMANCE
# ═══════════════════════════════════════════════════════════════════════════
check_memory() {
    section "7. MEMORY (RAM) PERFORMANCE"
    
    TOTAL_RAM=$(free -m | awk '/^Mem:/{print $2}')
    USED_RAM=$(free -m | awk '/^Mem:/{print $3}')
    FREE_RAM=$(free -m | awk '/^Mem:/{print $4}')
    AVAILABLE_RAM=$(free -m | awk '/^Mem:/{print $7}')
    RAM_PERCENT=$(( (USED_RAM * 100) / TOTAL_RAM ))
    
    info "Total RAM: ${TOTAL_RAM} MB"
    info "Used RAM: ${USED_RAM} MB (${RAM_PERCENT}%)"
    info "Available RAM: ${AVAILABLE_RAM} MB"
    
    # RAM adequacy check
    if [ "$TOTAL_RAM" -ge 8000 ]; then
        check_pass "RAM: ${TOTAL_RAM} MB (Excellent for pentesting)"
    elif [ "$TOTAL_RAM" -ge 4000 ]; then
        check_warn "RAM: ${TOTAL_RAM} MB (Good, but 8GB+ recommended)"
        add_issue "LOW_RAM"
    elif [ "$TOTAL_RAM" -ge 2000 ]; then
        check_warn "RAM: ${TOTAL_RAM} MB (Minimum - may experience slowdowns)"
        add_issue "VERY_LOW_RAM"
    else
        check_fail "RAM: ${TOTAL_RAM} MB (Critically low - increase allocation)"
        add_issue "CRITICAL_LOW_RAM"
    fi
    
    # RAM usage warning
    if [ "$RAM_PERCENT" -gt 85 ]; then
        check_warn "High RAM usage: ${RAM_PERCENT}%"
        add_issue "HIGH_RAM_USAGE"
    fi
    
    # Swap check
    SWAP_TOTAL=$(free -m | awk '/^Swap:/{print $2}')
    SWAP_USED=$(free -m | awk '/^Swap:/{print $3}')
    
    info "Swap Total: ${SWAP_TOTAL} MB"
    info "Swap Used: ${SWAP_USED} MB"
    
    if [ "$SWAP_TOTAL" -gt 0 ]; then
        check_pass "Swap configured (${SWAP_TOTAL} MB)"
        
        if [ "$SWAP_USED" -gt 500 ]; then
            check_warn "Significant swap usage (${SWAP_USED} MB) - consider more RAM"
        fi
    else
        check_warn "No swap configured - consider adding for stability"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
# 8. STORAGE PERFORMANCE
# ═══════════════════════════════════════════════════════════════════════════
check_storage() {
    section "8. STORAGE PERFORMANCE"
    
    # Root partition
    ROOT_INFO=$(df -BG / | awk 'NR==2{print $2, $3, $4, $5}')
    ROOT_TOTAL=$(echo $ROOT_INFO | awk '{print $1}' | tr -d 'G')
    ROOT_USED=$(echo $ROOT_INFO | awk '{print $2}' | tr -d 'G')
    ROOT_AVAIL=$(echo $ROOT_INFO | awk '{print $3}' | tr -d 'G')
    ROOT_PERCENT=$(echo $ROOT_INFO | awk '{print $4}' | tr -d '%')
    
    info "Root Partition (/):"
    info "  Total: ${ROOT_TOTAL}GB | Used: ${ROOT_USED}GB | Available: ${ROOT_AVAIL}GB (${ROOT_PERCENT}% used)"
    
    if [ "$ROOT_AVAIL" -ge 30 ]; then
        check_pass "Free space: ${ROOT_AVAIL}GB (Excellent)"
    elif [ "$ROOT_AVAIL" -ge 15 ]; then
        check_pass "Free space: ${ROOT_AVAIL}GB (Good)"
    elif [ "$ROOT_AVAIL" -ge 5 ]; then
        check_warn "Free space: ${ROOT_AVAIL}GB (Getting low)"
        add_issue "LOW_DISK_SPACE"
    else
        check_fail "Free space: ${ROOT_AVAIL}GB (Critical - expand disk!)"
        add_issue "CRITICAL_DISK_SPACE"
    fi
    
    # I/O scheduler
    if [ -f /sys/block/sda/queue/scheduler ]; then
        SCHEDULER=$(cat /sys/block/sda/queue/scheduler 2>/dev/null | grep -oP '\[\K[^\]]+')
        info "I/O Scheduler: ${SCHEDULER}"
    fi
    
    # Disk I/O test (quick)
    if command -v dd &> /dev/null; then
        info "Quick disk write test..."
        WRITE_SPEED=$(dd if=/dev/zero of=/tmp/testfile bs=1M count=100 conv=fdatasync 2>&1 | grep -oP '[\d.]+ [MG]B/s' | tail -1)
        rm -f /tmp/testfile 2>/dev/null
        if [ -n "$WRITE_SPEED" ]; then
            info "Disk Write Speed: ~${WRITE_SPEED}"
        fi
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
# 9. NETWORK CONFIGURATION
# ═══════════════════════════════════════════════════════════════════════════
check_network() {
    section "9. NETWORK CONFIGURATION"
    
    # List interfaces
    info "Network Interfaces:"
    ip -br addr show 2>/dev/null | while read line; do
        echo "       $line"
    done
    
    # Internet connectivity
    if ping -c 1 -W 3 8.8.8.8 &> /dev/null; then
        check_pass "Internet connectivity (ping 8.8.8.8)"
    else
        check_fail "No internet connectivity"
        add_issue "NO_INTERNET"
    fi
    
    # DNS resolution
    if ping -c 1 -W 3 google.com &> /dev/null; then
        check_pass "DNS resolution working"
    else
        check_warn "DNS resolution may have issues"
        add_issue "DNS_ISSUES"
    fi
    
    # Default gateway
    DEFAULT_GW=$(ip route | grep default | awk '{print $3}' | head -1)
    info "Default Gateway: ${DEFAULT_GW}"
}

# ═══════════════════════════════════════════════════════════════════════════
# 10. SHARED FOLDERS CHECK
# ═══════════════════════════════════════════════════════════════════════════
check_shared_folders() {
    section "10. VIRTUALBOX SHARED FOLDERS"
    
    # Check vboxsf module
    if lsmod | grep -q "vboxsf"; then
        check_pass "Shared Folders kernel module (vboxsf) loaded"
    else
        check_fail "vboxsf module not loaded - Shared Folders won't work"
        add_issue "SHARED_FOLDERS_MODULE_MISSING"
    fi
    
    # Check if user is in vboxsf group
    CURRENT_USER=$(whoami)
    if groups "$CURRENT_USER" | grep -q "vboxsf"; then
        check_pass "User '$CURRENT_USER' is in vboxsf group"
    else
        check_warn "User '$CURRENT_USER' NOT in vboxsf group - cannot access shared folders"
        add_issue "USER_NOT_IN_VBOXSF"
    fi
    
    # Check for mounted shared folders
    SHARED_MOUNTS=$(mount | grep "vboxsf\|/media/sf_" | wc -l)
    if [ "$SHARED_MOUNTS" -gt 0 ]; then
        check_pass "Shared folders mounted: ${SHARED_MOUNTS}"
        mount | grep "vboxsf\|/media/sf_" | while read line; do
            info "  → $line"
        done
    else
        info "No shared folders currently mounted"
        info "Configure in: VirtualBox → Devices → Shared Folders"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
# 11. ESSENTIAL SERVICES
# ═══════════════════════════════════════════════════════════════════════════
check_services() {
    section "11. ESSENTIAL SERVICES"
    
    declare -A SERVICES=(
        ["NetworkManager"]="Network Management"
        ["ssh"]="SSH Server"
        ["postgresql"]="PostgreSQL Database"
        ["docker"]="Docker Containers"
        ["vboxadd-service"]="VirtualBox Guest Additions"
    )
    
    for svc in "${!SERVICES[@]}"; do
        DESC="${SERVICES[$svc]}"
        if systemctl list-unit-files 2>/dev/null | grep -q "^${svc}"; then
            STATUS=$(systemctl is-active "$svc" 2>/dev/null)
            ENABLED=$(systemctl is-enabled "$svc" 2>/dev/null)
            
            if [ "$STATUS" == "active" ]; then
                echo -e "  ${GREEN}[RUNNING]${NC} ${svc} (${DESC})"
            else
                echo -e "  ${YELLOW}[STOPPED]${NC} ${svc} (${DESC}) - enabled: ${ENABLED}"
            fi
        fi
    done
}

# ═══════════════════════════════════════════════════════════════════════════
# 12. PARROT TOOLS CHECK
# ═══════════════════════════════════════════════════════════════════════════
check_parrot_tools() {
    section "12. PARROT SECURITY TOOLS"
    
    TOOLS=("nmap" "msfconsole" "burpsuite" "sqlmap" "hydra" "john" "aircrack-ng" "wireshark" "gobuster" "nikto" "hashcat")
    
    INSTALLED=0
    MISSING=0
    MISSING_LIST=""
    
    for tool in "${TOOLS[@]}"; do
        if command -v "$tool" &> /dev/null || dpkg -l 2>/dev/null | grep -q "^ii.*$tool"; then
            ((INSTALLED++))
        else
            ((MISSING++))
            MISSING_LIST="${MISSING_LIST} ${tool}"
        fi
    done
    
    if [ $MISSING -eq 0 ]; then
        check_pass "All ${#TOOLS[@]} essential pentesting tools installed"
    else
        check_warn "${INSTALLED}/${#TOOLS[@]} tools installed"
        if [ -n "$MISSING_LIST" ]; then
            echo -e "  ${YELLOW}Missing tools:${MISSING_LIST}${NC}"
        fi
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
# 13. SYSTEM LOGS CHECK FOR ERRORS
# ═══════════════════════════════════════════════════════════════════════════
check_logs_for_errors() {
    section "13. SYSTEM LOGS ANALYSIS"
    
    # Check VirtualBox related errors
    info "Checking for VirtualBox errors in logs..."
    
    VBOX_ERRORS=$(dmesg 2>/dev/null | grep -i "vbox" | grep -i "error\|fail\|warn" | tail -5)
    if [ -n "$VBOX_ERRORS" ]; then
        check_warn "VirtualBox related messages in dmesg:"
        echo "$VBOX_ERRORS" | while read line; do
            echo -e "       ${YELLOW}$line${NC}"
        done
    else
        check_pass "No VirtualBox errors in kernel log"
    fi
    
    # Check Guest Additions setup log
    if [ -f /var/log/vboxadd-setup.log ]; then
        GA_ERRORS=$(grep -i "error\|fail" /var/log/vboxadd-setup.log 2>/dev/null | tail -3)
        if [ -n "$GA_ERRORS" ]; then
            check_warn "Errors in Guest Additions setup log:"
            echo "$GA_ERRORS" | while read line; do
                echo -e "       ${YELLOW}$line${NC}"
            done
        else
            check_pass "No errors in Guest Additions setup log"
        fi
    fi
    
    # Check journal for recent critical errors
    CRITICAL_ERRORS=$(journalctl -p 3 -n 5 --no-pager 2>/dev/null | grep -v "^--")
    if [ -n "$CRITICAL_ERRORS" ]; then
        check_warn "Recent critical system errors:"
        echo "$CRITICAL_ERRORS" | head -5 | while read line; do
            echo -e "       ${YELLOW}$line${NC}"
        done
    else
        check_pass "No recent critical errors in system journal"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
# 14. BOOT TIME ANALYSIS
# ═══════════════════════════════════════════════════════════════════════════
check_boot_time() {
    section "14. BOOT TIME ANALYSIS"
    
    # Get boot time
    if command -v systemd-analyze &> /dev/null; then
        BOOT_TIME=$(systemd-analyze 2>/dev/null | head -1)
        info "Boot Time: ${BOOT_TIME}"
        
        # Extract total seconds
        TOTAL_SECONDS=$(systemd-analyze 2>/dev/null | grep -oP '[\d.]+s \(userspace\)' | grep -oP '[\d.]+' | head -1)
        
        if [ -n "$TOTAL_SECONDS" ]; then
            TOTAL_INT=${TOTAL_SECONDS%.*}
            if [ "$TOTAL_INT" -le 30 ]; then
                check_pass "Boot time is good (under 30 seconds)"
            elif [ "$TOTAL_INT" -le 60 ]; then
                check_warn "Boot time is moderate (30-60 seconds)"
                add_issue "SLOW_BOOT"
            else
                check_fail "Boot time is slow (over 60 seconds)"
                add_issue "VERY_SLOW_BOOT"
            fi
        fi
        
        # Show slowest services
        echo ""
        info "Top 10 slowest services at boot:"
        systemd-analyze blame 2>/dev/null | head -10 | while read line; do
            echo -e "       ${YELLOW}$line${NC}"
        done
    else
        check_warn "systemd-analyze not available"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
# 15. STARTUP SERVICES ANALYSIS
# ═══════════════════════════════════════════════════════════════════════════
check_startup_services() {
    section "15. STARTUP SERVICES ANALYSIS"
    
    # Services that can typically be disabled for better performance
    declare -A OPTIONAL_SERVICES=(
        ["postgresql"]="Database server - disable if not using databases"
        ["docker"]="Container runtime - disable if not using Docker"
        ["containerd"]="Container runtime - disable if not using containers"
        ["cups"]="Printing service - disable if not printing"
        ["cups-browsed"]="Printer discovery - disable if not printing"
        ["bluetooth"]="Bluetooth service - disable if not using Bluetooth"
        ["ModemManager"]="Modem support - disable if not using modems"
        ["avahi-daemon"]="Network discovery - can usually be disabled"
        ["accounts-daemon"]="User account service - can sometimes be disabled"
        ["NetworkManager-wait-online"]="Waits for network - often slows boot"
        ["plymouth-quit-wait"]="Boot splash animation - cosmetic only, often wastes 15-35s"
        ["apt-daily-upgrade"]="Auto package upgrades on boot - run updates manually instead"
        ["samba-ad-dc"]="Samba AD domain controller - disable unless running AD"
        ["isc-dhcp-server"]="DHCP server daemon - disable unless serving DHCP"
        ["cpupower-gui"]="CPU frequency scaling GUI - unnecessary in a VM"
        ["cpupower-gui-helper"]="Helper for CPU frequency GUI - unnecessary in a VM"
        ["lm-sensors"]="Hardware temperature sensors - do not work in VMs"
        ["ptunnel"]="ICMP tunneling - only needed during specific engagements"
    )
    
    ENABLED_OPTIONAL=0
    DISABLED_OPTIONAL=0
    SERVICES_TO_DISABLE=()
    
    echo -e "  ${WHITE}[Optional Services Status]${NC}"
    
    for svc in "${!OPTIONAL_SERVICES[@]}"; do
        DESC="${OPTIONAL_SERVICES[$svc]}"
        if systemctl is-enabled "$svc" &>/dev/null 2>&1; then
            STATUS=$(systemctl is-active "$svc" 2>/dev/null)
            if [ "$STATUS" == "active" ]; then
                echo -e "  ${YELLOW}[ENABLED/RUNNING]${NC} ${svc}"
                echo -e "       └─ ${DESC}"
                ((ENABLED_OPTIONAL++))
                SERVICES_TO_DISABLE+=("$svc")
            else
                echo -e "  ${YELLOW}[ENABLED/STOPPED]${NC} ${svc}"
                ((ENABLED_OPTIONAL++))
                SERVICES_TO_DISABLE+=("$svc")
            fi
        fi
    done
    
    echo ""
    if [ $ENABLED_OPTIONAL -gt 3 ]; then
        check_warn "${ENABLED_OPTIONAL} optional services enabled - consider disabling unused ones"
        add_issue "MANY_OPTIONAL_SERVICES"
    elif [ $ENABLED_OPTIONAL -gt 0 ]; then
        info "${ENABLED_OPTIONAL} optional services enabled"
    else
        check_pass "No unnecessary services running"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
# 16. SYSTEM PERFORMANCE METRICS
# ═══════════════════════════════════════════════════════════════════════════
check_performance_metrics() {
    section "16. SYSTEM PERFORMANCE METRICS"
    
    # Swappiness
    SWAPPINESS=$(cat /proc/sys/vm/swappiness 2>/dev/null)
    info "Current swappiness: ${SWAPPINESS}"
    
    if [ "$SWAPPINESS" -gt 30 ]; then
        check_warn "Swappiness is high (${SWAPPINESS}) - system may use swap too aggressively"
        add_issue "HIGH_SWAPPINESS"
    else
        check_pass "Swappiness is optimized (${SWAPPINESS})"
    fi
    
    # Cache pressure
    CACHE_PRESSURE=$(cat /proc/sys/vm/vfs_cache_pressure 2>/dev/null)
    info "VFS cache pressure: ${CACHE_PRESSURE}"
    
    # Check if preload is installed
    if command -v preload &> /dev/null; then
        if systemctl is-active preload &>/dev/null; then
            check_pass "Preload is installed and running (faster app launching)"
        else
            check_warn "Preload is installed but not running"
        fi
    else
        info "Preload not installed (optional: speeds up app launching)"
        add_issue "PRELOAD_NOT_INSTALLED"
    fi
    
    # Check for tracker (GNOME indexer - can be heavy)
    if pgrep -x "tracker" > /dev/null || pgrep -f "tracker-miner" > /dev/null; then
        check_warn "Tracker (file indexer) is running - can slow down system"
        add_issue "TRACKER_RUNNING"
    fi
    
    # Check KDE effects (if KDE)
    if [ "$XDG_CURRENT_DESKTOP" == "KDE" ] || echo "$XDG_CURRENT_DESKTOP" | grep -qi "plasma"; then
        if command -v kreadconfig5 &> /dev/null; then
            COMPOSITING=$(kreadconfig5 --file kwinrc --group Compositing --key Enabled 2>/dev/null)
            if [ "$COMPOSITING" != "false" ]; then
                info "KDE desktop effects are enabled (can be disabled for performance)"
                add_issue "KDE_EFFECTS_ENABLED"
            else
                check_pass "KDE desktop effects are disabled"
            fi
        fi
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
# 17. BROWSER CHECK
# ═══════════════════════════════════════════════════════════════════════════
check_browsers() {
    section "17. BROWSER ANALYSIS"
    
    # Check installed browsers
    BROWSERS_INSTALLED=()
    
    if command -v firefox &> /dev/null; then
        BROWSERS_INSTALLED+=("firefox")
        info "Firefox installed (heavy, resource-intensive)"
    fi
    
    if command -v firefox-esr &> /dev/null; then
        BROWSERS_INSTALLED+=("firefox-esr")
        info "Firefox ESR installed (more stable than regular Firefox)"
    fi
    
    if command -v chromium &> /dev/null; then
        BROWSERS_INSTALLED+=("chromium")
        check_pass "Chromium installed (lighter alternative)"
    fi
    
    if command -v falkon &> /dev/null; then
        BROWSERS_INSTALLED+=("falkon")
        check_pass "Falkon installed (lightweight Qt browser)"
    fi
    
    if command -v midori &> /dev/null; then
        BROWSERS_INSTALLED+=("midori")
        check_pass "Midori installed (very lightweight)"
    fi
    
    # Recommendations
    if [[ " ${BROWSERS_INSTALLED[@]} " =~ " firefox " ]] && [[ ! " ${BROWSERS_INSTALLED[@]} " =~ " chromium " ]]; then
        check_warn "Only Firefox installed - consider installing Chromium for lighter browsing"
        add_issue "NO_LIGHT_BROWSER"
    fi
    
    # Check Firefox processes if running
    FIREFOX_MEM=$(ps aux 2>/dev/null | grep -i firefox | grep -v grep | awk '{sum+=$6} END {print sum/1024}')
    if [ -n "$FIREFOX_MEM" ] && [ "${FIREFOX_MEM%.*}" -gt 0 ]; then
        info "Firefox current memory usage: ${FIREFOX_MEM%.*} MB"
        if [ "${FIREFOX_MEM%.*}" -gt 1000 ]; then
            check_warn "Firefox using over 1GB RAM"
        fi
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
# ISSUE FIXES & RECOMMENDATIONS
# ═══════════════════════════════════════════════════════════════════════════
show_fixes() {
    section "🔧 DETECTED ISSUES & FIXES"
    
    if [ ${#ISSUES[@]} -eq 0 ]; then
        echo -e "\n  ${GREEN}${BOLD}✓ No critical issues detected! Your system is well configured.${NC}\n"
        return
    fi
    
    echo ""
    ISSUE_NUM=1
    
    for issue in "${ISSUES[@]}"; do
        case "$issue" in
            "WAYLAND_SESSION")
                echo -e "  ${BOLD}${YELLOW}Issue #${ISSUE_NUM}: Wayland Session Detected${NC}"
                echo -e "  ${WHITE}Problem:${NC} VirtualBox clipboard and drag-drop don't work properly on Wayland"
                echo -e "  ${GREEN}Fix:${NC}"
                echo "       1. Log out of Parrot"
                echo "       2. At login screen, click your username"
                echo "       3. Click the gear icon ⚙️ (bottom corner)"
                echo "       4. Select 'Plasma (X11)' instead of 'Plasma (Wayland)'"
                echo "       5. Log in"
                echo ""
                ((ISSUE_NUM++))
                ;;
                
            "GUEST_ADDITIONS_NOT_INSTALLED"|"VBOXGUEST_MISSING")
                echo -e "  ${BOLD}${YELLOW}Issue #${ISSUE_NUM}: Guest Additions Not Installed/Loaded${NC}"
                echo -e "  ${WHITE}Problem:${NC} VirtualBox features won't work without Guest Additions"
                echo -e "  ${GREEN}Fix:${NC}"
                echo "       # Install dependencies"
                echo "       sudo apt update"
                echo "       sudo apt install -y build-essential dkms linux-headers-\$(uname -r)"
                echo ""
                echo "       # In VirtualBox menu: Devices → Insert Guest Additions CD"
                echo "       sudo mkdir -p /mnt/cdrom"
                echo "       sudo mount /dev/cdrom /mnt/cdrom"
                echo "       sudo /mnt/cdrom/VBoxLinuxAdditions.run"
                echo "       sudo reboot"
                echo ""
                ((ISSUE_NUM++))
                ;;
                
            "VBOXSERVICE_NOT_RUNNING")
                echo -e "  ${BOLD}${YELLOW}Issue #${ISSUE_NUM}: VBoxService Not Running${NC}"
                echo -e "  ${WHITE}Problem:${NC} Guest Additions service is not running"
                echo -e "  ${GREEN}Fix:${NC}"
                echo "       sudo systemctl start vboxadd-service"
                echo "       sudo systemctl enable vboxadd-service"
                echo ""
                ((ISSUE_NUM++))
                ;;
                
            "VBOXCLIENT_CLIPBOARD_MISSING"|"CLIPBOARD_NOT_RUNNING")
                echo -e "  ${BOLD}${YELLOW}Issue #${ISSUE_NUM}: Clipboard Service Not Running${NC}"
                echo -e "  ${WHITE}Problem:${NC} Copy/paste between host and guest won't work"
                echo -e "  ${GREEN}Fix:${NC}"
                echo "       # Method 1: Restart the service"
                echo "       VBoxClient --clipboard &"
                echo ""
                echo "       # Method 2: Restart all VBoxClient services"
                echo "       VBoxClient-all"
                echo ""
                echo "       # Method 3: Check VirtualBox menu"
                echo "       Devices → Shared Clipboard → Bidirectional"
                echo ""
                ((ISSUE_NUM++))
                ;;
                
            "VBOXCLIENT_DRAGANDDROP_MISSING"|"DRAGDROP_NOT_RUNNING")
                echo -e "  ${BOLD}${YELLOW}Issue #${ISSUE_NUM}: Drag-Drop Service Not Running${NC}"
                echo -e "  ${WHITE}Problem:${NC} Drag and drop between host and guest won't work"
                echo -e "  ${GREEN}Fix:${NC}"
                echo "       # Method 1: Restart the service"
                echo "       VBoxClient --draganddrop &"
                echo ""
                echo "       # Method 2: Check VirtualBox menu"
                echo "       Devices → Drag and Drop → Bidirectional"
                echo ""
                echo "       # Note: Drag-drop is buggy in VirtualBox."
                echo "       # Recommended: Use Shared Folders instead (100% reliable)"
                echo ""
                ((ISSUE_NUM++))
                ;;
                
            "USER_NOT_IN_VBOXSF")
                echo -e "  ${BOLD}${YELLOW}Issue #${ISSUE_NUM}: User Not in vboxsf Group${NC}"
                echo -e "  ${WHITE}Problem:${NC} Cannot access VirtualBox shared folders"
                echo -e "  ${GREEN}Fix:${NC}"
                echo "       sudo usermod -aG vboxsf \$USER"
                echo "       # Then log out and log back in, or reboot"
                echo "       sudo reboot"
                echo ""
                ((ISSUE_NUM++))
                ;;
                
            "SHARED_FOLDERS_MODULE_MISSING"|"VBOXSF_MISSING")
                echo -e "  ${BOLD}${YELLOW}Issue #${ISSUE_NUM}: Shared Folders Module Missing${NC}"
                echo -e "  ${WHITE}Problem:${NC} vboxsf kernel module not loaded"
                echo -e "  ${GREEN}Fix:${NC}"
                echo "       # Load the module"
                echo "       sudo modprobe vboxsf"
                echo ""
                echo "       # If that fails, reinstall Guest Additions"
                echo "       sudo /mnt/cdrom/VBoxLinuxAdditions.run"
                echo "       sudo reboot"
                echo ""
                ((ISSUE_NUM++))
                ;;
                
            "3D_ACCELERATION_DISABLED")
                echo -e "  ${BOLD}${YELLOW}Issue #${ISSUE_NUM}: 3D Acceleration Not Working${NC}"
                echo -e "  ${WHITE}Problem:${NC} Graphics performance may be poor"
                echo -e "  ${GREEN}Fix:${NC}"
                echo "       1. Shut down the VM"
                echo "       2. VirtualBox → Settings → Display"
                echo "       3. Check 'Enable 3D Acceleration'"
                echo "       4. Set Video Memory to 128 MB"
                echo "       5. Graphics Controller: VMSVGA"
                echo "       6. Start the VM"
                echo ""
                ((ISSUE_NUM++))
                ;;
                
            "LOW_CPU_CORES"|"VERY_LOW_CPU_CORES")
                echo -e "  ${BOLD}${YELLOW}Issue #${ISSUE_NUM}: Low CPU Allocation${NC}"
                echo -e "  ${WHITE}Problem:${NC} VM may be slow with few CPU cores"
                echo -e "  ${GREEN}Fix:${NC}"
                echo "       1. Shut down the VM"
                echo "       2. VirtualBox → Settings → System → Processor"
                echo "       3. Increase 'Processors' to 4 or more"
                echo "       4. Keep within green zone (50-75% of host CPU)"
                echo ""
                ((ISSUE_NUM++))
                ;;
                
            "LOW_RAM"|"VERY_LOW_RAM"|"CRITICAL_LOW_RAM")
                echo -e "  ${BOLD}${YELLOW}Issue #${ISSUE_NUM}: Low RAM Allocation${NC}"
                echo -e "  ${WHITE}Problem:${NC} VM may run slowly or freeze"
                echo -e "  ${GREEN}Fix:${NC}"
                echo "       1. Shut down the VM"
                echo "       2. VirtualBox → Settings → System → Motherboard"
                echo "       3. Increase 'Base Memory' to at least 4096 MB (8192 MB recommended)"
                echo ""
                ((ISSUE_NUM++))
                ;;
                
            "HIGH_RAM_USAGE")
                echo -e "  ${BOLD}${YELLOW}Issue #${ISSUE_NUM}: High RAM Usage${NC}"
                echo -e "  ${WHITE}Problem:${NC} System may become slow or unresponsive"
                echo -e "  ${GREEN}Fix:${NC}"
                echo "       # Check what's using memory"
                echo "       top -o %MEM"
                echo ""
                echo "       # Or allocate more RAM in VirtualBox settings"
                echo ""
                ((ISSUE_NUM++))
                ;;
                
            "LOW_DISK_SPACE"|"CRITICAL_DISK_SPACE")
                echo -e "  ${BOLD}${YELLOW}Issue #${ISSUE_NUM}: Low Disk Space${NC}"
                echo -e "  ${WHITE}Problem:${NC} May cause system issues and failed updates"
                echo -e "  ${GREEN}Fix:${NC}"
                echo "       # Clean package cache"
                echo "       sudo apt clean"
                echo "       sudo apt autoremove -y"
                echo ""
                echo "       # Find large files"
                echo "       sudo du -sh /* 2>/dev/null | sort -h | tail -10"
                echo ""
                echo "       # Or expand virtual disk in VirtualBox"
                echo ""
                ((ISSUE_NUM++))
                ;;
                
            "NO_INTERNET")
                echo -e "  ${BOLD}${YELLOW}Issue #${ISSUE_NUM}: No Internet Connectivity${NC}"
                echo -e "  ${WHITE}Problem:${NC} Cannot reach the internet"
                echo -e "  ${GREEN}Fix:${NC}"
                echo "       # Check network adapter in VirtualBox"
                echo "       Devices → Network → Network Settings"
                echo "       - Try 'NAT' or 'Bridged Adapter'"
                echo ""
                echo "       # Inside VM"
                echo "       sudo systemctl restart NetworkManager"
                echo "       ip a  # Check if interface has IP"
                echo ""
                ((ISSUE_NUM++))
                ;;
                
            "DNS_ISSUES")
                echo -e "  ${BOLD}${YELLOW}Issue #${ISSUE_NUM}: DNS Resolution Issues${NC}"
                echo -e "  ${WHITE}Problem:${NC} Cannot resolve domain names"
                echo -e "  ${GREEN}Fix:${NC}"
                echo "       # Set Google DNS"
                echo "       echo 'nameserver 8.8.8.8' | sudo tee /etc/resolv.conf"
                echo ""
                echo "       # Or restart NetworkManager"
                echo "       sudo systemctl restart NetworkManager"
                echo ""
                ((ISSUE_NUM++))
                ;;
                
            "SLOW_BOOT"|"VERY_SLOW_BOOT")
                echo -e "  ${BOLD}${YELLOW}Issue #${ISSUE_NUM}: Slow Boot Time${NC}"
                echo -e "  ${WHITE}Problem:${NC} System takes too long to boot"
                echo -e "  ${GREEN}Fix:${NC}"
                echo "       # Disable NetworkManager wait (common cause)"
                echo "       sudo systemctl disable NetworkManager-wait-online.service"
                echo ""
                echo "       # Disable unnecessary services"
                echo "       sudo systemctl disable postgresql docker cups bluetooth"
                echo ""
                echo "       # Analyze boot time"
                echo "       systemd-analyze blame | head -20"
                echo ""
                ((ISSUE_NUM++))
                ;;
                
            "MANY_OPTIONAL_SERVICES")
                echo -e "  ${BOLD}${YELLOW}Issue #${ISSUE_NUM}: Many Optional Services Running${NC}"
                echo -e "  ${WHITE}Problem:${NC} Unnecessary services consuming resources"
                echo -e "  ${GREEN}Fix:${NC}"
                echo "       # Disable common unnecessary services"
                echo "       sudo systemctl disable postgresql"
                echo "       sudo systemctl disable docker containerd"
                echo "       sudo systemctl disable cups cups-browsed"
                echo "       sudo systemctl disable bluetooth ModemManager"
                echo "       sudo systemctl disable avahi-daemon"
                echo "       sudo systemctl disable NetworkManager-wait-online"
                echo ""
                ((ISSUE_NUM++))
                ;;
                
            "HIGH_SWAPPINESS")
                echo -e "  ${BOLD}${YELLOW}Issue #${ISSUE_NUM}: High Swappiness Value${NC}"
                echo -e "  ${WHITE}Problem:${NC} System uses swap too aggressively, causing slowdowns"
                echo -e "  ${GREEN}Fix:${NC}"
                echo "       # Set swappiness to 10 (use RAM more, swap less)"
                echo "       echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf"
                echo "       sudo sysctl -p"
                echo ""
                ((ISSUE_NUM++))
                ;;
                
            "PRELOAD_NOT_INSTALLED")
                echo -e "  ${BOLD}${YELLOW}Issue #${ISSUE_NUM}: Preload Not Installed${NC}"
                echo -e "  ${WHITE}Problem:${NC} Applications may take longer to start"
                echo -e "  ${GREEN}Fix:${NC}"
                echo "       # Install preload (learns and preloads frequently used apps)"
                echo "       sudo apt install -y preload"
                echo "       sudo systemctl enable preload"
                echo "       sudo systemctl start preload"
                echo ""
                ((ISSUE_NUM++))
                ;;
                
            "TRACKER_RUNNING")
                echo -e "  ${BOLD}${YELLOW}Issue #${ISSUE_NUM}: Tracker File Indexer Running${NC}"
                echo -e "  ${WHITE}Problem:${NC} File indexer consuming CPU/disk resources"
                echo -e "  ${GREEN}Fix:${NC}"
                echo "       # Disable tracker"
                echo "       systemctl --user mask tracker-store.service tracker-miner-fs.service"
                echo "       systemctl --user mask tracker-miner-rss.service tracker-extract.service"
                echo "       systemctl --user mask tracker-miner-apps.service tracker-writeback.service"
                echo "       tracker reset --hard"
                echo ""
                ((ISSUE_NUM++))
                ;;
                
            "KDE_EFFECTS_ENABLED")
                echo -e "  ${BOLD}${YELLOW}Issue #${ISSUE_NUM}: KDE Desktop Effects Enabled${NC}"
                echo -e "  ${WHITE}Problem:${NC} Visual effects consuming GPU/CPU resources"
                echo -e "  ${GREEN}Fix:${NC}"
                echo "       # Via GUI:"
                echo "       System Settings → Workspace Behavior → Desktop Effects"
                echo "       → Uncheck 'Enable desktop effects at startup'"
                echo ""
                echo "       # Or via command:"
                echo "       kwriteconfig5 --file kwinrc --group Compositing --key Enabled false"
                echo "       qdbus org.kde.KWin /KWin reconfigure"
                echo ""
                ((ISSUE_NUM++))
                ;;
                
            "NO_LIGHT_BROWSER")
                echo -e "  ${BOLD}${YELLOW}Issue #${ISSUE_NUM}: No Lightweight Browser Installed${NC}"
                echo -e "  ${WHITE}Problem:${NC} Firefox is heavy and uses lots of RAM"
                echo -e "  ${GREEN}Fix:${NC}"
                echo "       # Install Chromium (lighter than Firefox)"
                echo "       sudo apt install -y chromium"
                echo ""
                echo "       # Or install very lightweight browsers"
                echo "       sudo apt install -y falkon    # Qt-based, lightweight"
                echo "       sudo apt install -y midori    # Very lightweight"
                echo ""
                ((ISSUE_NUM++))
                ;;
        esac
    done
}

# ═══════════════════════════════════════════════════════════════════════════
# QUICK FIX SCRIPT GENERATOR
# ═══════════════════════════════════════════════════════════════════════════
generate_fix_script() {
    section "📜 AUTO-FIX SCRIPT"
    
    if [ ${#ISSUES[@]} -eq 0 ]; then
        echo -e "  ${GREEN}No fixes needed - system is healthy!${NC}"
        return
    fi
    
    FIX_SCRIPT="/tmp/parrot_autofix.sh"
    
    cat > "$FIX_SCRIPT" << 'FIXSCRIPT'
#!/bin/bash
# Auto-generated fix script for Parrot OS VM issues
# Run with: sudo bash /tmp/parrot_autofix.sh

echo "Starting automatic fixes..."

FIXSCRIPT

    for issue in "${ISSUES[@]}"; do
        case "$issue" in
            "VBOXSERVICE_NOT_RUNNING")
                echo "systemctl start vboxadd-service" >> "$FIX_SCRIPT"
                echo "systemctl enable vboxadd-service" >> "$FIX_SCRIPT"
                ;;
            "VBOXSF_MISSING")
                echo "modprobe vboxsf" >> "$FIX_SCRIPT"
                ;;
            "USER_NOT_IN_VBOXSF")
                echo "usermod -aG vboxsf \$SUDO_USER" >> "$FIX_SCRIPT"
                ;;
            "CLIPBOARD_NOT_RUNNING"|"VBOXCLIENT_CLIPBOARD_MISSING")
                echo "su - \$SUDO_USER -c 'VBoxClient --clipboard &'" >> "$FIX_SCRIPT"
                ;;
            "DRAGDROP_NOT_RUNNING"|"VBOXCLIENT_DRAGANDDROP_MISSING")
                echo "su - \$SUDO_USER -c 'VBoxClient --draganddrop &'" >> "$FIX_SCRIPT"
                ;;
        esac
    done
    
    echo "" >> "$FIX_SCRIPT"
    echo 'echo "Fixes applied! Some changes may require logout or reboot."' >> "$FIX_SCRIPT"
    
    chmod +x "$FIX_SCRIPT"
    
    echo -e "  ${GREEN}Fix script generated: ${FIX_SCRIPT}${NC}"
    echo -e "  ${WHITE}Run with: ${CYAN}sudo bash ${FIX_SCRIPT}${NC}"
    echo ""
    echo -e "  ${YELLOW}Note: Some issues (like Wayland→X11, RAM/CPU allocation)${NC}"
    echo -e "  ${YELLOW}require manual changes in VirtualBox settings or at login.${NC}"
}

# ═══════════════════════════════════════════════════════════════════════════
# SUMMARY
# ═══════════════════════════════════════════════════════════════════════════
show_summary() {
    section "📊 VERIFICATION SUMMARY"
    
    echo ""
    echo -e "  ${GREEN}Passed:   ${PASS}${NC}"
    echo -e "  ${YELLOW}Warnings: ${WARN}${NC}"
    echo -e "  ${RED}Failed:   ${FAIL}${NC}"
    echo -e "  ${MAGENTA}Issues:   ${#ISSUES[@]}${NC}"
    echo ""
    
    # Overall status
    if [ $FAIL -eq 0 ] && [ ${#ISSUES[@]} -le 2 ]; then
        echo -e "  ${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "  ${GREEN}║  ★ Your Parrot OS VM is properly configured and healthy! ★   ║${NC}"
        echo -e "  ${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    elif [ $FAIL -le 2 ]; then
        echo -e "  ${YELLOW}╔═══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "  ${YELLOW}║  ⚠ VM is functional but has some issues - review fixes above ║${NC}"
        echo -e "  ${YELLOW}╚═══════════════════════════════════════════════════════════════╝${NC}"
    else
        echo -e "  ${RED}╔═══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "  ${RED}║  ✗ Multiple issues detected - follow the fix instructions     ║${NC}"
        echo -e "  ${RED}╚═══════════════════════════════════════════════════════════════╝${NC}"
    fi
    
    echo ""
    echo -e "  ${CYAN}Report generated: $(date)${NC}"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════
# COMPREHENSIVE ISSUES TABLE
# ═══════════════════════════════════════════════════════════════════════════
show_issues_table() {
    section "📋 ISSUES & SOLUTIONS TABLE"
    
    if [ ${#ISSUES[@]} -eq 0 ]; then
        echo ""
        echo -e "  ${GREEN}┌─────────────────────────────────────────────────────────────────────┐${NC}"
        echo -e "  ${GREEN}│          ✓ NO ISSUES DETECTED - SYSTEM IS HEALTHY!                 │${NC}"
        echo -e "  ${GREEN}└─────────────────────────────────────────────────────────────────────┘${NC}"
        echo ""
        return
    fi
    
    echo ""
    
    # Table header
    echo -e "${CYAN}┌──────┬─────────────────────────────┬──────────┬────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│ ${BOLD}No.${NC}${CYAN}  │ ${BOLD}Issue${NC}${CYAN}                       │ ${BOLD}Severity${NC}${CYAN} │ ${BOLD}Solution / Commands${NC}${CYAN}                                            │${NC}"
    echo -e "${CYAN}├──────┼─────────────────────────────┼──────────┼────────────────────────────────────────────────────────────────┤${NC}"
    
    ISSUE_NUM=1
    
    for issue in "${ISSUES[@]}"; do
        case "$issue" in
            "WAYLAND_SESSION")
                print_table_row "$ISSUE_NUM" "Wayland Session Active" "HIGH" \
                    "Switch to X11 at login screen" \
                    "1. Log out" \
                    "2. Click gear icon ⚙️ at login" \
                    "3. Select 'Plasma (X11)'" \
                    "4. Log in"
                ((ISSUE_NUM++))
                ;;
                
            "GUEST_ADDITIONS_NOT_INSTALLED")
                print_table_row "$ISSUE_NUM" "Guest Additions Missing" "HIGH" \
                    "Install VirtualBox Guest Additions" \
                    "sudo apt install -y build-essential dkms linux-headers-\$(uname -r)" \
                    "# VirtualBox Menu: Devices → Insert Guest Additions CD" \
                    "sudo mount /dev/cdrom /mnt/cdrom" \
                    "sudo /mnt/cdrom/VBoxLinuxAdditions.run" \
                    "sudo reboot"
                ((ISSUE_NUM++))
                ;;
                
            "VBOXGUEST_MISSING")
                print_table_row "$ISSUE_NUM" "vboxguest Module Missing" "HIGH" \
                    "Reinstall Guest Additions" \
                    "sudo modprobe vboxguest" \
                    "# If fails, reinstall Guest Additions:" \
                    "sudo /mnt/cdrom/VBoxLinuxAdditions.run" \
                    "sudo reboot"
                ((ISSUE_NUM++))
                ;;
                
            "VBOXSF_MISSING"|"SHARED_FOLDERS_MODULE_MISSING")
                print_table_row "$ISSUE_NUM" "Shared Folders Module Missing" "MEDIUM" \
                    "Load vboxsf kernel module" \
                    "sudo modprobe vboxsf" \
                    "# Make permanent:" \
                    "echo 'vboxsf' | sudo tee -a /etc/modules"
                ((ISSUE_NUM++))
                ;;
                
            "VBOXSERVICE_NOT_RUNNING")
                print_table_row "$ISSUE_NUM" "VBoxService Not Running" "HIGH" \
                    "Start and enable the service" \
                    "sudo systemctl start vboxadd-service" \
                    "sudo systemctl enable vboxadd-service"
                ((ISSUE_NUM++))
                ;;
                
            "VBOXCLIENT_CLIPBOARD_MISSING"|"CLIPBOARD_NOT_RUNNING")
                print_table_row "$ISSUE_NUM" "Clipboard Service Missing" "MEDIUM" \
                    "Start clipboard service" \
                    "VBoxClient --clipboard &" \
                    "# Or restart all:" \
                    "VBoxClient-all" \
                    "# Check VirtualBox: Devices → Shared Clipboard → Bidirectional"
                ((ISSUE_NUM++))
                ;;
                
            "VBOXCLIENT_DRAGANDDROP_MISSING"|"DRAGDROP_NOT_RUNNING")
                print_table_row "$ISSUE_NUM" "Drag-Drop Service Missing" "LOW" \
                    "Start drag-drop service (Note: Often buggy)" \
                    "VBoxClient --draganddrop &" \
                    "# Check VirtualBox: Devices → Drag and Drop → Bidirectional" \
                    "# Recommended: Use Shared Folders instead"
                ((ISSUE_NUM++))
                ;;
                
            "VBOXCLIENT_SEAMLESS_MISSING")
                print_table_row "$ISSUE_NUM" "Seamless Mode Missing" "LOW" \
                    "Start seamless service" \
                    "VBoxClient --seamless &"
                ((ISSUE_NUM++))
                ;;
                
            "VBOXCLIENT_VMSVGA_MISSING")
                print_table_row "$ISSUE_NUM" "VMSVGA Service Missing" "MEDIUM" \
                    "Start VMSVGA service" \
                    "VBoxClient --vmsvga &"
                ((ISSUE_NUM++))
                ;;
                
            "USER_NOT_IN_VBOXSF")
                print_table_row "$ISSUE_NUM" "User Not in vboxsf Group" "MEDIUM" \
                    "Add user to vboxsf group for shared folders" \
                    "sudo usermod -aG vboxsf \$USER" \
                    "# Then logout/login or:" \
                    "sudo reboot"
                ((ISSUE_NUM++))
                ;;
                
            "3D_ACCELERATION_DISABLED")
                print_table_row "$ISSUE_NUM" "3D Acceleration Disabled" "MEDIUM" \
                    "Enable in VirtualBox settings (VM off)" \
                    "1. Shut down VM" \
                    "2. VirtualBox → Settings → Display" \
                    "3. Check 'Enable 3D Acceleration'" \
                    "4. Video Memory: 128 MB" \
                    "5. Graphics Controller: VMSVGA"
                ((ISSUE_NUM++))
                ;;
                
            "LOW_CPU_CORES")
                print_table_row "$ISSUE_NUM" "Low CPU Cores (< 4)" "MEDIUM" \
                    "Allocate more CPU cores in VirtualBox" \
                    "1. Shut down VM" \
                    "2. VirtualBox → Settings → System → Processor" \
                    "3. Increase to 4+ cores" \
                    "4. Stay in green zone (50-75% of host)"
                ((ISSUE_NUM++))
                ;;
                
            "VERY_LOW_CPU_CORES")
                print_table_row "$ISSUE_NUM" "Very Low CPU Cores (< 2)" "HIGH" \
                    "Allocate more CPU cores urgently" \
                    "1. Shut down VM" \
                    "2. VirtualBox → Settings → System → Processor" \
                    "3. Set to at least 2 cores (4+ recommended)"
                ((ISSUE_NUM++))
                ;;
                
            "LOW_RAM")
                print_table_row "$ISSUE_NUM" "Low RAM (< 8GB)" "MEDIUM" \
                    "Allocate more RAM in VirtualBox" \
                    "1. Shut down VM" \
                    "2. VirtualBox → Settings → System → Motherboard" \
                    "3. Increase Base Memory to 8192 MB+"
                ((ISSUE_NUM++))
                ;;
                
            "VERY_LOW_RAM"|"CRITICAL_LOW_RAM")
                print_table_row "$ISSUE_NUM" "Critically Low RAM" "HIGH" \
                    "Increase RAM allocation urgently" \
                    "1. Shut down VM" \
                    "2. VirtualBox → Settings → System → Motherboard" \
                    "3. Set Base Memory to at least 4096 MB"
                ((ISSUE_NUM++))
                ;;
                
            "HIGH_RAM_USAGE")
                print_table_row "$ISSUE_NUM" "High RAM Usage (> 85%)" "MEDIUM" \
                    "Check memory-heavy processes" \
                    "top -o %MEM" \
                    "# Kill unnecessary processes:" \
                    "kill -9 <PID>" \
                    "# Or allocate more RAM in VirtualBox"
                ((ISSUE_NUM++))
                ;;
                
            "LOW_DISK_SPACE")
                print_table_row "$ISSUE_NUM" "Low Disk Space (< 15GB)" "MEDIUM" \
                    "Free up disk space" \
                    "sudo apt clean" \
                    "sudo apt autoremove -y" \
                    "# Find large files:" \
                    "sudo du -sh /* 2>/dev/null | sort -h | tail -10"
                ((ISSUE_NUM++))
                ;;
                
            "CRITICAL_DISK_SPACE")
                print_table_row "$ISSUE_NUM" "Critical Disk Space (< 5GB)" "HIGH" \
                    "Free up disk space urgently" \
                    "sudo apt clean && sudo apt autoremove -y" \
                    "sudo journalctl --vacuum-time=3d" \
                    "# Consider expanding virtual disk"
                ((ISSUE_NUM++))
                ;;
                
            "NO_INTERNET")
                print_table_row "$ISSUE_NUM" "No Internet Connection" "HIGH" \
                    "Fix network configuration" \
                    "# Check VirtualBox: Devices → Network → Adapter" \
                    "# Try NAT or Bridged mode" \
                    "sudo systemctl restart NetworkManager" \
                    "ip a  # Verify interface has IP"
                ((ISSUE_NUM++))
                ;;
                
            "DNS_ISSUES")
                print_table_row "$ISSUE_NUM" "DNS Resolution Failed" "MEDIUM" \
                    "Fix DNS configuration" \
                    "echo 'nameserver 8.8.8.8' | sudo tee /etc/resolv.conf" \
                    "echo 'nameserver 8.8.4.4' | sudo tee -a /etc/resolv.conf" \
                    "sudo systemctl restart NetworkManager"
                ((ISSUE_NUM++))
                ;;
                
            "SLOW_BOOT"|"VERY_SLOW_BOOT")
                print_table_row "$ISSUE_NUM" "Slow Boot Time" "MEDIUM" \
                    "Disable unnecessary startup services" \
                    "sudo systemctl disable NetworkManager-wait-online" \
                    "sudo systemctl disable postgresql docker cups bluetooth" \
                    "systemd-analyze blame | head -20"
                ((ISSUE_NUM++))
                ;;
                
            "MANY_OPTIONAL_SERVICES")
                print_table_row "$ISSUE_NUM" "Many Optional Services" "MEDIUM" \
                    "Disable unused services for faster boot" \
                    "sudo systemctl disable postgresql docker containerd" \
                    "sudo systemctl disable cups bluetooth ModemManager" \
                    "sudo systemctl disable avahi-daemon"
                ((ISSUE_NUM++))
                ;;
                
            "HIGH_SWAPPINESS")
                print_table_row "$ISSUE_NUM" "High Swappiness (>30)" "MEDIUM" \
                    "Reduce swappiness to use RAM more efficiently" \
                    "echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf" \
                    "sudo sysctl -p"
                ((ISSUE_NUM++))
                ;;
                
            "PRELOAD_NOT_INSTALLED")
                print_table_row "$ISSUE_NUM" "Preload Not Installed" "LOW" \
                    "Install preload for faster app launching" \
                    "sudo apt install -y preload" \
                    "sudo systemctl enable preload" \
                    "sudo systemctl start preload"
                ((ISSUE_NUM++))
                ;;
                
            "TRACKER_RUNNING")
                print_table_row "$ISSUE_NUM" "Tracker Indexer Running" "MEDIUM" \
                    "Disable file indexer to save resources" \
                    "tracker reset --hard" \
                    "systemctl --user mask tracker-store.service" \
                    "systemctl --user mask tracker-miner-fs.service"
                ((ISSUE_NUM++))
                ;;
                
            "KDE_EFFECTS_ENABLED")
                print_table_row "$ISSUE_NUM" "KDE Effects Enabled" "LOW" \
                    "Disable desktop effects for better performance" \
                    "System Settings → Desktop Effects → Disable" \
                    "Or: kwriteconfig5 --file kwinrc --group Compositing --key Enabled false" \
                    "qdbus org.kde.KWin /KWin reconfigure"
                ((ISSUE_NUM++))
                ;;
                
            "NO_LIGHT_BROWSER")
                print_table_row "$ISSUE_NUM" "No Lightweight Browser" "LOW" \
                    "Install Chromium (lighter than Firefox)" \
                    "sudo apt install -y chromium" \
                    "Alternative: sudo apt install -y falkon"
                ((ISSUE_NUM++))
                ;;
        esac
    done
    
    # Table footer
    echo -e "${CYAN}└──────┴─────────────────────────────┴──────────┴────────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    # Legend
    echo -e "  ${BOLD}Severity Legend:${NC}"
    echo -e "    ${RED}HIGH${NC}   = Critical issue affecting core functionality"
    echo -e "    ${YELLOW}MEDIUM${NC} = Important issue affecting performance or features"
    echo -e "    ${GREEN}LOW${NC}    = Minor issue, optional fix"
    echo ""
}

# Helper function to print table rows
print_table_row() {
    local num="$1"
    local issue="$2"
    local severity="$3"
    shift 3
    local solutions=("$@")
    
    # Color severity
    local sev_color=""
    case "$severity" in
        "HIGH")   sev_color="${RED}HIGH${NC}    " ;;
        "MEDIUM") sev_color="${YELLOW}MEDIUM${NC}  " ;;
        "LOW")    sev_color="${GREEN}LOW${NC}     " ;;
    esac
    
    # Print first row with issue name and first solution
    printf "${CYAN}│${NC} %-4s ${CYAN}│${NC} %-27s ${CYAN}│${NC} %b ${CYAN}│${NC} %-62s ${CYAN}│${NC}\n" \
        "$num" "$issue" "$sev_color" "${solutions[0]}"
    
    # Print remaining solution lines
    for ((i=1; i<${#solutions[@]}; i++)); do
        printf "${CYAN}│${NC} %-4s ${CYAN}│${NC} %-27s ${CYAN}│${NC} %-8s ${CYAN}│${NC} ${WHITE}%-62s${NC} ${CYAN}│${NC}\n" \
            "" "" "" "${solutions[$i]}"
    done
    
    # Print separator if not last
    echo -e "${CYAN}├──────┼─────────────────────────────┼──────────┼────────────────────────────────────────────────────────────────┤${NC}"
}

# ═══════════════════════════════════════════════════════════════════════════
# QUICK COMMAND REFERENCE TABLE
# ═══════════════════════════════════════════════════════════════════════════
show_quick_commands_table() {
    section "⚡ QUICK COMMANDS REFERENCE"
    
    echo ""
    echo -e "${CYAN}┌─────────────────────────────────────┬───────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│ ${BOLD}Action${NC}${CYAN}                              │ ${BOLD}Command${NC}${CYAN}                                                             │${NC}"
    echo -e "${CYAN}├─────────────────────────────────────┼───────────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${NC} Restart all VBoxClient services    ${CYAN}│${NC} ${WHITE}VBoxClient-all${NC}                                                  ${CYAN}│${NC}"
    echo -e "${CYAN}├─────────────────────────────────────┼───────────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${NC} Start clipboard service            ${CYAN}│${NC} ${WHITE}VBoxClient --clipboard &${NC}                                        ${CYAN}│${NC}"
    echo -e "${CYAN}├─────────────────────────────────────┼───────────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${NC} Start drag-drop service            ${CYAN}│${NC} ${WHITE}VBoxClient --draganddrop &${NC}                                      ${CYAN}│${NC}"
    echo -e "${CYAN}├─────────────────────────────────────┼───────────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${NC} Restart Guest Additions service    ${CYAN}│${NC} ${WHITE}sudo systemctl restart vboxadd-service${NC}                         ${CYAN}│${NC}"
    echo -e "${CYAN}├─────────────────────────────────────┼───────────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${NC} Load shared folders module         ${CYAN}│${NC} ${WHITE}sudo modprobe vboxsf${NC}                                            ${CYAN}│${NC}"
    echo -e "${CYAN}├─────────────────────────────────────┼───────────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${NC} Add user to vboxsf group           ${CYAN}│${NC} ${WHITE}sudo usermod -aG vboxsf \$USER && sudo reboot${NC}                    ${CYAN}│${NC}"
    echo -e "${CYAN}├─────────────────────────────────────┼───────────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${NC} Check session type (X11/Wayland)   ${CYAN}│${NC} ${WHITE}echo \$XDG_SESSION_TYPE${NC}                                          ${CYAN}│${NC}"
    echo -e "${CYAN}├─────────────────────────────────────┼───────────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${NC} Check VBox modules loaded          ${CYAN}│${NC} ${WHITE}lsmod | grep vbox${NC}                                               ${CYAN}│${NC}"
    echo -e "${CYAN}├─────────────────────────────────────┼───────────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${NC} Check VBox services running        ${CYAN}│${NC} ${WHITE}pgrep -a VBox${NC}                                                   ${CYAN}│${NC}"
    echo -e "${CYAN}├─────────────────────────────────────┼───────────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${NC} Check Guest Additions version      ${CYAN}│${NC} ${WHITE}VBoxControl --version${NC}                                           ${CYAN}│${NC}"
    echo -e "${CYAN}├─────────────────────────────────────┼───────────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${NC} Check 3D acceleration              ${CYAN}│${NC} ${WHITE}glxinfo | grep \"direct rendering\"${NC}                               ${CYAN}│${NC}"
    echo -e "${CYAN}├─────────────────────────────────────┼───────────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${NC} Test graphics performance          ${CYAN}│${NC} ${WHITE}glxgears${NC}                                                        ${CYAN}│${NC}"
    echo -e "${CYAN}├─────────────────────────────────────┼───────────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${NC} Reinstall Guest Additions          ${CYAN}│${NC} ${WHITE}sudo /mnt/cdrom/VBoxLinuxAdditions.run${NC}                          ${CYAN}│${NC}"
    echo -e "${CYAN}├─────────────────────────────────────┼───────────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${NC} View shared folders                ${CYAN}│${NC} ${WHITE}ls /media/sf_*${NC}                                                  ${CYAN}│${NC}"
    echo -e "${CYAN}├─────────────────────────────────────┼───────────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${NC} Clean disk space                   ${CYAN}│${NC} ${WHITE}sudo apt clean && sudo apt autoremove -y${NC}                        ${CYAN}│${NC}"
    echo -e "${CYAN}├─────────────────────────────────────┼───────────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${NC} Fix DNS                            ${CYAN}│${NC} ${WHITE}echo 'nameserver 8.8.8.8' | sudo tee /etc/resolv.conf${NC}           ${CYAN}│${NC}"
    echo -e "${CYAN}└─────────────────────────────────────┴───────────────────────────────────────────────────────────────────┘${NC}"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════
# PERFORMANCE OPTIMIZATION TABLE
# ═══════════════════════════════════════════════════════════════════════════
show_optimization_table() {
    section "🚀 PERFORMANCE OPTIMIZATION GUIDE"
    
    echo ""
    echo -e "${CYAN}┌──────────────────────────────────────────────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│ ${BOLD}VIRTUALBOX SETTINGS (Apply when VM is OFF)${NC}${CYAN}                                                             │${NC}"
    echo -e "${CYAN}├────────────────────────────┬─────────────────────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${NC} ${WHITE}Setting${NC}                    ${CYAN}│${NC} ${WHITE}Recommended Value & Location${NC}                                               ${CYAN}│${NC}"
    echo -e "${CYAN}├────────────────────────────┼─────────────────────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${NC} RAM                        ${CYAN}│${NC} 8192 MB+  │ System → Motherboard → Base Memory                       ${CYAN}│${NC}"
    echo -e "${CYAN}├────────────────────────────┼─────────────────────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${NC} CPU Cores                  ${CYAN}│${NC} 4+ cores  │ System → Processor → Processors                          ${CYAN}│${NC}"
    echo -e "${CYAN}├────────────────────────────┼─────────────────────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${NC} Video Memory               ${CYAN}│${NC} 128 MB    │ Display → Screen → Video Memory                          ${CYAN}│${NC}"
    echo -e "${CYAN}├────────────────────────────┼─────────────────────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${NC} 3D Acceleration            ${CYAN}│${NC} ✓ Enabled │ Display → Screen → Enable 3D Acceleration                ${CYAN}│${NC}"
    echo -e "${CYAN}├────────────────────────────┼─────────────────────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${NC} Graphics Controller        ${CYAN}│${NC} VMSVGA    │ Display → Screen → Graphics Controller                   ${CYAN}│${NC}"
    echo -e "${CYAN}├────────────────────────────┼─────────────────────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${NC} Host I/O Cache             ${CYAN}│${NC} ✓ Enabled │ Storage → Controller: SATA → Use Host I/O Cache          ${CYAN}│${NC}"
    echo -e "${CYAN}├────────────────────────────┼─────────────────────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${NC} Pointing Device            ${CYAN}│${NC} USB Tablet│ System → Motherboard → Pointing Device                   ${CYAN}│${NC}"
    echo -e "${CYAN}├────────────────────────────┼─────────────────────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${NC} Paravirtualization         ${CYAN}│${NC} Default   │ System → Acceleration → Paravirtualization Interface     ${CYAN}│${NC}"
    echo -e "${CYAN}└────────────────────────────┴─────────────────────────────────────────────────────────────────────────────┘${NC}"
    
    echo ""
    echo -e "${CYAN}┌──────────────────────────────────────────────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│ ${BOLD}SERVICES TO DISABLE (Faster Boot & Less RAM)${NC}${CYAN}                                                           │${NC}"
    echo -e "${CYAN}├────────────────────────────┬───────────────────────────────────┬─────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${NC} ${WHITE}Service${NC}                    ${CYAN}│${NC} ${WHITE}Purpose${NC}                           ${CYAN}│${NC} ${WHITE}Disable Command${NC}                       ${CYAN}│${NC}"
    echo -e "${CYAN}├────────────────────────────┼───────────────────────────────────┼─────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${NC} plymouth-quit-wait         ${CYAN}│${NC} Boot splash (cosmetic)            ${CYAN}│${NC} sudo systemctl mask plymouth-quit-wait  ${CYAN}│${NC}"
    echo -e "${CYAN}├────────────────────────────┼───────────────────────────────────┼─────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${NC} apt-daily-upgrade          ${CYAN}│${NC} Auto upgrades at boot             ${CYAN}│${NC} sudo systemctl mask apt-daily-upgrade   ${CYAN}│${NC}"
    echo -e "${CYAN}├────────────────────────────┼───────────────────────────────────┼─────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${NC} lm-sensors                 ${CYAN}│${NC} Sensors (no-op in a VM)           ${CYAN}│${NC} sudo systemctl disable lm-sensors       ${CYAN}│${NC}"
    echo -e "${CYAN}├────────────────────────────┼───────────────────────────────────┼─────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${NC} postgresql                 ${CYAN}│${NC} Database server                   ${CYAN}│${NC} sudo systemctl disable postgresql       ${CYAN}│${NC}"
    echo -e "${CYAN}├────────────────────────────┼───────────────────────────────────┼─────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${NC} docker                     ${CYAN}│${NC} Container runtime                 ${CYAN}│${NC} sudo systemctl disable docker           ${CYAN}│${NC}"
    echo -e "${CYAN}├────────────────────────────┼───────────────────────────────────┼─────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${NC} containerd                 ${CYAN}│${NC} Container runtime                 ${CYAN}│${NC} sudo systemctl disable containerd       ${CYAN}│${NC}"
    echo -e "${CYAN}├────────────────────────────┼───────────────────────────────────┼─────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${NC} cups / cups-browsed        ${CYAN}│${NC} Printing service                  ${CYAN}│${NC} sudo systemctl disable cups cups-browsed${CYAN}│${NC}"
    echo -e "${CYAN}├────────────────────────────┼───────────────────────────────────┼─────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${NC} bluetooth                  ${CYAN}│${NC} Bluetooth support                 ${CYAN}│${NC} sudo systemctl disable bluetooth        ${CYAN}│${NC}"
    echo -e "${CYAN}├────────────────────────────┼───────────────────────────────────┼─────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${NC} ModemManager               ${CYAN}│${NC} Modem support                     ${CYAN}│${NC} sudo systemctl disable ModemManager     ${CYAN}│${NC}"
    echo -e "${CYAN}├────────────────────────────┼───────────────────────────────────┼─────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${NC} avahi-daemon               ${CYAN}│${NC} Network discovery                 ${CYAN}│${NC} sudo systemctl disable avahi-daemon     ${CYAN}│${NC}"
    echo -e "${CYAN}├────────────────────────────┼───────────────────────────────────┼─────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${NC} NetworkManager-wait-online ${CYAN}│${NC} Waits for network at boot         ${CYAN}│${NC} sudo systemctl disable NetworkManager-wait-online${CYAN}│${NC}"
    echo -e "${CYAN}└────────────────────────────┴───────────────────────────────────┴─────────────────────────────────────────┘${NC}"
    
    echo ""
    echo -e "${CYAN}┌──────────────────────────────────────────────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│ ${BOLD}SYSTEM OPTIMIZATIONS (Run inside VM)${NC}${CYAN}                                                                   │${NC}"
    echo -e "${CYAN}├────────────────────────────────────────┬─────────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${NC} ${WHITE}Optimization${NC}                          ${CYAN}│${NC} ${WHITE}Command${NC}                                                       ${CYAN}│${NC}"
    echo -e "${CYAN}├────────────────────────────────────────┼─────────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${NC} Reduce swappiness (use RAM more)       ${CYAN}│${NC} echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf       ${CYAN}│${NC}"
    echo -e "${CYAN}├────────────────────────────────────────┼─────────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${NC} Apply sysctl changes                   ${CYAN}│${NC} sudo sysctl -p                                                ${CYAN}│${NC}"
    echo -e "${CYAN}├────────────────────────────────────────┼─────────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${NC} Install preload (faster app launch)    ${CYAN}│${NC} sudo apt install -y preload && sudo systemctl enable preload ${CYAN}│${NC}"
    echo -e "${CYAN}├────────────────────────────────────────┼─────────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${NC} Install lighter browser                ${CYAN}│${NC} sudo apt install -y chromium                                 ${CYAN}│${NC}"
    echo -e "${CYAN}├────────────────────────────────────────┼─────────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${NC} Clear RAM cache (temporary)            ${CYAN}│${NC} sudo sync && sudo sysctl -w vm.drop_caches=3                 ${CYAN}│${NC}"
    echo -e "${CYAN}├────────────────────────────────────────┼─────────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${NC} Clean apt cache                        ${CYAN}│${NC} sudo apt clean && sudo apt autoremove -y                     ${CYAN}│${NC}"
    echo -e "${CYAN}├────────────────────────────────────────┼─────────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${NC} Disable KDE effects (command)          ${CYAN}│${NC} kwriteconfig5 --file kwinrc --group Compositing --key Enabled false ${CYAN}│${NC}"
    echo -e "${CYAN}├────────────────────────────────────────┼─────────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${NC} Apply KDE changes                      ${CYAN}│${NC} qdbus org.kde.KWin /KWin reconfigure                         ${CYAN}│${NC}"
    echo -e "${CYAN}├────────────────────────────────────────┼─────────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${NC} Disable tracker indexer                ${CYAN}│${NC} tracker reset --hard                                         ${CYAN}│${NC}"
    echo -e "${CYAN}└────────────────────────────────────────┴─────────────────────────────────────────────────────────────────┘${NC}"
    
    echo ""
    echo -e "${CYAN}┌──────────────────────────────────────────────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│ ${BOLD}FIREFOX OPTIMIZATION (about:config)${NC}${CYAN}                                                                    │${NC}"
    echo -e "${CYAN}├────────────────────────────────────────────────────┬─────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${NC} ${WHITE}Setting${NC}                                            ${CYAN}│${NC} ${WHITE}Value${NC}                                             ${CYAN}│${NC}"
    echo -e "${CYAN}├────────────────────────────────────────────────────┼─────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${NC} browser.sessionstore.interval                      ${CYAN}│${NC} 30000000 (reduce disk writes)                      ${CYAN}│${NC}"
    echo -e "${CYAN}├────────────────────────────────────────────────────┼─────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${NC} browser.cache.disk.enable                         ${CYAN}│${NC} false (use RAM cache only)                         ${CYAN}│${NC}"
    echo -e "${CYAN}├────────────────────────────────────────────────────┼─────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${NC} browser.cache.memory.capacity                     ${CYAN}│${NC} 524288 (512MB RAM cache)                           ${CYAN}│${NC}"
    echo -e "${CYAN}├────────────────────────────────────────────────────┼─────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${NC} gfx.webrender.all                                 ${CYAN}│${NC} true (better rendering)                            ${CYAN}│${NC}"
    echo -e "${CYAN}├────────────────────────────────────────────────────┼─────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${NC} layers.acceleration.force-enabled                 ${CYAN}│${NC} true (hardware acceleration)                       ${CYAN}│${NC}"
    echo -e "${CYAN}└────────────────────────────────────────────────────┴─────────────────────────────────────────────────────┘${NC}"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════
# GENERATE FULL OPTIMIZATION SCRIPT
# ═══════════════════════════════════════════════════════════════════════════
generate_optimization_script() {
    section "📜 AUTO-OPTIMIZATION SCRIPT"
    
    OPT_SCRIPT="/tmp/parrot_optimize.sh"
    
    cat > "$OPT_SCRIPT" << 'OPTSCRIPT'
#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════
# Parrot OS Performance Optimization Script
# Generated by Parrot VM Check v2.0
# CyberSkii
# ═══════════════════════════════════════════════════════════════════════════

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

echo -e "${CYAN}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║       Parrot OS Performance Optimization Script               ║"
echo "║                     CyberSkii                                 ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as root: sudo $0${NC}"
    exit 1
fi

# Menu function
show_menu() {
    echo ""
    echo -e "${BOLD}Select optimization to apply:${NC}"
    echo ""
    echo "  1) Disable unnecessary startup services (postgresql, docker, plymouth, etc.)"
    echo "  2) Optimize system settings (swappiness, cache, GRUB boot timeout)"
    echo "  3) Install preload (faster app launching)"
    echo "  4) Install lighter browser (Chromium)"
    echo "  5) Disable KDE desktop effects"
    echo "  6) Disable tracker / Baloo file indexer"
    echo "  7) Clean system (apt cache, old packages)"
    echo "  8) Clear RAM cache (temporary boost)"
    echo "  9) Apply ALL optimizations"
    echo "  0) Exit"
    echo ""
}

# Function: Disable startup services
disable_services() {
    echo -e "${YELLOW}[*] Disabling unnecessary startup services...${NC}"
    
    SERVICES=(
        "postgresql"
        "docker"
        "containerd"
        "cups"
        "cups-browsed"
        "bluetooth"
        "ModemManager"
        "avahi-daemon"
        "accounts-daemon"
        "NetworkManager-wait-online"
        "apt-daily-upgrade"
        "samba-ad-dc"
        "isc-dhcp-server"
        "cpupower-gui"
        "cpupower-gui-helper"
        "lm-sensors"
        "ptunnel"
    )

    for svc in "${SERVICES[@]}"; do
        if systemctl is-enabled "$svc" &>/dev/null 2>&1; then
            systemctl disable "$svc" 2>/dev/null
            systemctl stop "$svc" 2>/dev/null
            echo -e "  ${GREEN}[✓]${NC} Disabled: $svc"
        fi
    done

    # Plymouth (boot splash) is a common boot-time offender. It often survives
    # 'disable' because other units depend on it, so mask it to force it off.
    for svc in "plymouth-quit-wait" "plymouth"; do
        if systemctl list-unit-files 2>/dev/null | grep -q "^${svc}\.service"; then
            systemctl mask "${svc}.service" 2>/dev/null
            echo -e "  ${GREEN}[✓]${NC} Masked: ${svc} (boot splash)"
        fi
    done

    echo -e "${GREEN}[✓] Services optimization complete${NC}"
}

# Function: Optimize system settings
optimize_system() {
    echo -e "${YELLOW}[*] Optimizing system settings...${NC}"
    
    # Set swappiness
    if ! grep -q "vm.swappiness=10" /etc/sysctl.conf; then
        echo "vm.swappiness=10" >> /etc/sysctl.conf
        echo -e "  ${GREEN}[✓]${NC} Set swappiness to 10"
    else
        echo -e "  ${CYAN}[i]${NC} Swappiness already optimized"
    fi
    
    # Set cache pressure
    if ! grep -q "vm.vfs_cache_pressure=50" /etc/sysctl.conf; then
        echo "vm.vfs_cache_pressure=50" >> /etc/sysctl.conf
        echo -e "  ${GREEN}[✓]${NC} Set vfs_cache_pressure to 50"
    fi

    # Apply changes
    sysctl -p &>/dev/null

    # Reduce GRUB menu timeout so the machine boots straight through instead of
    # pausing at the boot menu for several seconds every start.
    if [ -f /etc/default/grub ]; then
        if grep -q "^GRUB_TIMEOUT=" /etc/default/grub; then
            CURRENT_TIMEOUT=$(grep "^GRUB_TIMEOUT=" /etc/default/grub | head -1 | cut -d= -f2)
            if [ "$CURRENT_TIMEOUT" != "0" ]; then
                sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' /etc/default/grub
                update-grub &>/dev/null && \
                    echo -e "  ${GREEN}[✓]${NC} Reduced GRUB boot menu timeout to 0s (was ${CURRENT_TIMEOUT}s)"
            else
                echo -e "  ${CYAN}[i]${NC} GRUB timeout already 0"
            fi
        else
            echo "GRUB_TIMEOUT=0" >> /etc/default/grub
            update-grub &>/dev/null && \
                echo -e "  ${GREEN}[✓]${NC} Set GRUB boot menu timeout to 0s"
        fi
    fi

    echo -e "${GREEN}[✓] System settings optimization complete${NC}"
}

# Function: Install preload
install_preload() {
    echo -e "${YELLOW}[*] Installing preload...${NC}"
    
    if command -v preload &> /dev/null; then
        echo -e "  ${CYAN}[i]${NC} Preload already installed"
    else
        apt install -y preload
        echo -e "  ${GREEN}[✓]${NC} Preload installed"
    fi
    
    systemctl enable preload &>/dev/null
    systemctl start preload &>/dev/null
    
    echo -e "${GREEN}[✓] Preload setup complete${NC}"
}

# Function: Install lighter browser
install_browser() {
    echo -e "${YELLOW}[*] Installing Chromium browser...${NC}"
    
    if command -v chromium &> /dev/null; then
        echo -e "  ${CYAN}[i]${NC} Chromium already installed"
    else
        apt install -y chromium
        echo -e "  ${GREEN}[✓]${NC} Chromium installed"
    fi
    
    echo -e "${GREEN}[✓] Browser installation complete${NC}"
    echo -e "${CYAN}[i] Tip: Use Chromium instead of Firefox for lighter browsing${NC}"
}

# Function: Disable KDE effects
disable_kde_effects() {
    echo -e "${YELLOW}[*] Disabling KDE desktop effects...${NC}"
    
    # Get the actual user (not root)
    REAL_USER="${SUDO_USER:-$USER}"
    REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
    
    if [ -f "$REAL_HOME/.config/kwinrc" ]; then
        # Disable compositing
        su - "$REAL_USER" -c "kwriteconfig5 --file kwinrc --group Compositing --key Enabled false" 2>/dev/null
        
        # Try to apply immediately
        su - "$REAL_USER" -c "qdbus org.kde.KWin /KWin reconfigure" 2>/dev/null
        
        echo -e "  ${GREEN}[✓]${NC} KDE desktop effects disabled"
    else
        echo -e "  ${CYAN}[i]${NC} KDE config not found - may not be using KDE"
    fi
    
    echo -e "${GREEN}[✓] KDE optimization complete${NC}"
    echo -e "${CYAN}[i] You may need to log out and back in for full effect${NC}"
}

# Function: Disable tracker
disable_tracker() {
    echo -e "${YELLOW}[*] Disabling tracker file indexer...${NC}"
    
    REAL_USER="${SUDO_USER:-$USER}"
    
    # Mask tracker services
    su - "$REAL_USER" -c "systemctl --user mask tracker-store.service tracker-miner-fs.service" 2>/dev/null
    su - "$REAL_USER" -c "systemctl --user mask tracker-miner-rss.service tracker-extract.service" 2>/dev/null
    su - "$REAL_USER" -c "systemctl --user mask tracker-miner-apps.service tracker-writeback.service" 2>/dev/null
    
    # Reset tracker
    su - "$REAL_USER" -c "tracker reset --hard" 2>/dev/null

    # Kill any running tracker processes
    pkill -f tracker 2>/dev/null

    # KDE editions use Baloo instead of tracker - disable it too if present.
    if su - "$REAL_USER" -c "command -v balooctl" &>/dev/null; then
        su - "$REAL_USER" -c "balooctl disable" 2>/dev/null
        echo -e "  ${GREEN}[✓]${NC} Baloo file indexer disabled (KDE)"
    fi

    echo -e "${GREEN}[✓] Tracker/Baloo disabled${NC}"
}

# Function: Clean system
clean_system() {
    echo -e "${YELLOW}[*] Cleaning system...${NC}"
    
    # Clean apt cache
    apt clean
    echo -e "  ${GREEN}[✓]${NC} Cleaned apt cache"
    
    # Remove old packages
    apt autoremove -y
    echo -e "  ${GREEN}[✓]${NC} Removed unused packages"
    
    # Clean journal logs (keep last 3 days)
    journalctl --vacuum-time=3d &>/dev/null
    echo -e "  ${GREEN}[✓]${NC} Cleaned old journal logs"
    
    # Clean thumbnail cache
    REAL_USER="${SUDO_USER:-$USER}"
    REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
    rm -rf "$REAL_HOME/.cache/thumbnails/*" 2>/dev/null
    echo -e "  ${GREEN}[✓]${NC} Cleaned thumbnail cache"
    
    echo -e "${GREEN}[✓] System cleaning complete${NC}"
}

# Function: Clear RAM cache
clear_ram() {
    echo -e "${YELLOW}[*] Clearing RAM cache...${NC}"
    
    # Sync and clear
    sync
    echo 3 > /proc/sys/vm/drop_caches
    
    echo -e "${GREEN}[✓] RAM cache cleared${NC}"
    
    # Show current memory
    echo ""
    echo -e "${CYAN}Current memory status:${NC}"
    free -h
}

# Function: Apply all optimizations
apply_all() {
    echo -e "${YELLOW}[*] Applying ALL optimizations...${NC}"
    echo ""
    
    disable_services
    echo ""
    optimize_system
    echo ""
    install_preload
    echo ""
    install_browser
    echo ""
    disable_kde_effects
    echo ""
    disable_tracker
    echo ""
    clean_system
    echo ""
    clear_ram
    
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║        ALL OPTIMIZATIONS APPLIED SUCCESSFULLY!                ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}[!] Recommended: Reboot your system for all changes to take effect${NC}"
    echo -e "${CYAN}    sudo reboot${NC}"
}

# Main loop
while true; do
    show_menu
    read -p "Enter your choice [0-9]: " choice
    echo ""
    
    case $choice in
        1) disable_services ;;
        2) optimize_system ;;
        3) install_preload ;;
        4) install_browser ;;
        5) disable_kde_effects ;;
        6) disable_tracker ;;
        7) clean_system ;;
        8) clear_ram ;;
        9) apply_all ;;
        0) echo -e "${GREEN}Goodbye!${NC}"; exit 0 ;;
        *) echo -e "${RED}Invalid option. Please try again.${NC}" ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
done
OPTSCRIPT

    chmod +x "$OPT_SCRIPT"
    
    echo -e "  ${GREEN}Optimization script generated: ${OPT_SCRIPT}${NC}"
    echo ""
    echo -e "  ${WHITE}Run with: ${CYAN}sudo bash ${OPT_SCRIPT}${NC}"
    echo ""
    echo -e "  ${BOLD}The script provides a menu to:${NC}"
    echo "    1) Disable unnecessary startup services (incl. plymouth boot splash)"
    echo "    2) Optimize system settings (swappiness, cache, GRUB boot timeout)"
    echo "    3) Install preload for faster app launching"
    echo "    4) Install Chromium (lighter browser)"
    echo "    5) Disable KDE desktop effects"
    echo "    6) Disable tracker / Baloo file indexer"
    echo "    7) Clean system cache"
    echo "    8) Clear RAM cache"
    echo "    9) Apply ALL optimizations at once"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════
# MAIN EXECUTION
# ═══════════════════════════════════════════════════════════════════════════

main() {
    banner
    
    # Run all checks
    check_system_info
    check_desktop_session
    check_guest_additions
    check_clipboard_dragdrop
    check_graphics
    check_cpu
    check_memory
    check_storage
    check_network
    check_shared_folders
    check_services
    check_parrot_tools
    check_logs_for_errors
    check_boot_time
    check_startup_services
    check_performance_metrics
    check_browsers
    
    # Show fixes and summary
    show_fixes
    generate_fix_script
    show_summary
    
    # Show comprehensive tables at the end
    show_issues_table
    show_quick_commands_table
    show_optimization_table
    generate_optimization_script
    
    # Final message
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}  Script completed. Review the tables above for issues and solutions.${NC}"
    echo -e ""
    echo -e "${YELLOW}  To apply optimizations, run:${NC}"
    echo -e "${WHITE}    sudo bash /tmp/parrot_optimize.sh${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════════${NC}"
    echo ""
}

# Run main function
main "$@"
