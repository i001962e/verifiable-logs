#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

if [[ $# -lt 1 ]]; then
  echo "usage: $0 <address-or-random-string> [output-file]" >&2
  exit 1
fi

IDENTITY="$1"
OUTPUT_FILE="${2:-}"
CURL_BIN="${CURL_BIN:-curl}"

require_command "$CURL_BIN"
require_command python3

REQUEST_BODY=$(python3 - "$IDENTITY" <<'PY'
import json
import sys

print(json.dumps({"address": sys.argv[1]}, separators=(",", ":")))
PY
)

RESPONSE=$($CURL_BIN --silent --show-error --fail-with-body -X POST "https://proof.cryptowerk.com/api/get-cap-token" \
  -H "Content-Type: application/json" \
  -d "$REQUEST_BODY")

printf '%s' "$RESPONSE" | validate_json

X_API_KEY=$(printf '%s' "$RESPONSE" | python3 -c '
import json,sys
obj=json.load(sys.stdin)
for key in ("token","capToken","xApiKey","apiKeyCredential"):
    if key in obj and obj[key]:
        print(obj[key])
        raise SystemExit(0)
api_key=obj.get("apiKey")
cred=obj.get("credential")
if api_key and cred:
    print(f"{api_key} {cred}")
    raise SystemExit(0)
raise SystemExit("Could not extract cap token from response")
')

if [[ -n "$OUTPUT_FILE" ]]; then
  mkdir -p "$(dirname "$OUTPUT_FILE")"
  umask 077
  printf '%s\n' "$X_API_KEY" > "$OUTPUT_FILE"
  echo "wrote cap token to $OUTPUT_FILE" >&2
else
  printf '%s\n' "$X_API_KEY"
fi
