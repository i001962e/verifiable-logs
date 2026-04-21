# Storage and State

## Goal
Keep local proof state deterministic, queryable, and restart-safe.

## File-based state

Recommended sidecars:
- `.rid` for retrieval ID
- `.seal` for seal JSON
- `.cw.json` for local metadata
- `.verify.json` for stored verify response
- optional `.sig` for signature payload

Example metadata:

```json
{
  "version": 1,
  "sourcePath": "/data/file.txt",
  "lookupInfo": "file:/data/file.txt",
  "sha256": "...",
  "retrievalId": "...",
  "registeredAt": "2026-04-17T00:00:00Z",
  "sealPath": "/data/file.txt.seal",
  "verifyPath": "/data/file.txt.verify.json",
  "signaturePath": "/data/file.txt.sig",
  "signatureType": null,
  "signer": null,
  "signatureHash": null,
  "lastSealReceivedAt": null,
  "lastVerifiedAt": null,
  "lastError": null
}
```

## SQLite state

Recommended columns:
- `record_key`
- `lookup_info`
- `sha256`
- `retrieval_id`
- `seal_json`
- `verify_json`
- `signature_path`
- `signature_type`
- `signer`
- `signature_hash`
- `registered_at`
- `verified_at`
- `last_error`

Use SQLite when:
- proofs must map to application records
- append-only logs need query support
- you want one system of record for correlation

## Idempotency

Rules:
- same source + same hash should not re-register unless policy says so
- repeated `getseal` calls should overwrite seal state safely only when a seal is present
- repeated `verifyseal` calls should overwrite verify state safely
