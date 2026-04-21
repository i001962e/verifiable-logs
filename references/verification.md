# Verification

## Purpose
Define how local content is checked against a stored Cryptowerk seal.

## Flow
1. Re-hash source bytes with SHA-256
2. Load stored seal JSON
3. Call `verifyseal`
4. Persist the response object
5. Surface `verified` and `isComplete`

## Inputs
- source bytes
- seal JSON
- cap token for the same address context

## Outputs
- raw verify response
- local `.verify.json` or SQLite `verify_json`

## Failure handling
- if `verified=false`, persist exact response
- if seal is missing, report blocker
- if retrieval ID is missing, report blocker
- if the file has changed since registration, verification should fail and must be recorded

## MVP rule
Use the hosted `verifyseal` API first. Local proof evaluation can be a future enhancement.
