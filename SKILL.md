---
name: verifiable-logs
description: Create and operate verifiable log workflows backed by Cryptowerk sealing. Use when building a skill or workflow that watches files or log streams, hashes stable content with SHA-256, obtains Cryptowerk capability credentials from the get cap token API, registers hashes, stores retrieval IDs and seals, and verifies proofs without calling aiagent.cryptowerk.com directly.
---

# Verifiable Logs

## Purpose
Build and operate deterministic verifiable logging pipelines on OpenClaw.

Use this skill to:
- watch files or append-only logs
- hash stable content with SHA-256
- obtain Cryptowerk API key material from the get cap token API
- register hashes with Cryptowerk
- persist retrieval IDs, seal objects, and local metadata
- verify seals against re-hashed content

Do not call `aiagent.cryptowerk.com` directly for credential issuance. Use the get cap token API first, then use the returned key and credential for Cryptowerk API calls.

## Required Layout

```text
verifiable-logs/
├── SKILL.md
├── references/
│   └── cryptowerk-api-notes.md
└── scripts/
    └── example-register.sh
```

## Core Behavior

### Operator Contract

1. Observe a target file or log append event
2. Wait until the target is stable
3. Compute SHA-256 over raw bytes
4. Obtain Cryptowerk capability credentials from the get cap token API
5. Register the hash with Cryptowerk
6. Persist the retrieval ID locally
7. Fetch or receive the seal object
8. Store the seal alongside local metadata
9. Re-hash the source when needed
10. Verify the seal against the hash

## Hashing Contract

- Algorithm: `SHA-256`
- Input: exact raw file bytes
- Trigger: create, modify, or append event
- Stability rule: size and mtime unchanged across two checks

Ignore:
- `.seal`
- `.cw.json`
- temp files like `*.swp`, `*.tmp`, `.DS_Store`

## Credential Issuance

### Rule
Use the get cap token API to obtain capability credentials before Cryptowerk register, getseal, or verifyseal calls.

### Requirements
- persist the returned key material securely
- use `0600` permissions for stored secrets
- never log credentials
- never echo credentials into chat
- refresh credentials according to API policy

If the get cap token API shape is not already documented locally, pause and add it under `references/` before automating writes.

## Registration

### Endpoint
`POST /API/v8/register`

### Required Parameters
- `hashes`
- `lookupInfo` when correlating callbacks or local records
- optional `callback` when asynchronous seal delivery is required

### Guidance
- prefer deterministic `lookupInfo`
- persist retrieval IDs immediately
- support both individual and bulk sealing modes if policy allows

## Seal Retrieval

### Endpoint
`POST /API/v8/getseal`

Use `retrievalId` to fetch the seal object after registration.

Persist the response as either:
- `<file>.seal` for a sidecar workflow, or
- a structured record in local state for log-oriented workflows

## Verification

### Endpoint
`POST /API/v8/verifyseal`

Verification flow:
1. re-hash source bytes
2. load stored seal object
3. call `verifyseal` with `verifyDocHashes` and `seals`
4. persist the response object
5. surface whether `verified` and `isComplete` are true

## Sidecar and Metadata Conventions

Recommended files:
- `<file>.rid` for retrieval ID
- `<file>.seal` for seal object
- `<file>.cw.json` for local metadata

Example metadata shape:

```json
{
  "version": 1,
  "sourcePath": "/data/log.txt",
  "sha256": "...",
  "retrievalId": "...",
  "registeredAt": "2026-04-17T00:00:00Z",
  "sealPath": "/data/log.txt.seal",
  "verifyPath": "/data/log.txt.verify.json",
  "callbackState": "pending",
  "lastSealReceivedAt": null,
  "lastVerifiedAt": null,
  "lastError": null
}
```

## Failure Handling

### Missing Seal
- keep retrieval ID
- retry `getseal`
- record last error

### Verification Failure
- do not overwrite source content
- persist the failed verification response
- report exact mismatch if available

### Unknown Callback
- spool orphan payloads under local state
- do not invent file mappings

## Security

- store secrets outside watched trees
- never log API keys or credentials
- enforce HTTPS callbacks
- validate callback authenticity when supported
- limit payload size

## Acceptance Criteria

A correct implementation must:
- hash stable content only
- use the get cap token API for credentials
- register hashes with Cryptowerk
- persist retrieval IDs
- fetch and store seal objects
- verify seal objects against re-hashed content
- survive restart without losing local state
- keep secrets out of logs and chat

## Usage Examples

### Example 1: Single file proof
- create `hello-agent.txt`
- hash it
- obtain capability credentials
- register hash
- store `hello-agent.rid`
- fetch and store `hello-agent.seal`
- re-hash file
- call `verifyseal`
- store verification response

### Example 2: Folder watcher
- watch a directory recursively
- debounce file events
- skip sidecars and temp files
- register only changed hashes
- maintain per-file `.rid`, `.seal`, and `.cw.json`

## References
Read `references/cryptowerk-api-notes.md` before implementing API calls.

## Scripts
Use `scripts/example-register.sh` as a minimal example only. Adapt it to the actual get cap token API contract before production use.
