"""A11 / PR-11: loopback-only synthetic Sentry envelope proof; no body logging.

serve --out DIR; check --out DIR. Never use real user data with this sink.
Captured bytes are private files, decoded before validation (gzip/deflate).
"""
import argparse
from http.server import BaseHTTPRequestHandler, HTTPServer
import json
import os
from pathlib import Path
import sys
import zlib

CANARY = b"FB_A11_CANARY_shawarma_250g"
LIMIT = 8 * 1024 * 1024
FORBIDDEN = {"user", "request", "extra", "server_name", "device_app_hash",
             "device_unique_identifier", "installation_id", "install_id", "device_id",
             "ip_address"}


def decode_body(body, encoding):
    if encoding == "gzip":
        # Bounded decompression, including compressed input from untrusted senders.
        decoder = zlib.decompressobj(16 + zlib.MAX_WBITS)
    elif encoding == "deflate":
        decoder = zlib.decompressobj()
    elif encoding in ("", "identity"):
        return body
    else:
        raise ValueError("unsupported encoding")
    result = decoder.decompress(body, LIMIT + 1)
    if len(result) > LIMIT or not decoder.eof or decoder.unused_data:
        raise ValueError("invalid compressed envelope")
    return result


def events(body):
    """Parse byte lengths, not line splits: item payloads may contain newlines."""
    header, sep, remaining = body.partition(b"\n")
    if not sep or not isinstance(json.loads(header), dict):
        raise ValueError("invalid envelope")
    result = []
    while remaining:
        header, sep, remaining = remaining.partition(b"\n")
        if not sep:
            raise ValueError("missing item header")
        item = json.loads(header)
        length = item.get("length")
        if length is None:
            payload, _, remaining = remaining.partition(b"\n")
        elif isinstance(length, int) and 0 <= length <= len(remaining):
            payload, remaining = remaining[:length], remaining[length:]
            if remaining.startswith(b"\n"):
                remaining = remaining[1:]
        else:
            raise ValueError("invalid item length")
        if item.get("type") != "event":
            raise ValueError("non-error item")
        event = json.loads(payload)
        if not isinstance(event, dict):
            raise ValueError("invalid event")
        result.append(event)
    if not result:
        raise ValueError("empty envelope")
    return result


def validate(body):
    if CANARY in body:
        raise ValueError("canary leaked")
    result = events(body)

    def walk(value):
        if isinstance(value, dict):
            for key, child in value.items():
                if key in FORBIDDEN:
                    raise ValueError("forbidden field")
                walk(child)
        elif isinstance(value, list):
            for child in value:
                walk(child)

    for event in result:
        walk(event)
        contexts = event.get("contexts", {})
        if any(key in contexts.get("device", {}) for key in ("name", "id")):
            raise ValueError("device identity leaked")
        if any(key != "flavor" or value not in {"dev", "staging", "prod"}
               for key, value in event.get("tags", {}).items()):
            raise ValueError("unapproved tags")
        for exception in event.get("exception", {}).get("values", []):
            if exception.get("value") != "[scrubbed]":
                raise ValueError("unscrubbed exception")
    return result


def server(out, port):
    out.mkdir(mode=0o700, parents=True, exist_ok=False)

    class Handler(BaseHTTPRequestHandler):
        def log_message(self, *_):
            pass  # HTTP paths/headers/body must never reach stdout.

        def do_POST(self):
            try:
                if self.path != "/api/1/envelope/":
                    raise ValueError("unexpected endpoint")
                length = int(self.headers.get("Content-Length", "0"))
                if not 0 < length <= LIMIT:
                    raise ValueError("invalid body size")
                raw = self.rfile.read(length)
                body = decode_body(raw, self.headers.get("Content-Encoding", ""))
                # Preserve failures too: a later check must fail, never hide a leak.
                target = out / f"{len(list(out.glob('*.envelope'))):06d}.envelope"
                with target.open("xb") as capture:
                    os.chmod(target, 0o600)
                    capture.write(body)
                validate(body)
            except Exception:
                # Fixed marker makes malformed/undecodable requests fail check too.
                (out / "FAILED").touch(mode=0o600)
                self.send_response(400)
            else:
                self.send_response(200)
            self.end_headers()
            self.wfile.write(b"{}")

    return HTTPServer(("127.0.0.1", port), Handler)


def check(out, expected_reports=2):
    if (out / "FAILED").exists():
        raise ValueError("capture failed privacy/format validation")
    captured = [event for path in sorted(out.glob("*.envelope"))
                for event in validate(path.read_bytes())]
    mechanisms = [exception.get("mechanism", {}).get("handled")
                  for event in captured
                  for exception in event.get("exception", {}).get("values", [])
                  if exception.get("type") == "TestErrorReport"]
    if (len(captured) != expected_reports or
            mechanisms.count(True) != expected_reports // 2 or
            mechanisms.count(False) != expected_reports // 2):
        raise ValueError("expected exactly handled and unhandled test reports")
    print(f"PASS: {expected_reports} scrubbed test reports; no native or non-error envelopes")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("serve", "check"))
    parser.add_argument("--out", required=True, type=Path)
    parser.add_argument("--port", type=int, default=8765)
    parser.add_argument("--expected-reports", type=int, choices=(2, 4), default=2)
    args = parser.parse_args()
    try:
        if args.command == "serve":
            with server(args.out, args.port) as sink:
                print("Loopback sink ready", flush=True)
                sink.serve_forever()
        else:
            check(args.out, args.expected_reports)
    except KeyboardInterrupt:
        pass
    except Exception:
        print("FAIL: envelope proof incomplete or privacy validation failed", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
