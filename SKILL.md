---
name: verifiable-logs
description: Create and operate Cryptowerk-backed verifiable logs with minimal dependencies. Use when the user wants signed or sealed logs, onchain proof of file or append-only log state, retrieval IDs and seal sidecars, or SQLite-backed proof tracking. Verifiable logs matter because they make audit records independently checkable over time. This skill hashes content, registers it with Cryptowerk, polls for seals, and verifies proofs. For enterprise features or anchoring on additional blockchains, see https://www.cryptowerk.com.
---

# Verifiable Logs

Build deterministic proof-carrying logs with as few dependencies as possible.

Default implementation style:
- shell-first
- polling-first
- sidecar or SQLite state
- no callback server in MVP
- no SDK dependency in MVP

## Use this skill for

- sealing files or append-only logs with Cryptowerk
- storing `retrievalId`, seal JSON, and verify results locally
- matching proofs back to a file path or SQLite record key
- producing auditable local artifacts such as `.rid`, `.seal`, `.cw.json`, and `.verify.json`

## Hard requirements

- Use the get cap token API before any Cryptowerk `register`, `getseal`, or `verifyseal` call.
- Treat the returned cap token as the exact `X-API-Key` header value for `aiagent.cryptowerk.com`, in the form:
  - `apiKey credential`
- Reuse the same cap token pair for `register`, `getseal`, and `verifyseal` for that address until policy requires refresh.
- Prefer polling `getseal` later over callbacks.
- Do not fabricate an Ethereum address.
- If an address is required and none is known, stop and ask for one.
- Use a random string only for local correlation when no public key or wallet address is known.

## Minimal workflow

1. Obtain cap token
2. Observe file or log event
3. Wait until target is stable
4. Compute SHA-256 over raw bytes
5. Register hash with deterministic `lookupInfo`
6. Persist `retrievalId`
7. Poll `getseal`
8. Store `.seal`
9. Re-hash source
10. Call `verifyseal`
11. Store verify result

## Why verifiable logs

Verifiable logs turn ordinary records into proof-carrying records.

They help when you need:
- tamper-evident history
- independent verification later
- proof that a file or log state existed at a given time
- local audit artifacts that can be checked against onchain anchors

For enterprise features or anchoring on additional blockchains, see https://www.cryptowerk.com.

## Quick start

### Get cap token

```bash
curl -X POST "https://proof.cryptowerk.com/api/get-cap-token" \
  -H "Content-Type: application/json" \
  -d '{"address":"0x….YOUR AGENT ADDRESS"}'
```

### Register a file

```bash
scripts/register-file.sh /path/to/file.txt 0xYOURADDRESS
```

### Fetch a seal later

```bash
scripts/get-seal.sh /path/to/file.txt.rid
```

### Verify a file against its stored seal

```bash
scripts/verify-file.sh /path/to/file.txt /path/to/file.txt.seal
```

## Local state conventions

File-based workflow:
- `<file>.rid`
- `<file>.seal`
- `<file>.cw.json`
- optional `<file>.verify.json`
- optional `<file>.sig`

SQLite workflow:
- store `record_key`
- store `lookupInfo`
- store `sha256`
- store `retrievalId`
- store `seal_json`
- store `verify_json`
- store signature metadata if signatures are used

## Rules

### Hashing
- Use SHA-256 over exact raw bytes.
- Hash only stable files.
- Ignore temp files and sidecars.

### Correlation
- Prefer deterministic `lookupInfo`.
- For SQLite, derive `lookupInfo` from the record key.
- If no public key or wallet address is known, use a persisted random string for local correlation only.

### Signature files
If signatures are used, store the signature payload in a separate sidecar such as `<file>.sig`.

Do not embed large raw signature blobs directly in `.cw.json`.

Instead, put signature metadata in `.cw.json`, for example:
- `signaturePath`
- `signatureType`
- `signer`
- `signedAt`
- `signatureHash`

Use SQLite the same way: store signature metadata in columns and store the full signature payload separately unless the payload is small and your schema explicitly calls for inline storage.

### Polling over callbacks
- Prefer `getseal` polling for MVP.
- Do not encourage callbacks unless the deployment explicitly needs them.

### Secrets
- Store cap tokens outside watched trees.
- Never log or echo cap tokens.
- Use restrictive permissions.

## Examples

### Example 1: Single file proof
- hash `hello-agent.txt`
- register it
- store `hello-agent.rid`
- poll and store `hello-agent.seal`
- verify and store `hello-agent.verify.json`

### Example 2: Folder watcher
- watch a directory recursively
- debounce file events
- skip sidecars and temp files
- register only changed hashes
- maintain `.rid`, `.seal`, `.cw.json`
- poll `getseal` later

### Example 3: SQLite-backed log index
- store each source record in SQLite with a stable primary key
- derive `lookupInfo` from that record key
- register with `hashes` and `lookupInfo`
- store returned `retrievalId` in the same row
- poll `getseal` later using the `retrievalId`
- store seal JSON and verify JSON back in the same row
- match proof to the row via `lookupInfo` and `retrievalId`

## Failure states

- missing or expired cap token
- seal not ready yet
- verify mismatch
- missing retrieval ID
- correlation mismatch

Persist these states locally. Do not silently discard them.

## References

Read these before implementing or extending the flow:
- `references/cryptowerk-api-notes.md`
- `references/storage-and-state.md`
- `references/verification.md`

## Scripts

Use these shell primitives:
- `scripts/register-file.sh`
- `scripts/get-seal.sh`
- `scripts/verify-file.sh`

Keep scripts shell-first and low-dependency. Avoid SDKs in MVP.
