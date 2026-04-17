#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "usage: $0 <file-path> [lookup-info]" >&2
  exit 1
fi

FILE_PATH="$1"
LOOKUP_INFO="${2:-file:$FILE_PATH}"

if [[ ! -f "$FILE_PATH" ]]; then
  echo "file not found: $FILE_PATH" >&2
  exit 1
fi

CURL_BIN="${CURL_BIN:-curl}"
X_API_KEY="${CRYPTOWERK_X_API_KEY:-}"
if [[ -z "$X_API_KEY" ]]; then
  echo "set CRYPTOWERK_X_API_KEY to the exact cap token value before calling register-file.sh" >&2
  echo "expected format: apiKey credential" >&2
  exit 1
fi

HASH=$(shasum -a 256 "$FILE_PATH" | awk '{print $1}')
REGISTER_RESPONSE=$($CURL_BIN -sS -X POST "https://aiagent.cryptowerk.com/platform/API/v8/register" \
  -H "Accept: application/json" \
  -H "X-API-Key: $X_API_KEY" \
  --get \
  --data-urlencode "hashes=$HASH" \
  --data-urlencode "lookupInfo=$LOOKUP_INFO")

RID=$(printf '%s' "$REGISTER_RESPONSE" | python3 -c '
import json,sys
obj=json.load(sys.stdin)
docs=obj.get("documents") or []
if docs and docs[0].get("retrievalId"):
    print(docs[0]["retrievalId"])
    raise SystemExit(0)
raise SystemExit("Could not extract retrievalId")
')

printf '%s\n' "$RID" > "$FILE_PATH.rid"
python3 - <<PY
import json
from datetime import datetime, timezone
meta={
  "version": 1,
  "sourcePath": "$FILE_PATH",
  "lookupInfo": "$LOOKUP_INFO",
  "sha256": "$HASH",
  "retrievalId": "$RID",
  "registeredAt": datetime.now(timezone.utc).isoformat(),
  "sealPath": "$FILE_PATH.seal",
  "verifyPath": "$FILE_PATH.verify.json",
  "lastSealReceivedAt": None,
  "lastVerifiedAt": None,
  "lastError": None,
}
with open("$FILE_PATH.cw.json","w") as f:
    json.dump(meta,f,indent=2)
    f.write("\n")
PY

printf '%s\n' "$REGISTER_RESPONSE"
