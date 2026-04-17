#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "usage: $0 <file-path> <seal-file>" >&2
  exit 1
fi

FILE_PATH="$1"
SEAL_FILE="$2"

if [[ ! -f "$FILE_PATH" ]]; then
  echo "file not found: $FILE_PATH" >&2
  exit 1
fi
if [[ ! -f "$SEAL_FILE" ]]; then
  echo "seal file not found: $SEAL_FILE" >&2
  exit 1
fi

CURL_BIN="${CURL_BIN:-curl}"
X_API_KEY="${CRYPTOWERK_X_API_KEY:-}"
if [[ -z "$X_API_KEY" ]]; then
  echo "set CRYPTOWERK_X_API_KEY to the cap token before calling verify-file.sh" >&2
  exit 1
fi

HASH=$(shasum -a 256 "$FILE_PATH" | awk '{print $1}')
SEAL=$(python3 - <<'PY' "$SEAL_FILE"
import json,sys
with open(sys.argv[1], 'r') as f:
    obj=json.load(f)
if 'seal' in obj:
    print(json.dumps(obj['seal'], separators=(',',':')))
else:
    docs=obj.get('documents') or []
    if docs and docs[0].get('seal'):
        print(json.dumps(docs[0]['seal'], separators=(',',':')))
    else:
        raise SystemExit('Could not extract seal object')
PY
)

RESPONSE=$($CURL_BIN -sS -X POST "https://aiagent.cryptowerk.com/platform/API/v8/verifyseal" \
  -H "Accept: application/json" \
  -H "X-API-Key: $X_API_KEY" \
  --get \
  --data-urlencode "verifyDocHashes=$HASH" \
  --data-urlencode "seals=$SEAL")

printf '%s\n' "$RESPONSE" > "$FILE_PATH.verify.json"
printf '%s\n' "$RESPONSE"
