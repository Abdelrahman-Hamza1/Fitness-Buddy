#!/usr/bin/env python3
"""A54 catalog expansion generator.

Reads the USDA FoodData Central CSVs (SR Legacy + Foundation, CC0, downloaded
outside the repo by tools/scripts/fetch-usda.sh) and the curated name
dictionaries in names/*.tsv, and proposes entries for data/usda_selection.yaml.

Nutrition numbers are never produced here: the entries only name an FDC food;
`make catalog-usda` imports the numbers. The dictionaries hold names only
(search aliases, EN/AR/Arabizi), never nutrition.

Usage:
  python3 -I tools/scripts/catalog_expand/expand.py --usda-dir DIR \
      --names names/vegetables.tsv [--names ...] --out proposal.yaml [--report r.txt]

Dictionary line (` | ` separated, `#` comments):
  usda head phrase | English | Arabic | Arabizi (comma separated) | flags
Flags (space separated): f = feminine Arabic noun, d = dry ingredient (USDA raw/none -> state dry), a = any state, one food, name used as written, s=raw,boiled = allowed
states (s=* all concrete states), p = product (no state suffix), rawdry = USDA "raw" means a dry
ingredient (state dry), cook = also allow cooked forms.
"""
import argparse
import json
import os
import re
import sys
from collections import defaultdict

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from usda_load import Usda, servings_for, SKIP_CATEGORIES  # noqa: E402
from normalize import norm_key  # noqa: E402

NOISE = {
    'with salt', 'without salt', 'drained', 'solids and liquids',
    'drained solids', 'includes skin', 'with skin', 'without skin',
    'all commercial varieties', 'year round average', 'commercially prepared',
    'salt added in processing', 'salt not added in processing', 'nfs',
    'no salt added', 'solids', 'liquid', 'mature seeds', 'fresh',
    'all varieties', 'regular pack', 'enriched', 'unenriched',
    'with added ascorbic acid', 'without added ascorbic acid',
    'seeds', 'flesh and skin', 'flesh', 'cooked without salt',
    'with salt added', 'salt added', 'edible portion', 'whole',
    'ready-to-eat', 'ready to eat', 'regular', 'unsalted', 'prepared',
    'fully cooked', 'unheated', 'all types', 'composite', 'separable',
    'bottled', 'average', 'dry heat', 'moist heat', 'packed in tomato juice', 'packed in water',
    'water pack', 'regular pack', 'packed in juice', 'sulfured', 'unsulfured',
    'with added vitamin c', 'immature seeds',
    'includes foods for usda\'s food distribution program',
}
# token -> state word
STATE_WORDS = {
    'raw': 'raw', 'uncooked': 'raw',
    'cooked': 'cooked', 'boiled': 'boiled', 'steamed': 'steamed',
    'baked': 'baked', 'roasted': 'roasted', 'grilled': 'grilled',
    'broiled': 'broiled', 'fried': 'fried', 'pan-fried': 'fried',
    'braised': 'braised', 'stewed': 'stewed', 'microwaved': 'microwaved',
    'simmered': 'boiled', 'canned': 'canned', 'frozen': 'frozen',
    'dried': 'dried', 'dehydrated': 'dried', 'dry': 'dry',
    'dry roasted': 'dry_roasted', 'oil roasted': 'oil_roasted',
    'stir-fried': 'fried', 'sauteed': 'fried', 'unprepared': 'unprepared',
    'toasted': 'toasted', 'smoked': 'smoked',
}
STATE_EN = {
    'raw': 'raw', 'boiled': 'boiled', 'steamed': 'steamed', 'baked': 'baked',
    'roasted': 'roasted', 'grilled': 'grilled', 'broiled': 'broiled',
    'fried': 'fried', 'braised': 'braised', 'stewed': 'stewed',
    'microwaved': 'microwaved', 'cooked': 'cooked', 'canned': 'canned',
    'frozen': 'frozen', 'frozen_cooked': 'frozen, cooked', 'dried': 'dried',
    'dry': 'dry', 'dry_roasted': 'dry roasted', 'oil_roasted': 'oil roasted',
    'toasted': 'toasted', 'smoked': 'smoked', 'none': '',
}
# (masculine, feminine, arabizi)
STATE_AR = {
    'raw': ('نيء', 'نيئة', 'nay'),
    'boiled': ('مسلوق', 'مسلوقة', 'maslouq'),
    'steamed': ('على البخار', 'على البخار', 'ala el bukhar'),
    'baked': ('مخبوز', 'مخبوزة', 'makhbouz'),
    'roasted': ('مشوي بالفرن', 'مشوية بالفرن', 'mashwi bil forn'),
    'grilled': ('مشوي على الشواية', 'مشوية على الشواية', 'mashwi ala el shawaya'),
    'broiled': ('مشوي', 'مشوية', 'mashwi'),
    'fried': ('مقلي', 'مقلية', 'maqli'),
    'braised': ('مطبوخ ببطء', 'مطبوخة ببطء', 'matbookh bi butu2'),
    'stewed': ('مطهو', 'مطهوة', 'matbookh bil qidr'),
    'microwaved': ('مطبوخ بالميكروويف', 'مطبوخة بالميكروويف', 'microwave'),
    'cooked': ('مطبوخ', 'مطبوخة', 'matbookh'),
    'canned': ('معلب', 'معلبة', 'mu3alab'),
    'frozen': ('مجمد', 'مجمدة', 'mjammad'),
    'frozen_cooked': ('مجمد مطبوخ', 'مجمدة مطبوخة', 'mjammad matbookh'),
    'dried': ('مجفف', 'مجففة', 'mujaffaf'),
    'dry': ('جاف', 'جافة', 'jaf'),
    'dry_roasted': ('محمص', 'محمصة', 'mu7ammas'),
    'oil_roasted': ('محمص بالزيت', 'محمصة بالزيت', 'mu7ammas bil zeit'),
    'toasted': ('محمص', 'محمصة', 'mu7ammas'),
    'smoked': ('مدخن', 'مدخنة', 'mudakhkhan'),
    'none': ('', '', ''),
}
STATE_PRIORITY = {'none': 10, 'raw': 8, 'dried': 6, 'dry': 6, 'dry_roasted': 5,
                  'roasted': 4, 'oil_roasted': 3, 'canned': 2}
