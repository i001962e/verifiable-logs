#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "usage: $0 <file-path> <address> [lookup-info]" >&2
  exit 1
fi

FILE_PATH="$1"
ADDRESS="$2"
LOOKUP_INFO="${3:-file:$FILE_PATH}"

if [[ ! -f "$FILE_PATH" ]]; then
  echo "file not found: $FILE_PATH" >&2
  exit 1
fi

if [[ -z "${CURL_BIN:-}" ]]; then
  CURL_BIN="curl"
fi

HASH=$(shasum -a 256 "$FILE_PATH" | awk '{print $1}')
TOKEN_RESPONSE=$($CURL_BIN -sS -X POST "https://proof.cryptowerk.com/api/get-cap-token" \
  -H "Content-Type: application/json" \
  -d "{\"address\":\"$ADDRESS\"}")

X_API_KEY=$(printf '%s' "$TOKEN_RESPONSE" | python3 - <<'PY'
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
PY
)

REGISTER_RESPONSE=$($CURL_BIN -sS -X POST "https://aiagent.cryptowerk.com/platform/API/v8/register" \
  -H "Accept: application/json" \
  -H "X-API-Key: $X_API_KEY" \
  --get \
  --data-urlencode "hashes=$HASH" \
  --data-urlencode "lookupInfo=$LOOKUP_INFO")

RID=$(printf '%s' "$REGISTER_RESPONSE" | python3 - <<'PY'
import json,sys
obj=json.load(sys.stdin)
docs=obj.get("documents") or []
if docs and docs[0].get("retrievalId"):
    print(docs[0]["retrievalId"])
    raise SystemExit(0)
raise SystemExit("Could not extract retrievalId")
PY
)

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
