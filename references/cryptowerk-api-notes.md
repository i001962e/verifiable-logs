# Cryptowerk API Notes

## Purpose
Reference notes for the verifiable-logs skill.

## Credential Flow
Use the get cap token API first.

Expected behavior:
- returns Cryptowerk API key material
- caller uses returned key and credential for Cryptowerk API calls
- do not call `aiagent.cryptowerk.com` directly to mint credentials

## Endpoints used after credential issuance
- `POST /API/v8/register`
- `POST /API/v8/getseal`
- `POST /API/v8/verifyseal`

## Register
Required core parameter:
- `hashes`

Useful optional parameters:
- `lookupInfo`
- `callback`
- `mode`

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

## Open Questions
Document the exact get cap token API request and response shape here before shipping automation.

## PR note