ALL_STATES = ['raw', 'boiled', 'steamed', 'baked', 'roasted', 'grilled', 'broiled', 'fried',
              'braised', 'stewed', 'microwaved', 'cooked', 'canned', 'frozen',
              'frozen_cooked', 'dried', 'dry']
DEFAULT_STATES = ['raw', 'boiled', 'canned', 'frozen_cooked', 'dried']
COOKED = {'boiled', 'steamed', 'baked', 'roasted', 'grilled', 'broiled',
          'fried', 'braised', 'stewed', 'microwaved', 'cooked'}


def split_tokens(desc):
    d = re.sub(r'\([^)]*\)', '', desc)
    return [t.strip().lower() for t in d.split(',') if t.strip()]


def parse(desc):
    """-> (head_phrase, state_key, score_bonus) or None."""
    toks = split_tokens(desc)
    head, states, bonus = [], [], 0
    for t in toks:
        if t in ('without salt', 'salt not added in processing',
                 'no salt added', 'cooked without salt'):
            bonus += 3
        if t in ('with salt', 'salt added in processing', 'with salt added'):
            bonus -= 3
        if t in ('drained solids', 'drained'):
            bonus += 1
        if t in NOISE:
            continue
        if t in STATE_WORDS:
            states.append(STATE_WORDS[t])
            continue
        head.append(t)
    s = set(states)
    if not s:
        st = 'none'
    elif 'raw' in s:
        st = 'raw'
    elif 'frozen' in s:
        st = 'frozen_cooked' if s & COOKED else 'frozen'
    elif 'canned' in s:
        st = 'canned' if not (s & COOKED) else 'x_canned_cooked'
    elif 'dried' in s:
        st = 'dried' if not (s & COOKED) else 'x_' + '_'.join(sorted(s))
    elif 'dry_roasted' in s:
        st = 'dry_roasted'
    elif 'oil_roasted' in s:
        st = 'oil_roasted'
    elif 'unprepared' in s:
        st = 'unprepared'
    else:
        meths = [m for m in ('boiled', 'steamed', 'baked', 'roasted',
                             'grilled', 'broiled', 'fried', 'braised',
                             'stewed', 'microwaved') if m in s]
        if len(meths) == 1:
            st = meths[0]
        elif not meths:
            st = sorted(s)[0]
        else:
            st = 'x_' + '_'.join(meths)
    return ', '.join(head), st, bonus


