"""PR-11 A11 envelope proof: synthetic data only, offline self-test."""
import contextlib
import gzip
import http.client
import importlib.util
import io
import json
from pathlib import Path
import tempfile
import threading
import unittest
import zlib

SPEC = importlib.util.spec_from_file_location(
    'sink', Path(__file__).with_name('sentry_envelope_sink.py'))
sink = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(sink)


def envelope(handled=True, **fields):
    payload = json.dumps({'exception': {'values': [{'type': 'TestErrorReport',
        'value': '[scrubbed]', 'mechanism': {'handled': handled}}]}, **fields}).encode()
    return b'{}\n' + json.dumps({'type': 'event', 'length': len(payload)}).encode() + b'\n' + payload + b'\n'


class SinkTests(unittest.TestCase):
    def test_gzip_deflate_and_byte_lengths(self):
        body = envelope(message={'formatted': 'safe\nArabic: عربي'})
        for encoding, data in [('', body), ('gzip', gzip.compress(body)),
                               ('deflate', zlib.compress(body))]:
            self.assertEqual(body, sink.decode_body(data, encoding))
            self.assertEqual(1, len(sink.validate(body)))

    def test_canary_identity_non_error_and_malformed_fail(self):
        for body in [envelope(message={'formatted': sink.CANARY.decode()}),
                     envelope(user={'id': 'install'}),
                     envelope(contexts={'device': {'name': 'phone'}}),
                     envelope(tags={'native': 'value'}),
                     envelope(contexts={'app': {'device_app_hash': 'id'}}),
                     b'{}\n{"type":"session"}\n{}\n', b'broken',
                     b'{}\n{"type":"event","length":999}\n{}']:
            with self.assertRaises((ValueError, KeyError)):
                sink.validate(body)

    def test_decompression_is_bounded_and_rejects_invalid_encoding(self):
        for data, encoding in [(gzip.compress(b'a' * (sink.LIMIT + 1)), 'gzip'),
                               (b'invalid', 'gzip'), (b'a', 'br')]:
            with self.assertRaises((ValueError, zlib.error)):
                sink.decode_body(data, encoding)

    def test_local_http_capture_and_proof_including_native_failure(self):
        with tempfile.TemporaryDirectory() as tmp:
            out = Path(tmp) / 'captures'
            server = sink.server(out, 0)
            thread = threading.Thread(target=server.serve_forever)
            thread.start()
            try:
                for handled in [True, False]:
                    client = http.client.HTTPConnection(*server.server_address)
                    client.request('POST', '/api/1/envelope/', gzip.compress(envelope(handled)),
                                   {'Content-Encoding': 'gzip'})
                    self.assertEqual(200, client.getresponse().status)
                    client.close()
                with contextlib.redirect_stdout(io.StringIO()) as output:
                    sink.check(out)
                self.assertIn('PASS', output.getvalue())
                self.assertEqual(0o700, out.stat().st_mode & 0o777)
                self.assertTrue(all(p.stat().st_mode & 0o777 == 0o600 for p in out.iterdir()))
                for handled in [True, False]:
                    client = http.client.HTTPConnection(*server.server_address)
                    client.request('POST', '/api/1/envelope/', envelope(handled))
                    self.assertEqual(200, client.getresponse().status)
                    client.close()
                with contextlib.redirect_stdout(io.StringIO()) as output:
                    sink.check(out, 4)
                self.assertIn('4 scrubbed', output.getvalue())
                client = http.client.HTTPConnection(*server.server_address)
                client.request('POST', '/api/1/envelope/', envelope(user={'id': 'native'}))
                self.assertEqual(400, client.getresponse().status)
                client.close()
                with self.assertRaises(ValueError):
                    sink.check(out)
            finally:
                server.shutdown()
                thread.join()
                server.server_close()

    def test_missing_or_extra_events_fail_proof(self):
        with tempfile.TemporaryDirectory() as tmp:
            out = Path(tmp)
            for count in [0, 1, 3]:
                for path in out.iterdir():
                    path.unlink()
                for n in range(count):
                    (out / f'{n}.envelope').write_bytes(envelope(n == 0))
                with self.assertRaises(ValueError):
                    sink.check(out)


if __name__ == '__main__':
    unittest.main()
