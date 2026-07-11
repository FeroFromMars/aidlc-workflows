#!/usr/bin/env zsh
#
# sync-to-kiro.sh
#
# Copies the aidlc-workflows rule files into the .kiro folder for use by the IDE.
# By default, targets the sibling .kiro/ directory (same parent as this repo).
# Pass a directory argument to override the destination.
#
# Usage:
#   ./sync-to-kiro.sh              # copies to ../.kiro/
#   ./sync-to-kiro.sh /path/to/.kiro   # copies to specified directory

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_RULES="$SCRIPT_DIR/aidlc-rules"

# Determine destination
if [[ $# -ge 1 ]]; then
  DEST="$1"
else
  DEST="$(dirname "$SCRIPT_DIR")/.kiro"
fi

# Validate source exists
if [[ ! -d "$REPO_RULES" ]]; then
  echo "Error: Source rules directory not found at $REPO_RULES" >&2
  exit 1
fi

# Validate destination exists
if [[ ! -d "$DEST" ]]; then
  echo "Error: Destination directory not found at $DEST" >&2
  echo "Create it first or pass a valid path as argument." >&2
  exit 1
fi

echo "Source:      $REPO_RULES"
echo "Destination: $DEST"
echo ""

# Sync aws-aidlc-rule-details/
SRC_DETAILS="$REPO_RULES/aws-aidlc-rule-details"
DEST_DETAILS="$DEST/aws-aidlc-rule-details"

if [[ -d "$SRC_DETAILS" ]]; then
  echo "Syncing aws-aidlc-rule-details/ ..."
  rm -rf "$DEST_DETAILS"
  cp -R "$SRC_DETAILS" "$DEST_DETAILS"
  echo "  ✓ aws-aidlc-rule-details/"
fi

# Sync aws-aidlc-rules/ → steering/aws-aidlc-rules/
SRC_STEERING="$REPO_RULES/aws-aidlc-rules"
DEST_STEERING="$DEST/steering/aws-aidlc-rules"

if [[ -d "$SRC_STEERING" ]]; then
  echo "Syncing aws-aidlc-rules/ → steering/aws-aidlc-rules/ ..."
  mkdir -p "$DEST_STEERING"
  rm -rf "$DEST_STEERING"
  cp -R "$SRC_STEERING" "$DEST_STEERING"
  echo "  ✓ steering/aws-aidlc-rules/"
fi

echo ""
echo "Done. Rule files updated in $DEST"