def rx_score(d, dataset):
    sc = 5 if dataset == 'foundation' else 0
    for pat, w in (('all grades', 3), ('choice', 2), ('select', 1),
                   ('trimmed to 1/8" fat', 2), ('trimmed to 1/4" fat', 1),
                   ('without salt', 2), ('with salt', -2),
                   ('australian', -6), ('imported', -6), ('new zealand', -6),
                   ('grass-fed', -4), ('prime', -3), ('restaurant', -4),
                   ('enhanced', -3), ('pre-basted', -3), ('rotisserie', -1),
                   ('sodium added', -3), ('low sodium', -2)):
        if pat in d:
            sc += w
    return sc - len(d) / 100.0


def load_names(paths):
    d = {}
    for p in paths:
        for n, line in enumerate(open(p, encoding='utf-8'), 1):
            line = line.rstrip('\n')
            if not line.strip() or line.lstrip().startswith('#'):
                continue
            parts = [x.strip() for x in re.split(r'\s\|\s', line)]
            if len(parts) < 3:
                sys.exit(f'{p}:{n}: need at least key | EN | AR')
            parts += [''] * (5 - len(parts))
            key, en, ar, zi, flags = parts[:5]
            fl = flags.split()
            e = {'en': en, 'ar': ar,
                 'zi': [z.strip() for z in zi.split(',') if z.strip()],
                 'f': 'f' in fl, 'p': 'p' in fl, 'rawdry': 'rawdry' in fl or 'd' in fl,
                 'dry': 'd' in fl, 'any': 'a' in fl,
                 'states': None, 'src': f'{os.path.basename(p)}:{n}',
                 'enum': None, 'rx': None}
            for f in fl:
                if f.startswith('s='):
                    e['states'] = f[2:].split(',')
                if f.startswith('st='):
                    e['enum'] = f[3:]
            if key.startswith('re:'):
                e['rx'] = re.compile(key[3:])
                if not e['enum']:
                    sys.exit(f'{p}:{n}: re: lines need st=<state>')
            if key in d:
                sys.exit(f'{p}:{n}: duplicate key {key}')
            d[key] = e
    return d


def slugify(s):
    s = s.lower().replace('&', ' and ')
    s = re.sub(r'[^a-z0-9]+', '_', s).strip('_')
    return s


def load_existing(repo):
    import yaml
    sel = yaml.safe_load(open(os.path.join(repo, 'data/usda_selection.yaml')))
    foods = sel['foods']
    ids = {f['id'] for f in foods}
    fdc = {f['fdc_id'] for f in foods}
    names = set()
    for f in foods:
        for lang, lst in f['names'].items():
            for n in lst:
                names.add((lang, norm_key(n)))
    dd = os.path.join(repo, 'data/reference_dishes')
    for fn in os.listdir(dd):
        if not fn.endswith('.yaml'):
            continue
        d = yaml.safe_load(open(os.path.join(dd, fn)))
        def walk(nm):
            for lang, lst in (nm or {}).items():
                for n in lst:
                    names.add((lang, norm_key(n)))
        walk(d.get('names'))
        for v in d.get('variants', []) or []:
            walk(v.get('names'))
    ex = yaml.safe_load(open(os.path.join(repo, 'data/exercises.yaml')))
    return ids, fdc, names, ex


def yaml_str(s):
    return json.dumps(s, ensure_ascii=False)


