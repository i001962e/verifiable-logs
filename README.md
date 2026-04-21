# verifiable-logs

Minimal Cryptowerk-backed shell primitives for proof-carrying files and append-only logs.

## What is here

- `SKILL.md` documents the workflow and operating rules.
- `scripts/` contains shell-first helpers for token issuance, registration, seal retrieval, and verification.
- `references/` captures storage and API notes for extending the flow.
- `tests/` provides offline fixture tests that stub the network surface.

## Quick start

```bash
scripts/get-cap-token.sh 0xYOURADDRESS ~/.secrets/cryptowerk.cap
export CRYPTOWERK_X_API_KEY="$(cat ~/.secrets/cryptowerk.cap)"
scripts/register-file.sh /path/to/file.txt record:file.txt
scripts/get-seal.sh /path/to/file.txt.rid
scripts/verify-file.sh /path/to/file.txt /path/to/file.txt.seal
```

If you omit `lookupInfo`, `register-file.sh` uses `sha256:<digest>` to avoid leaking local filesystem paths. For stable application-level correlation, pass an explicit record key.

## Local artifacts

- `<file>.rid`
- `<file>.seal`
- `<file>.cw.json`
- `<file>.verify.json`

## Verification

Run the local checks with:

```bash
bash -n scripts/*.sh
python3 -m unittest -v tests.test_scripts
```

The tests do not call the live Cryptowerk APIs. They stub `curl` and validate parsing, escaping, and state-handling behavior.

## Publish notes

- The scripts expect `bash`, `curl`, and `python3`.
- SHA-256 hashing works with `shasum`, `sha256sum`, or `openssl`.
- No SDKs or callback server are required in the current MVP.
