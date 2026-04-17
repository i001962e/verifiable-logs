#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "usage: $0 <address-or-random-string> [output-file]" >&2
  exit 1
fi

IDENTITY="$1"
OUTPUT_FILE="${2:-}"
CURL_BIN="${CURL_BIN:-curl}"

RESPONSE=$($CURL_BIN -sS -X POST "https://proof.cryptowerk.com/api/get-cap-token" \
  -H "Content-Type: application/json" \
  -d "{\"address\":\"$IDENTITY\"}")

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
  umask 077
  printf '%s\n' "$X_API_KEY" > "$OUTPUT_FILE"
  echo "wrote cap token to $OUTPUT_FILE" >&2
else
  printf '%s\n' "$X_API_KEY"
fi
