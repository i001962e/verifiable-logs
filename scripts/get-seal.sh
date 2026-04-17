#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "usage: $0 <rid-file|retrieval-id>" >&2
  exit 1
fi

INPUT="$1"
if [[ -f "$INPUT" ]]; then
  RID=$(tr -d '\n' < "$INPUT")
  BASE_PATH="${INPUT%.rid}"
else
  RID="$INPUT"
  BASE_PATH=""
fi

CURL_BIN="${CURL_BIN:-curl}"
X_API_KEY="${CRYPTOWERK_X_API_KEY:-}"
if [[ -z "$X_API_KEY" ]]; then
  echo "set CRYPTOWERK_X_API_KEY to the cap token before calling get-seal.sh" >&2
  exit 1
fi

RESPONSE=$($CURL_BIN -sS -X POST "https://aiagent.cryptowerk.com/platform/API/v8/getseal" \
  -H "Accept: application/json" \
  -H "X-API-Key: $X_API_KEY" \
  --get \
  --data-urlencode "retrievalId=$RID" \
  --data-urlencode "provideVerificationInfos=true")

if [[ -n "$BASE_PATH" ]]; then
  printf '%s\n' "$RESPONSE" > "$BASE_PATH.seal"
fi

printf '%s\n' "$RESPONSE"
