#!/usr/bin/env python3
"""B25 exit criterion 2: a scripted Buddy agent turn smoke against a running API (the laptop server).

Paid: every model step is a real provider send. Nothing runs without --live. Scenarios and their sends:
  log     "2 eggs": one proposal, the templated one-liner, done (1 send)
  phone   a diary question: phoneTools, a wrong-call-ID continue (error invalid, no send), the real continue, done (2+ sends)
  retry   a stream killed after its first proposal, retried once with priorAttempt (attempt 2, new card IDs, the same
          single message charge; 2+ sends), then an acknowledged replay that must answer 409 (no send)
Pick with --scenario (repeatable; default: log). Uses a fresh guest account; content stays in this terminal only.

  python3 tools/scripts/buddy-agent-smoke.py --live --base-url http://127.0.0.1:5199 --scenario log
"""
import argparse
import http.client
import json
import os
import secrets
import sys
import time
import urllib.parse
import uuid


def uuid7():
    ms = int(time.time() * 1000)
    raw = bytearray(ms.to_bytes(6, 'big') + secrets.token_bytes(10))
    raw[6] = (raw[6] & 0x0F) | 0x70
    raw[8] = (raw[8] & 0x3F) | 0x80
    return str(uuid.UUID(bytes=bytes(raw)))


class Api:
    def __init__(self, base, version):
        self.url = urllib.parse.urlparse(base)
        self.headers = {'X-App-Version': version, 'X-Platform': 'android', 'X-Device-Id': str(uuid.uuid4())}

    def connection(self):
        cls = http.client.HTTPSConnection if self.url.scheme == 'https' else http.client.HTTPConnection
        return cls(self.url.hostname, self.url.port, timeout=90)

    def sign_in(self):
        conn = self.connection()
        conn.request('POST', '/v1/auth/anonymous', headers=self.headers)
        response = conn.getresponse()
        body = response.read()
        if response.status != 200:
            raise SystemExit(f'guest sign-in failed: {response.status}')
        self.headers['Authorization'] = 'Bearer ' + json.loads(body)['accessToken']

    def stream(self, path, turn_id, body, stop_after=None):
        """POST and read SSE events; stop_after(event) True closes the connection early (a killed stream)."""
        conn = self.connection()
        headers = dict(self.headers, **{'Content-Type': 'application/json', 'Idempotency-Key': turn_id})
        conn.request('POST', path, body=json.dumps(body, ensure_ascii=False).encode(), headers=headers)
        response = conn.getresponse()
        if response.getheader('Content-Type', '').split(';')[0] != 'text/event-stream':
            payload = response.read().decode(errors='replace')
            conn.close()
            return response.status, [], payload
        events, frame = [], {}
        while True:
            line = response.readline()
            if not line:
                break
            line = line.decode().rstrip('\n')
            if line == '':
                if 'data' in frame:
                    event = json.loads(frame['data'])
                    event['_id'] = frame.get('id')
                    events.append(event)
                    print(f"  {event['_id']}  {event['type']}" + (f"  {event.get('code') or event.get('reason') or ''}"))
                    if stop_after and stop_after(event):
                        conn.close()
                        return response.status, events, 'killed'
                    if event['type'] in ('phoneTools', 'done', 'error'):
                        break
                frame = {}
            elif line.startswith(':'):
                continue
            elif ':' in line:
                key, value = line.split(':', 1)
                frame[key] = value[1:] if value.startswith(' ') else value
        conn.close()
        return response.status, events, ''


def start_body(turn_id, text, ack=None, prior=None):
    now = time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime())
    return {
        'turnId': turn_id, 'mode': 'chat', 'message': {'text': text, 'image': None}, 'history': [], 'summary': None, 'compact': None,
        'personal': [],
        'profile': {'memory': [], 'defaults': [], 'halal': True, 'units': {'mass': 'kg', 'length': 'cm', 'energy': 'kcal'},
                    'ramadan': {'active': False, 'fajr': None, 'maghrib': None}},
        'snapshot': {'now': now, 'tzOffsetMin': 120, 'slots': [],
                     'today': {'kcal': 900, 'proteinG': 40, 'carbsG': 100, 'fatG': 30, 'fiberG': 10,
                               'targets': {'kcal': 2100, 'proteinG': 120, 'carbsG': None, 'fatG': None, 'fiberG': None}},
                     'openCards': []},
        'ackTurn': {'turnId': ack} if ack else None, 'priorAttempt': prior, 'trace': True,
    }


