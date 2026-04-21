import json
import os
import stat
import subprocess
import tempfile
import textwrap
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
SCRIPTS_DIR = REPO_ROOT / "scripts"


def write_executable(path: Path, content: str) -> None:
    path.write_text(content, encoding="utf-8")
    path.chmod(path.stat().st_mode | stat.S_IXUSR)


class ScriptTests(unittest.TestCase):
    maxDiff = None

    def setUp(self) -> None:
        self.tempdir = tempfile.TemporaryDirectory()
        self.tmp = Path(self.tempdir.name)
        self.bin_dir = self.tmp / "bin"
        self.bin_dir.mkdir()
        self.curl_log = self.tmp / "curl-log.json"
        self.env = os.environ.copy()
        self.env["PATH"] = f"{self.bin_dir}:{self.env['PATH']}"
        self.env["CRYPTOWERK_X_API_KEY"] = "api-key credential"

    def tearDown(self) -> None:
        self.tempdir.cleanup()

    def run_script(self, script_name: str, *args: str, check: bool = True) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [str(SCRIPTS_DIR / script_name), *args],
            cwd=REPO_ROOT,
            env=self.env,
            text=True,
            capture_output=True,
            check=check,
        )

    def install_curl_stub(self, mode: str, response: dict) -> None:
        stub = textwrap.dedent(
            f"""\
            #!/usr/bin/env bash
            set -euo pipefail

            mode="{mode}"
            log_path="{self.curl_log}"
            response_json='{json.dumps(response)}'

            python3 - "$mode" "$log_path" "$response_json" "$@" <<'PY'
            import json
            import sys

            mode = sys.argv[1]
            log_path = sys.argv[2]
            response_json = sys.argv[3]
            argv = sys.argv[4:]

            body = None
            query = []
            headers = []
            index = 0
            while index < len(argv):
                arg = argv[index]
                if arg == "-d":
                    body = argv[index + 1]
                    index += 2
                    continue
                if arg == "--data-urlencode":
                    query.append(argv[index + 1])
                    index += 2
                    continue
                if arg == "-H":
                    headers.append(argv[index + 1])
                    index += 2
                    continue
                index += 1

            payload = {{
                "mode": mode,
                "body": body,
                "query": query,
                "headers": headers,
            }}
            with open(log_path, "w", encoding="utf-8") as f:
                json.dump(payload, f)

            print(response_json)
            PY
            """
        )
        write_executable(self.bin_dir / "curl", stub)

    def test_get_cap_token_escapes_json_body(self) -> None:
        self.install_curl_stub("cap", {"apiKey": "issued", "credential": "secret"})

        identity = 'random"value\nwith newline'
        out = self.run_script("get-cap-token.sh", identity)

        self.assertEqual(out.stdout.strip(), "issued secret")
        logged = json.loads(self.curl_log.read_text(encoding="utf-8"))
        self.assertIsNotNone(logged["body"])
        self.assertEqual(json.loads(logged["body"]), {"address": identity})

    def test_register_file_handles_quoted_path_and_lookup_info(self) -> None:
        self.install_curl_stub("register", {"documents": [{"retrievalId": "rid-123"}]})

        file_path = self.tmp / 'proof "file".txt'
        file_path.write_text("hello world\n", encoding="utf-8")
        lookup_info = 'record:"quoted"/path'

        out = self.run_script("register-file.sh", str(file_path), lookup_info)

        self.assertIn('"retrievalId": "rid-123"', out.stdout)
        self.assertEqual((self.tmp / 'proof "file".txt.rid').read_text(encoding="utf-8").strip(), "rid-123")
        meta = json.loads((self.tmp / 'proof "file".txt.cw.json').read_text(encoding="utf-8"))
        self.assertEqual(meta["sourcePath"], str(file_path))
        self.assertEqual(meta["lookupInfo"], lookup_info)
        self.assertEqual(meta["retrievalId"], "rid-123")

    def test_get_seal_does_not_clobber_existing_file_when_pending(self) -> None:
        self.install_curl_stub("seal", {"documents": [{"status": "PENDING"}]})

        base = self.tmp / "audit.log"
        seal_path = self.tmp / "audit.log.seal"
        rid_path = self.tmp / "audit.log.rid"
        base.write_text("row\n", encoding="utf-8")
        seal_path.write_text('{"documents":[{"seal":{"kept":true}}]}\n', encoding="utf-8")
        rid_path.write_text("rid-123\n", encoding="utf-8")

        proc = self.run_script("get-seal.sh", str(rid_path), check=False)

        self.assertEqual(proc.returncode, 3)
        self.assertIn('"status": "PENDING"', proc.stdout)
        self.assertEqual(
            seal_path.read_text(encoding="utf-8"),
            '{"documents":[{"seal":{"kept":true}}]}\n',
        )

    def test_verify_file_writes_response(self) -> None:
        self.install_curl_stub("verify", {"verified": True, "isComplete": True})

        file_path = self.tmp / "artifact.txt"
        seal_path = self.tmp / "artifact.txt.seal"
        file_path.write_text("payload\n", encoding="utf-8")
        seal_path.write_text('{"documents":[{"seal":{"proof":"abc"}}]}\n', encoding="utf-8")

        out = self.run_script("verify-file.sh", str(file_path), str(seal_path))

        self.assertIn('"verified": true', out.stdout)
        verify_json = json.loads((self.tmp / "artifact.txt.verify.json").read_text(encoding="utf-8"))
        self.assertTrue(verify_json["verified"])


if __name__ == "__main__":
    unittest.main()
