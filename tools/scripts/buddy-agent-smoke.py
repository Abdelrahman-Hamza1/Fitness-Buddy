#!/usr/bin/env python3
"""B25 exit criterion 2 and B26 exit criterion 1: a scripted Buddy agent smoke against a running API (the laptop server).

Paid: every model step is a real provider send. Nothing runs without --live. Scenarios and their sends:
  log     "2 eggs": one proposal, the templated one-liner, done (1 send)
  phone   a diary question: phoneTools, a wrong-call-ID continue (error invalid, no send), the real continue, done (2+ sends)
  retry   a stream killed after its first proposal, retried once with priorAttempt (attempt 2, new card IDs, the same
          single message charge; 2+ sends), then an acknowledged replay that must answer 409 (no send)
  workout "push day bench 3x8 80, ohp 3x10 40, dips +10 3x8": a workout card with code-read sets (1 send)
  body    a waist measurement and a pasted weight list in one message: measurement + importRows cards (1 send)
  weekly  mode weeklyReview with synthetic aggregates: the code header + at most two observations, no tools (1–2 sends)
  label   POST /v1/buddy/label with --label-photo (a JPEG ≤ 1024 px of a nutrition panel): values and confidences (1 send)
Pick with --scenario (repeatable; default: log). Uses a fresh guest account; content stays in this terminal only.

  python3 tools/scripts/buddy-agent-smoke.py --live --base-url http://127.0.0.1:5199 --scenario log
"""
import argparse
import base64
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


    def post_json(self, path, body):
        conn = self.connection()
        conn.request('POST', path, body=json.dumps(body).encode(), headers=dict(self.headers, **{'Content-Type': 'application/json'}))
        response = conn.getresponse()
        payload = response.read().decode(errors='replace')
        conn.close()
        return response.status, payload