def emit(e):
    lines = [f"  - id: {e['id']}", f"    fdc_id: {e['fdc_id']}",
             f"    state: {e['state']}"]
    if e.get('yield_group'):
        lines.append(f"    yield_group: {e['yield_group']}")
    if e.get('fiber_zero'):
        lines.append('    fiber_zero: true')
    lines.append('    names:')
    for lang in ('en', 'ar', 'arabizi'):
        if e['names'].get(lang):
            lines.append(f"      {lang}: [" + ', '.join(
                yaml_str(x) for x in e['names'][lang]) + ']')
    if e.get('servings'):
        lines.append('    servings: [' + ', '.join(
            f'{{unit: {u}, g: {g:g}}}' for u, g in e['servings']) + ']')
    if e.get('notes'):
        lines.append(f"    notes: {yaml_str(e['notes'])}")
    return '\n'.join(lines)


def state_enum(st, entry, desc_has_drained):
    if st == 'raw':
        return 'dry' if entry['rawdry'] else 'raw'
    if st in COOKED or st == 'frozen_cooked':
        return 'cooked'
    if st == 'fried':
        return 'fried'
    if st == 'dry':
        return 'dry' if entry['dry'] else 'as_sold'
    if st == 'none' and entry['dry']:
        return 'dry'
    if st == 'canned':
        return 'drained' if desc_has_drained else 'as_sold'
    return 'as_sold'


