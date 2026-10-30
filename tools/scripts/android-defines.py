"""A11 D13, A50 D4: merge private build configuration; never report input values.

Usage: android-defines.py [--google] <config.json> <destination> <flavor>

--google (build-android.sh passes it only for release builds signed with the
release key) sets FB_GOOGLE_SERVER_CLIENT_ID from the environment, else from
WebClientId in the private B04 file (FB_GOOGLE_CLIENTS_FILE, default
~/.local/share/fitness-buddy/identity/google-clients.json), else the committed
"" (Google sign-in hidden). Without --google it is always "".
"""
import ipaddress
import json
import os
import re
import sys
from urllib.parse import urlsplit


GOOGLE_KEY = 'FB_GOOGLE_SERVER_CLIENT_ID'
GOOGLE_ID = re.compile(r'[0-9]+-[a-z0-9]+\.apps\.googleusercontent\.com')


def google_client_id(committed):
    """(value, source) for a release-key build; the value is never printed."""
    if os.environ.get(GOOGLE_KEY):
        return os.environ[GOOGLE_KEY], 'the environment'
    path = os.path.expanduser(os.environ.get('FB_GOOGLE_CLIENTS_FILE') or
                              '~/.local/share/fitness-buddy/identity/google-clients.json')
    if os.path.isfile(path):
        try:
            with open(path, encoding='utf-8') as stream:
                return json.load(stream)['WebClientId'], path
        except (ValueError, KeyError, TypeError, OSError):
            return None, path
    return committed, 'none'


def main():
    args = sys.argv[1:]
    google = '--google' in args
    if google:
        args.remove('--google')
    source, destination, flavor = args
    with open(source, encoding='utf-8') as stream:
        values = json.load(stream)
    for key in ('FB_API_BASE_URL', 'FB_SENTRY_DSN'):
        # Actions supplies empty strings for unavailable secrets (fork PRs).
        if os.environ.get(key):
            values[key] = os.environ[key]
    try:
        url = values['FB_API_BASE_URL']
        parsed = urlsplit(url)
        valid = (parsed.scheme == 'https' and parsed.hostname and
                 parsed.netloc and not parsed.username and not parsed.password and
                 not parsed.path and not parsed.query and not parsed.fragment and
                 not any(c.isspace() or ord(c) < 32 for c in url) and
                 '?' not in url and '#' not in url and '@' not in parsed.netloc)
        port = parsed.port
        host = parsed.hostname or ''
        if ':' in host:
            ipaddress.IPv6Address(host)
            authority = '[' + host + ']'
        else:
            if len(host) > 253 or not all(re.fullmatch(r'[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?', label)
                                          for label in host.split('.')):
                raise ValueError()
            authority = host
        if port is not None:
            if not 1 <= port <= 65535:
                raise ValueError()
            authority += ':' + str(port)
        valid = valid and parsed.netloc.lower() == authority.lower()
        if not valid:
            raise ValueError()
    except (ValueError, KeyError, TypeError):
        print('build-android: error: FB_API_BASE_URL must be HTTPS host[:port] only', file=sys.stderr)
        return 1
    dsn = values.get('FB_SENTRY_DSN')
    if not isinstance(dsn, str) or (dsn and not re.fullmatch(
            r'https://[A-Za-z0-9]+@o[0-9]+\.ingest\.de\.sentry\.io/[0-9]+', dsn)):
        print('build-android: error: FB_SENTRY_DSN must be an HTTPS EU ingest DSN', file=sys.stderr)
        return 1
    google_id, google_source = (google_client_id(values.get(GOOGLE_KEY, ''))
                                if google else ('', 'none'))
    if not isinstance(google_id, str) or (google_id and not GOOGLE_ID.fullmatch(google_id)):
        print('build-android: error: ' + GOOGLE_KEY + ' (from ' + google_source +
              ') must be a Google OAuth web client ID', file=sys.stderr)
        return 1
    values[GOOGLE_KEY] = google_id
    print('build-android: Google sign-in: ' +
          ('on (client ID from ' + google_source + ')' if google_id else 'off'))
    with open(destination, 'w', encoding='utf-8') as stream:
        json.dump(values, stream)
    return 0


if __name__ == '__main__':
    sys.exit(main())
