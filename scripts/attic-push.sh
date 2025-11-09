#!/usr/bin/env bash
# Helper script to push to Attic cache while excluding large/problematic packages

set -euo pipefail

CACHE="${1:-main}"
PATHS="${2:-/run/current-system}"
PARALLEL="${3:-10}"

# Patterns to exclude (large packages that cause upload issues)
EXCLUDE_PATTERN="(davinci-resolve|blender|steam|wine|nvidia-x11|obs-studio|gimp)"

echo "Pushing to cache '$CACHE' with exclusions..."
echo "Excluded patterns: $EXCLUDE_PATTERN"

# Get all dependencies, filter out excluded packages, and push
nix-store -qR "$PATHS" | \
  grep -vE "$EXCLUDE_PATTERN" | \
  attic push "$CACHE" --stdin -j "$PARALLEL"

echo "✓ Push completed successfully!"