def compose(entry, st):
    gender = 1 if entry['f'] else 0
    en = entry['en']
    stxt = STATE_EN.get(st, st)
    if entry['p'] or st == 'none':
        en_full = en
        ar_full = entry['ar']
        zi = list(entry['zi'])
    else:
        en_full = f'{en}, {stxt}'
        sar = STATE_AR[st][gender]
        ar_full = f"{entry['ar']} {sar}".strip()
        zi = [f'{z} {STATE_AR[st][2]}' for z in entry['zi']]
    return en_full, ar_full, zi


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--usda-dir', required=True)
    ap.add_argument('--names', action='append', required=True)
    ap.add_argument('--out', required=True)
    ap.add_argument('--report')
    ap.add_argument('--repo', default=os.getcwd())
    ap.add_argument('--taken', action='append', default=[],
                    help='extra proposal files whose ids/names/fdc count as taken')
    a = ap.parse_args()

    u = Usda(a.usda_dir)
    names = load_names(a.names)
    ids, fdcs, taken_names, _ = load_existing(a.repo)
    import yaml
    for t in a.taken:
        for f in yaml.safe_load(open(t))['foods']:
            ids.add(f['id'])
            fdcs.add(f['fdc_id'])
            for lang, lst in f['names'].items():
                for n in lst:
                    taken_names.add((lang, norm_key(n)))

    # concepts already covered by the existing selection (same head + state)
    covered = set()
    for fid in fdcs:
        if fid in u.foods:
            h, st, _ = parse(u.foods[fid]['desc'])
            covered.add((h, st))

    best = {}  # (key, state) -> (score, fdc)
    real_state = {}
    unmatched = defaultdict(int)
    for fid, f in u.foods.items():
        if f['cat'] in SKIP_CATEGORIES or fid in fdcs:
            continue
        h, st, bonus = parse(f['desc'])
        if h not in names:
            unmatched[h] += 1
            continue
        entry = names[h]
        allowed = entry['states'] or DEFAULT_STATES
        if entry['states'] == ['*']:
            allowed = ALL_STATES
        if entry['p']:
            allowed = ['none'] + (entry['states'] or [])
        if entry['any']:
            allowed = None
        if allowed is not None and st not in allowed:
            continue
        if st.startswith('x_') or st in ('unprepared',):
            continue
        if (h, st) in covered:
            continue
        if not u.core_ok(fid):
            continue
        score = bonus + (5 if f['dataset'] == 'foundation' else 0)
        score -= len(f['desc']) / 100.0
        k = (h, st)
        if entry['any']:
            score += STATE_PRIORITY.get(st, 0)
            k = (h, 'any')
            if any((h, s2) in covered for s2 in STATE_PRIORITY):
                continue
        if k not in best or score > best[k][0]:
            best[k] = (score, fid)
            real_state[k] = st

    # regex concepts: one best candidate per line, name used as written
    rx_hits = {}
    rxs = [(k, e) for k, e in names.items() if e['rx']]
    for k, e in rxs:
        cands = []
        for fid, f in u.foods.items():
            if f['cat'] in SKIP_CATEGORIES or fid in fdcs:
                continue
            d = re.sub(r'\s+', ' ', re.sub(r'\([^)]*\)', '', f['desc'].lower())).replace(' ,', ',')
            if not e['rx'].search(d) or not u.core_ok(fid):
                continue
            cands.append((rx_score(d, f['dataset']), fid))
        if cands:
            cands.sort(key=lambda x: (-x[0], x[1]))
            rx_hits[k] = cands[0][1]
        else:
            unmatched['MISS ' + k] += 1
    best_rx = sorted(rx_hits.items())

    out, rep = [], []
    used_ids, used_names = set(ids), set(taken_names)
    work = []
    for (h, st), (score, fid) in sorted(best.items()):
        entry = names[h]
        if st == 'any':
            st = real_state[(h, 'any')]
            en, ar, zi = entry['en'], entry['ar'], list(entry['zi'])
        else:
            en, ar, zi = compose(entry, st)
        work.append((entry, fid, st, en, ar, zi, h))
    for k, fid in best_rx:
        entry = names[k]
        work.append((entry, fid, entry['enum'], entry['en'], entry['ar'],
                     list(entry['zi']), k))
    done_fdc = set()
    got = {w[6] for w in work}
    for k, e in names.items():
        if not e['rx'] and k not in got:
            unmatched['NOFOOD ' + k] += 1
    for entry, fid, st, en, ar, zi, h in work:
        f = u.foods[fid]
        if fid in done_fdc:
            rep.append(f'SKIP same fdc {fid} twice ({en})')
            continue
        slug = slugify(en)[:60]
        eid = f'usda:{slug}'
        if eid in used_ids:
            rep.append(f'SKIP id clash {eid} ({h}/{st})')
            continue
        # fiber
        fz = False
        if not u.has_fiber(fid):
            cat = f['cat']
            carbs = u.nutrients[fid].get(1005, u.nutrients[fid].get(1050, 0))
            dl = f['desc'].lower()
            if cat in ('Beef Products', 'Poultry Products', 'Pork Products',
                       'Lamb, Veal, and Game Products', 'Finfish and Shellfish Products',
                       'Dairy and Egg Products', 'Fats and Oils', 'Beverages',
                       'Sausages and Luncheon Meats') or carbs < 1 \
                    or 'juice' in dl or 'nectar' in dl or cat == 'Sweets':
                fz = True
            else:
                rep.append(f'SKIP no fiber {en} fdc {fid}')
                continue
        enames = {'en': [], 'ar': [], 'arabizi': []}
        for lang, cand in (('en', [en]), ('ar', [ar] if ar else []),
                           ('arabizi', zi)):
            for c in cand:
                k = (lang, norm_key(c))
                if k in used_names or not k[1]:
                    if lang == 'en' or lang == 'ar':
                        rep.append(f'NAME clash {lang} {c} ({eid})')
                    continue
                used_names.add(k)
                if c not in enames[lang]:
                    enames[lang].append(c)
        if not enames['en'] or not enames['ar']:
            rep.append(f'SKIP name clash {eid}')
            continue
        used_ids.add(eid)
        done_fdc.add(fid)
        sd = entry['enum'] if entry['rx'] else state_enum(
            st, entry, 'drained' in f['desc'].lower())
        e = {'id': eid, 'fdc_id': fid, 'state': sd, 'names': enames,
             'servings': servings_for(u.portions.get(fid, []), f['cat']),
             'fiber_zero': fz}
        out.append(e)
        rep.append(f'{eid} <- {fid} {f["desc"]}')
    with open(a.out, 'w', encoding='utf-8') as fh:
        fh.write('foods:\n' + '\n'.join(emit(e) for e in out) + '\n')
    if a.report:
        with open(a.report, 'w', encoding='utf-8') as fh:
            fh.write('\n'.join(rep) + '\n\n# unmatched head phrases\n')
            for k, v in sorted(unmatched.items(), key=lambda x: -x[1]):
                fh.write(f'{v}\t{k}\n')
    print(f'proposed {len(out)} foods; '
          f'{sum(1 for r in rep if r.startswith(("SKIP", "NAME")))} skipped/clashed')


if __name__ == '__main__':
    main()
