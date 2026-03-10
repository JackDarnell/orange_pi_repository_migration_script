#!/usr/bin/env bash
#
# migrate-opi-sources.sh
#
# Migrates Orange Pi (Debian Bullseye) apt sources from Huawei Cloud mirrors
# to official Debian/Raspbian infrastructure.
#
# Tested on: Orange Pi Zero 2W running Orange Pi's Raspbian-based OS (Bullseye)
#
# Usage:
#   Copy this script to your Orange Pi and run:
#     chmod +x migrate-opi-sources.sh
#     sudo ./migrate-opi-sources.sh
#
#   Or run remotely via SSH:
#     ssh user@orangepi 'bash -s' < migrate-opi-sources.sh

set -euo pipefail

# --- Require root ---
if [[ $EUID -ne 0 ]]; then
    echo "Error: This script must be run as root (use sudo)." >&2
    exit 1
fi

SOURCES="/etc/apt/sources.list"
RASPI_LIST="/etc/apt/sources.list.d/raspi.list"

echo "========================================="
echo " Orange Pi Apt Source Migration Script"
echo "========================================="
echo

# --- Step 1: Gather system info ---
echo "[1/5] Gathering system info..."
echo
echo "OS:"
cat /etc/os-release | grep -E '^(PRETTY_NAME|VERSION_CODENAME)='
echo
echo "Kernel:"
uname -a
echo

# Detect codename
CODENAME=$(. /etc/os-release && echo "$VERSION_CODENAME")
if [[ -z "$CODENAME" ]]; then
    echo "Error: Could not detect VERSION_CODENAME from /etc/os-release." >&2
    exit 1
fi
echo "Detected suite: $CODENAME"
echo

# --- Step 2: Show current sources ---
echo "[2/5] Current apt sources:"
echo
echo "--- $SOURCES ---"
cat "$SOURCES"
echo

if [[ -f "$RASPI_LIST" ]]; then
    echo "--- $RASPI_LIST ---"
    cat "$RASPI_LIST"
    echo
fi

# --- Step 3: Back up ---
echo "[3/5] Creating backups..."

backup_file() {
    local file="$1"
    if [[ -f "$file" ]]; then
        local bak="${file}.bak.$(date +%Y%m%d%H%M%S)"
        cp "$file" "$bak"
        echo "  Backed up: $file -> $bak"
    fi
}

backup_file "$SOURCES"
[[ -f "$RASPI_LIST" ]] && backup_file "$RASPI_LIST"
echo

# --- Step 4: Replace mirrors ---
echo "[4/5] Replacing mirrors..."

changes_made=0

# Replace Huawei Cloud Debian mirrors -> deb.debian.org
if grep -q 'repo\.huaweicloud\.com/debian' "$SOURCES"; then
    # Main, updates, backports
    sed -i "s|http://repo\.huaweicloud\.com/debian |http://deb.debian.org/debian |g" "$SOURCES"
    # Security
    sed -i "s|http://repo\.huaweicloud\.com/debian-security |http://deb.debian.org/debian-security |g" "$SOURCES"
    echo "  Replaced repo.huaweicloud.com -> deb.debian.org in $SOURCES"
    changes_made=$((changes_made + 1))
else
    echo "  No Huawei Cloud entries found in $SOURCES (skipped)"
fi

# Handle archived repos: backports for bullseye are no longer on deb.debian.org
if grep -q "deb.debian.org/debian ${CODENAME}-backports" "$SOURCES"; then
    sed -i "s|http://deb.debian.org/debian ${CODENAME}-backports|http://archive.debian.org/debian ${CODENAME}-backports|g" "$SOURCES"
    echo "  Moved ${CODENAME}-backports -> archive.debian.org (archived from main CDN)"
    changes_made=$((changes_made + 1))
fi

# Replace Chinese Raspbian mirrors -> official archive
if [[ -f "$RASPI_LIST" ]]; then
    if grep -q 'mirrors\.ustc\.edu\.cn/archive\.raspberrypi\.org' "$RASPI_LIST"; then
        sed -i 's|http://mirrors\.ustc\.edu\.cn/archive\.raspberrypi\.org/debian/|http://archive.raspberrypi.org/debian/|g' "$RASPI_LIST"
        echo "  Replaced mirrors.ustc.edu.cn -> archive.raspberrypi.org in $RASPI_LIST"
        changes_made=$((changes_made + 1))
    elif grep -q 'mirrors\.tuna\.tsinghua\.edu\.cn/raspberrypi' "$RASPI_LIST"; then
        sed -i 's|http://mirrors\.tuna\.tsinghua\.edu\.cn/raspberrypi/|http://archive.raspberrypi.org/debian/|g' "$RASPI_LIST"
        echo "  Replaced mirrors.tuna.tsinghua.edu.cn -> archive.raspberrypi.org in $RASPI_LIST"
        changes_made=$((changes_made + 1))
    else
        echo "  No known Chinese mirrors found in $RASPI_LIST (skipped)"
    fi
fi

echo
if [[ $changes_made -eq 0 ]]; then
    echo "No changes were needed. Sources already point to official mirrors."
    exit 0
fi

# Show final state
echo "--- New $SOURCES ---"
cat "$SOURCES"
echo
if [[ -f "$RASPI_LIST" ]]; then
    echo "--- New $RASPI_LIST ---"
    cat "$RASPI_LIST"
    echo
fi

# --- Step 5: Verify with apt update ---
echo "[5/5] Running apt update to verify..."
echo
if apt update 2>&1; then
    echo
    echo "========================================="
    echo " Migration complete! All mirrors working."
    echo "========================================="
else
    echo
    echo "=========================================" >&2
    echo " Warning: apt update had errors." >&2
    echo " Backups are saved with .bak.TIMESTAMP" >&2
    echo " extension if you need to revert." >&2
    echo "=========================================" >&2
    exit 1
fi
