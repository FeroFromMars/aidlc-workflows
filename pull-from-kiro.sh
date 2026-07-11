#!/usr/bin/env zsh
#
# pull-from-kiro.sh
#
# Pulls workspace .kiro/steering/ documents into this repository's .kiro/steering/
# so that changes made in the live workspace are captured in version control.
#
# Only copies top-level .md files from the workspace steering directory.
# Subdirectories (like aws-aidlc-rules/) are owned by this repo and are NOT pulled.
#
# By default, reads from the sibling .kiro/ directory (same parent as this repo).
# Pass a directory argument to override the source.
#
# Usage:
#   ./pull-from-kiro.sh              # pulls from ../.kiro/
#   ./pull-from-kiro.sh /path/to/.kiro   # pulls from specified directory

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEST_STEERING="$SCRIPT_DIR/.kiro/steering"

# Determine source
if [[ $# -ge 1 ]]; then
  SRC="$1"
else
  SRC="$(dirname "$SCRIPT_DIR")/.kiro"
fi

SRC_STEERING="$SRC/steering"

# Validate source exists
if [[ ! -d "$SRC_STEERING" ]]; then
  echo "Error: Source steering directory not found at $SRC_STEERING" >&2
  exit 1
fi

# Validate destination exists
if [[ ! -d "$DEST_STEERING" ]]; then
  echo "Error: Destination steering directory not found at $DEST_STEERING" >&2
  echo "Expected: $DEST_STEERING" >&2
  exit 1
fi

echo "Source:      $SRC_STEERING"
echo "Destination: $DEST_STEERING"
echo ""

# Copy top-level .md files only (skip subdirectories — those are owned by this repo)
count=0
for file in "$SRC_STEERING"/*.md; do
  if [[ -f "$file" ]]; then
    filename="$(basename "$file")"
    cp "$file" "$DEST_STEERING/$filename"
    echo "  ✓ $filename"
    count=$((count + 1))
  fi
done

echo ""
echo "Done. Pulled $count steering file(s) into $DEST_STEERING"
