#!/usr/bin/env bash
set -euo pipefail

# Automated NixOS deployment script using nixos-anywhere
# Supports Secure Boot with sbctl key management

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${GREEN}[INFO]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }
step() { echo -e "${BLUE}[STEP]${NC} $*"; }

# Usage
usage() {
    cat << EOF
Usage: $0 <host> <target-host> [options]

Arguments:
  host          Host configuration name (e.g., framebox)
  target-host   SSH target (e.g., user@192.168.1.100 or nixos@target-ip)

Options:
  --password-file FILE    Path to file containing LUKS password
  --no-secure-boot        Skip Secure Boot key generation
  --dry-run              Show what would be done without executing
  --help                 Show this help message

Examples:
  # Deploy framebox with Secure Boot
  $0 framebox nixos@192.168.1.100 --password-file /tmp/luks-pass.txt

  # Deploy without Secure Boot
  $0 workstation nixos@10.0.0.5 --password-file ./password.txt --no-secure-boot

Environment Variables:
  MY_KEYS         Pre-generated sbctl keys directory (optional)
  SSH_KEY         SSH key for authentication (optional)

Note:
  The password file will be passed to nixos-anywhere as /tmp/disk-encryption.key
  (this is the path disko expects in your configuration)

EOF
    exit 1
}

# Parse arguments
HOST=""
TARGET=""
PASSWORD_FILE=""
SECURE_BOOT=true
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --password-file)
            PASSWORD_FILE="$2"
            shift 2
            ;;
        --no-secure-boot)
            SECURE_BOOT=false
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --help|-h)
            usage
            ;;
        -*)
            error "Unknown option: $1"
            ;;
        *)
            if [ -z "$HOST" ]; then
                HOST="$1"
            elif [ -z "$TARGET" ]; then
                TARGET="$1"
            else
                error "Too many arguments"
            fi
            shift
            ;;
    esac
done

# Validate required arguments
[ -z "$HOST" ] && error "Host configuration required"
[ -z "$TARGET" ] && error "Target host required"

# Check if host configuration exists
if [ ! -f "$REPO_ROOT/hosts/$HOST/default.nix" ]; then
    error "Host configuration not found: hosts/$HOST/default.nix"
fi

# Check for password file
if [ -z "$PASSWORD_FILE" ]; then
    warn "No password file specified. You'll need to enter the LUKS password interactively."
    read -p "Continue? [y/N] " -n 1 -r
    echo
    [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1
elif [ ! -f "$PASSWORD_FILE" ]; then
    error "Password file not found: $PASSWORD_FILE"
fi

# Header
echo "═══════════════════════════════════════════════════════════"
echo "  NixOS Anywhere Deployment"
echo "═══════════════════════════════════════════════════════════"
echo "  Host:          $HOST"
echo "  Target:        $TARGET"
echo "  Secure Boot:   $([ "$SECURE_BOOT" = true ] && echo "✓ Enabled" || echo "✗ Disabled")"
echo "  Password:      $([ -n "$PASSWORD_FILE" ] && echo "From file" || echo "Interactive")"
echo "═══════════════════════════════════════════════════════════"
echo

# Check if host has Secure Boot enabled
if [ "$SECURE_BOOT" = true ]; then
    step "Checking Secure Boot configuration..."
    if grep -q 'secureBoot.*=.*true' "$REPO_ROOT/hosts/$HOST/default.nix"; then
        info "Secure Boot is enabled in host configuration ✓"
    else
        warn "Secure Boot not enabled in host configuration"
        read -p "Continue anyway? [y/N] " -n 1 -r
        echo
        [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1
    fi
fi

# Generate or check sbctl keys
if [ "$SECURE_BOOT" = true ]; then
    if [ -z "${MY_KEYS:-}" ]; then
        step "Generating Secure Boot keys..."
        if [ "$DRY_RUN" = true ]; then
            info "[DRY RUN] Would run: $SCRIPT_DIR/generate-sbctl-keys.sh"
        else
            "$SCRIPT_DIR/generate-sbctl-keys.sh"
            echo
            warn "Please run the generate-sbctl-keys.sh script first:"
            echo "  $SCRIPT_DIR/generate-sbctl-keys.sh"
            echo "Then export MY_KEYS and re-run this script"
            exit 1
        fi
    else
        info "Using existing sbctl keys at: $MY_KEYS"
        if [ ! -d "$MY_KEYS/persist/var/lib/sbctl" ]; then
            error "Invalid MY_KEYS directory structure"
        fi
    fi
fi

# Build nixos-anywhere command
NIXOS_ANYWHERE_CMD=(
    nix run github:nix-community/nixos-anywhere --
    --flake ".#$HOST"
)

# Add sbctl keys if Secure Boot is enabled
if [ "$SECURE_BOOT" = true ] && [ -n "${MY_KEYS:-}" ]; then
    NIXOS_ANYWHERE_CMD+=(--extra-files "$MY_KEYS")
fi

# Add password file if provided
# NOTE: disko expects the password at /tmp/disk-encryption.key
if [ -n "$PASSWORD_FILE" ]; then
    NIXOS_ANYWHERE_CMD+=(--disk-encryption-keys /tmp/disk-encryption.key "$PASSWORD_FILE")
fi

# Add target host
NIXOS_ANYWHERE_CMD+=(--target-host "$TARGET")

# Show command
step "Deployment command:"
echo "  ${NIXOS_ANYWHERE_CMD[*]}"
echo

# Confirm before proceeding
if [ "$DRY_RUN" = false ]; then
    warn "This will WIPE the target system and install NixOS!"
    read -p "Are you sure you want to continue? [y/N] " -n 1 -r
    echo
    [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1

    # Execute deployment
    step "Starting deployment..."
    "${NIXOS_ANYWHERE_CMD[@]}"

    # Post-deployment instructions
    echo
    echo "═══════════════════════════════════════════════════════════"
    echo "  Deployment Complete!"
    echo "═══════════════════════════════════════════════════════════"

    if [ "$SECURE_BOOT" = true ]; then
        echo
        warn "IMPORTANT: Manual post-deployment steps required:"
        echo
        echo "1. SSH into the target system:"
        echo "   ssh $TARGET"
        echo
        echo "2. Enroll Secure Boot keys:"
        echo "   sudo sbctl enroll-keys --microsoft"
        echo
        echo "3. Enroll TPM auto-unlock (if using):"
        echo "   sudo systemd-cryptenroll /dev/nvme0n1p2 \\"
        echo "     --tpm2-device=auto \\"
        echo "     --tpm2-pcrs=0+2+7 \\"
        echo "     --tpm2-pcrs=15:sha256=0000000000000000000000000000000000000000000000000000000000000000"
        echo
        echo "4. Reboot to activate Secure Boot:"
        echo "   sudo reboot"
        echo
    fi

    echo "═══════════════════════════════════════════════════════════"
else
    info "[DRY RUN] Would execute: ${NIXOS_ANYWHERE_CMD[*]}"
fi
