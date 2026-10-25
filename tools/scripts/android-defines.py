"""A11 D13: merge private build configuration; never report input values."""
import ipaddress
import json
import os
import re
import sys
from urllib.parse import urlsplit


def main():
    source, destination, flavor = sys.argv[1:]
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
    with open(destination, 'w', encoding='utf-8') as stream:
        json.dump(values, stream)
    return 0


if __name__ == '__main__':
    sys.exit(main())
