# Cryptowerk API Notes

## Purpose
Reference notes for the verifiable-logs skill.

## Credential Flow
Use the get cap token API first.

Current expected behavior:
- returns one cap token pair per address sent
- the cap token is the exact `apiKey credential` value used in the `X-API-Key` header, with a literal space between `apiKey` and `credential`
- the same token pair is reused for `register`, `getseal`, and `verifyseal` for that address
- cap tokens are one-time retrievable from the get cap token API
- if the token is lost, request a new one using a new address or persisted random string
- do not call `aiagent.cryptowerk.com` directly to mint credentials

Preferred primitive:

```bash
scripts/get-cap-token.sh 0xYOURADDRESS ~/.secrets/cryptowerk.cap
export CRYPTOWERK_X_API_KEY="$(cat ~/.secrets/cryptowerk.cap)"
```

## Endpoints used after credential issuance
- `POST /API/v8/register`
- `POST /API/v8/getseal`
- `POST /API/v8/verifyseal`

Base host used by current skill:
- `https://aiagent.cryptowerk.com/platform`

## Register
Required core parameter:
- `hashes`

Useful optional parameters:
- `lookupInfo`
- `mode`

Guidance:
- prefer `lookupInfo` for correlation
- prefer polling `getseal` later over callbacks

## Get Seal
Useful parameters:
- `retrievalId`
- `provideVerificationInfos=true`

## Verify Seal
Required parameters:
- `verifyDocHashes`
- `seals`

## Storage Conventions
Recommended sidecars:
- `.rid`
- `.seal`
- `.cw.json`
- optional `.verify.json`

SQLite-oriented alternative:
- store `lookupInfo`, `retrievalId`, seal JSON, and verify JSON in columns tied to the application record key

## Identity Fallback
If no public key or wallet address is known, use a random string for local correlation only.

Rules:
- persist the random string locally
- do not present it as an Ethereum address
- do not fabricate an onchain identity from it

If the cap-token API requires an address and none exists, stop and request a real address.

## Operational rule
Token acquisition should be a separate step from registration. `register`, `getseal`, and `verifyseal` should consume an already-issued cap token and must not silently mint a new one.

## Open Questions
The exact get cap token response contract should be documented here once finalized. Until then, scripts should fail loudly if they cannot extract the cap token.