def start_body(turn_id, text, ack=None, prior=None, mode='chat', weekly=None):
    now = time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime())
    return {
        'turnId': turn_id, 'mode': mode, 'weekly': weekly, 'message': {'text': text, 'image': None}, 'history': [], 'summary': None, 'compact': None,
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
    prior = {'attempt': 1, 'cards': [{'proposalId': c['proposalId'], 'status': 'pending', 'revision': c['revision'], 'line': 'breakfast card'} for c in cards]}
    status, events, _ = api.stream('/v1/buddy/turns', turn, start_body(turn, text, prior=prior))
    retried = [e['proposalId'] for e in events if e['type'] == 'proposal']
    ok = all([check(status == 200 and events and events[-1]['type'] == 'done', 'the retry runs as attempt 2 and finishes'),
              check(not set(retried) & {c['proposalId'] for c in cards}, 'attempt-scoped card IDs (no reuse)')])
    print('  note  one message charge for both attempts: check the console Usage page (messages +1 for this turn)')
    nxt = uuid7()
    api.stream('/v1/buddy/turns', nxt, start_body(nxt, '1 apple', ack=turn))
    status, _, _ = api.stream('/v1/buddy/turns', turn, start_body(turn, text, prior=prior))
    return ok and check(status == 409, 'an acknowledged round answers 409 roundAlreadyRan (no send)')


def intents(events):
    return [e['intent'] for e in events if e['type'] == 'proposal']


def scenario_workout(api):
    turn = uuid7()
    status, events, _ = api.stream('/v1/buddy/turns', turn, start_body(turn, 'push day bench 3x8 80, ohp 3x10 40, dips +10 3x8'))
    workout = next((i for i in intents(events) if i['kind'] == 'workout'), None)
    if not check(status == 200 and workout is not None, 'a workout card'):
        return False
    bench = next((x for x in workout['exercises'] if 'bench' in x['mention'].lower()), None)
    for x in workout['exercises']:
        print(f"  card  {x['mention']} → {x['exerciseRef']}: {len(x['sets'])} sets {x['assumptions']}")
    return all([check(len(workout['exercises']) >= 3, 'three exercises'),
                check(bench is not None and len(bench['sets']) == 3 and all(s['reps'] == 8 and s['weight'] == 80 for s in bench['sets']),
                      'bench read by code as 3 × 8 at 80'),
                check(events[-1]['type'] == 'done', 'done')])


def scenario_body(api):
    turn = uuid7()
    text = 'waist 84.5 cm today. and import my old weights: oct 10 2025: 110k, oct 20 2025: 105kg, nov 1 2025: 103.4'
    status, events, _ = api.stream('/v1/buddy/turns', turn, start_body(turn, text))
    kinds = [i['kind'] for i in intents(events)]
    rows = next((i['rows'] for i in intents(events) if i['kind'] == 'importRows'), [])
    for r in rows:
        print(f"  row   {r['date']} {r['value']} {r['unit']}  ← {r['original']}")
    return all([check(status == 200 and 'measurement' in kinds, 'a measurement card'), check('importRows' in kinds and len(rows) == 3, 'an import table with 3 rows'),
                check(events[-1]['type'] == 'done', 'done')])


WEEKLY = {'start': '2026-10-26', 'end': '2026-11-01', 'elapsedDays': 7, 'countedDays': 6, 'targetDays': 6, 'daysWithinTarget': 4,
          'proteinTargetDays': 6, 'proteinDaysHit': 3, 'averageKcal': 1850, 'averageTargetKcal': 2100, 'averageFiberG': 22,
          'trendChangeKg': -0.4, 'workouts': {'sessions': 3, 'planned': 4, 'prs': 2}, 'estimated': False,
          'checkIn': {'currentKcal': 2100, 'proposedKcal': 2000}}


def scenario_weekly(api):
    turn = uuid7()
    status, events, _ = api.stream('/v1/buddy/turns', turn, start_body(turn, 'weekly review', mode='weeklyReview', weekly=WEEKLY))
    text = ''.join(e['text'] for e in events if e['type'] == 'text')
    print('  review  ' + text.replace('\n', '\n          '))
    return all([check(status == 200 and text.startswith('Intake: 1,850 kcal'), 'the code-made header'),
                check(not intents(events) and not any(e['type'] == 'phoneTools' for e in events), 'no cards, no phone tools'),
                check(len([line for line in (text.split('\n\n', 1) + [''])[1].split('\n') if line.strip()]) <= 2, 'at most two observations'),
                check(events[-1]['type'] == 'done', 'done')])


def scenario_label(api, photo):
    if not photo:
        return check(False, '--label-photo is required for the label scenario')
    with open(photo, 'rb') as f:
        image = base64.b64encode(f.read()).decode()
    status, payload = api.post_json('/v1/buddy/label', {'image': image})
    if not check(status == 200, f'200 (got {status})'):
        return False
    read = json.loads(payload)
    n = read['nutrients']
    for key in ('kcal', 'proteinG', 'carbsG', 'fatG', 'fiberG', 'sugarG', 'sodiumMg'):
        print(f"  {key:10} {n[key]['value']!s:>8}  {n[key]['confidence']}")
    print(f"  basis {read['basis']}  serving {read['serving']}  name {read['name']}  kJ→kcal {n['kcalFromKj']}  salt→sodium {n['sodiumFromSalt']}")
    return check(read['found'], 'a nutrition panel was read')


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--live', action='store_true', help='required: these are paid provider sends')
    parser.add_argument('--base-url', default=os.environ.get('FB_API_BASE_URL', 'http://127.0.0.1:5199'))
    parser.add_argument('--app-version', default='1.0.0')
    parser.add_argument('--scenario', action='append', choices=['log', 'phone', 'retry', 'workout', 'body', 'weekly', 'label'])
    parser.add_argument('--label-photo', help='a JPEG of a nutrition panel (label scenario)')
    args = parser.parse_args()
    if not args.live:
        raise SystemExit('refusing to run without --live (paid provider sends)')
    api = Api(args.base_url, args.app_version)
    api.sign_in()
    results = []
    for name in args.scenario or ['log']:
        print(f'scenario {name}')
        runs = {'log': scenario_log, 'phone': scenario_phone, 'retry': scenario_retry, 'workout': scenario_workout, 'body': scenario_body,
                'weekly': scenario_weekly, 'label': lambda a: scenario_label(a, args.label_photo)}
        results.append(runs[name](api))
    sys.exit(0 if all(results) else 1)


if __name__ == '__main__':
    main()
