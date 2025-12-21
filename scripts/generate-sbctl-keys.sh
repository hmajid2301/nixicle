#!/usr/bin/env bash
set -euo pipefail

# Script to generate sbctl Secure Boot keys for nixos-anywhere deployment
# This prepares signing keys that will be copied to the target system during installation

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info() {
    echo -e "${GREEN}[INFO]${NC} $*"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

# Check if sbctl is available
if ! command -v sbctl &> /dev/null; then
    error "sbctl not found. Please install it first:"
    echo "  nix-shell -p sbctl"
    exit 1
fi

# Check if /var/lib/sbctl already exists
if [ -d /var/lib/sbctl ]; then
    warn "/var/lib/sbctl already exists"
    read -p "Do you want to backup and recreate keys? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        info "Backing up existing keys to /var/lib/sbctl.bak"
        sudo mv /var/lib/sbctl /var/lib/sbctl.bak
    else
        info "Using existing keys"
        KEYS_EXIST=true
    fi
fi

# Create new keys if they don't exist or were backed up
if [ "${KEYS_EXIST:-false}" != "true" ]; then
    info "Creating new Secure Boot keys..."
    sudo sbctl create-keys
fi

# Export keys to temporary directory
info "Preparing keys for nixos-anywhere deployment..."
export MY_KEYS=$(mktemp -d)
mkdir -p "${MY_KEYS}/persist/var/lib"

# Copy keys
sudo cp -r /var/lib/sbctl "${MY_KEYS}/persist/var/lib/sbctl"

# Also copy to root level (for nixos-anywhere --extra-files)
sudo cp -r "${MY_KEYS}/persist/var" "${MY_KEYS}/"

# Fix permissions
sudo chown -R "$(id -u):$(id -g)" "$MY_KEYS"

info "Keys prepared at: $MY_KEYS"
info ""
info "Directory structure:"
tree -L 4 "$MY_KEYS" 2>/dev/null || find "$MY_KEYS" -type f

info ""
info "Use these keys with nixos-anywhere:"
echo "  export MY_KEYS=\"$MY_KEYS\""
echo "  nix run github:nix-community/nixos-anywhere -- \\"
echo "    --flake '.#framebox' \\"
echo "    --extra-files \"\$MY_KEYS\" \\"
echo "    --disk-encryption-keys /tmp/disk-encryption.key /path/to/password.txt \\"
echo "    --target-host user@target-ip"

info ""
warn "IMPORTANT: After deployment, you must manually enroll the keys on the target:"
echo "  ssh framebox"
echo "  sudo sbctl enroll-keys --microsoft"
echo "  sudo reboot"

# Restore backup if it was created
if [ -d /var/lib/sbctl.bak ]; then
    info ""
    read -p "Restore original sbctl keys? [Y/n] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        info "Restoring /var/lib/sbctl from backup"
        sudo rm -rf /var/lib/sbctl
        sudo mv /var/lib/sbctl.bak /var/lib/sbctl
    else
        warn "Backup left at /var/lib/sbctl.bak (remember to clean up later)"
    fi
fi

info ""
info "✓ Done! Keys ready at: $MY_KEYS"
info "  Remember to export MY_KEYS when running nixos-anywhere"
