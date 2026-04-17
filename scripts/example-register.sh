#!/usr/bin/env bash
set -euo pipefail

# Example only.
# Replace credential acquisition with the real get cap token API call.

FILE_PATH="${1:-}"
if [[ -z "$FILE_PATH" ]]; then
  echo "usage: $0 <file>" >&2
  exit 1
fi

HASH=$(shasum -a 256 "$FILE_PATH" | awk '{print $1}')
echo "sha256=$HASH"

echo "TODO: call get cap token API and export X_API_KEY"
echo "TODO: call Cryptowerk register with hashes=$HASH"