SYNTHETIC = {
    'readDiary': {'truncated': False, 'entries': [{'id': str(uuid.uuid4()), 'date': time.strftime('%Y-%m-%d'), 'slot': 'Lunch',
                                                  'name': 'chicken shawarma sandwich', 'grams': 250, 'kcal': 610}]},
    'findMyFoods': {'items': []}, 'readMemory': {'items': []}, 'readBody': {'values': [], 'trend': None},
    'readWorkouts': {'sessions': [], 'prs': []},
}


def answer(call):
    data = SYNTHETIC.get(call['name'])
    return {'name': call['name'], 'callId': call['callId'], 'ok': data is not None, 'error': None if data is not None else 'unavailable', 'data': data}


def check(condition, message):
    print(('  ok    ' if condition else '  FAIL  ') + message)
    return condition


def scenario_log(api):
    turn = uuid7()
    status, events, _ = api.stream('/v1/buddy/turns', turn, start_body(turn, '2 eggs'))
    types = [e['type'] for e in events]
    done = events[-1] if events else {}
    return all([check(status == 200, '200 text/event-stream'), check('proposal' in types, 'a proposal card'),
                check('text' in types, 'a reply line'), check(done.get('type') == 'done', 'done'),
                check(done.get('usage', {}).get('sends') == 1, f"one send (got {done.get('usage', {}).get('sends')})")])


def scenario_phone(api):
    turn = uuid7()
    status, events, _ = api.stream('/v1/buddy/turns', turn, start_body(turn, 'what did I eat for lunch today?'))
    pause = next((e for e in events if e['type'] == 'phoneTools'), None)
    if not check(pause is not None, 'a phone-tool round (model chose to read the diary)'):
        return False
    body = {'turnId': turn, 'round': pause['round'], 'continuation': pause['continuation'], 'priorAttempt': None,
            'results': [answer(c) for c in pause['calls']]}
    wrong = dict(body, results=[dict(r, callId=str(uuid.uuid4())) for r in body['results']])
    _, bad, _ = api.stream('/v1/buddy/turns/continue', turn, wrong)
    ok = check([e.get('code') for e in bad] == ['invalid'], 'wrong call IDs → error invalid (no send)')
    _, events, _ = api.stream('/v1/buddy/turns/continue', turn, body)
    types = [e['type'] for e in events]
    return ok and check('text' in types and types[-1] == 'done', 'continue streams text and done')


def scenario_retry(api):
    turn = uuid7()
    text = '1 banana and 2 eggs for breakfast'
    _, first, outcome = api.stream('/v1/buddy/turns', turn, start_body(turn, text), stop_after=lambda e: e['type'] == 'proposal')
    cards = [e for e in first if e['type'] == 'proposal']
    if not check(outcome == 'killed' and cards, 'stream killed after the first proposal'):
        return False
    prior = {'attempt': 1, 'cards': [{'proposalId': c['proposalId'], 'status': 'pending', 'line': 'breakfast card'} for c in cards]}
    status, events, _ = api.stream('/v1/buddy/turns', turn, start_body(turn, text, prior=prior))
    retried = [e['proposalId'] for e in events if e['type'] == 'proposal']
    ok = all([check(status == 200 and events and events[-1]['type'] == 'done', 'the retry runs as attempt 2 and finishes'),
              check(not set(retried) & {c['proposalId'] for c in cards}, 'attempt-scoped card IDs (no reuse)')])
    print('  note  one message charge for both attempts: check the console Usage page (messages +1 for this turn)')
    nxt = uuid7()
    api.stream('/v1/buddy/turns', nxt, start_body(nxt, '1 apple', ack=turn))
    status, _, _ = api.stream('/v1/buddy/turns', turn, start_body(turn, text, prior=prior))
    return ok and check(status == 409, 'an acknowledged round answers 409 roundAlreadyRan (no send)')


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--live', action='store_true', help='required: these are paid provider sends')
    parser.add_argument('--base-url', default=os.environ.get('FB_API_BASE_URL', 'http://127.0.0.1:5199'))
    parser.add_argument('--app-version', default='1.0.0')
    parser.add_argument('--scenario', action='append', choices=['log', 'phone', 'retry'])
    args = parser.parse_args()
    if not args.live:
        raise SystemExit('refusing to run without --live (paid provider sends)')
    api = Api(args.base_url, args.app_version)
    api.sign_in()
    results = []
    for name in args.scenario or ['log']:
        print(f'scenario {name}')
        results.append({'log': scenario_log, 'phone': scenario_phone, 'retry': scenario_retry}[name](api))
    sys.exit(0 if all(results) else 1)


if __name__ == '__main__':
    main()
