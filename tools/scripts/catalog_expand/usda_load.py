"""Loads USDA FoodData Central CSVs (SR Legacy + Foundation) for the A54 catalog
expansion generator. Read-only; the bulk files live outside the repo
(tools/scripts/fetch-usda.sh)."""
import csv
import os
import re
from collections import defaultdict

SKIP_CATEGORIES = {
    'Baby Foods', 'Fast Foods', 'Restaurant Foods',
    'American Indian/Alaska Native Foods',
}


def _rows(path):
    with open(path, newline='', encoding='utf-8') as f:
        yield from csv.DictReader(f)


class Usda:
    def __init__(self, root):
        self.foods = {}  # fdc_id -> dict(desc, cat, dataset)
        self.portions = defaultdict(list)  # fdc_id -> [(amount, label, grams)]
        self.nutrients = defaultdict(dict)  # fdc_id -> {nutrient_id: amount}
        self.bad = set()  # foods with a nutrient id missing from nutrient.csv (the importer fails on them)
        for ds, types in (('sr_legacy', {'sr_legacy_food'}),
                          ('foundation', {'foundation_food'})):
            d = os.path.join(root, ds)
            cats = {r['id']: r['description']
                    for r in _rows(os.path.join(d, 'food_category.csv'))}
            for r in _rows(os.path.join(d, 'food.csv')):
                if r['data_type'] not in types:
                    continue
                self.foods[int(r['fdc_id'])] = {
                    'desc': r['description'],
                    'cat': cats.get(r['food_category_id'], ''),
                    'dataset': ds,
                }
            units = {r['id']: r['name']
                     for r in _rows(os.path.join(d, 'measure_unit.csv'))}
            ids = {i for i, f in self.foods.items() if f['dataset'] == ds}
            for r in _rows(os.path.join(d, 'food_portion.csv')):
                if not r['fdc_id']:
                    continue
                i = int(r['fdc_id'])
                if i not in ids:
                    continue
                try:
                    g = float(r['gram_weight'])
                    a = float(r['amount'] or 1)
                except ValueError:
                    continue
                if g <= 0 or a <= 0:
                    continue
                u = units.get(r['measure_unit_id'], '')
                if u == 'undetermined':
                    u = ''
                label = ' '.join(x for x in (u, r['portion_description'],
                                             r['modifier']) if x).strip()
                self.portions[i].append((a, label, g))
            known = {int(r['id']) for r in _rows(os.path.join(d, 'nutrient.csv'))}
            want = {1008, 2047, 2048, 1003, 1004, 1005, 1050, 1079}
            for r in _rows(os.path.join(d, 'food_nutrient.csv')):
                if not r['fdc_id']:
                    continue
                i = int(r['fdc_id'])
                if i not in ids:
                    continue
                n = int(r['nutrient_id'])
                if n not in known:
                    self.bad.add(i)
                if n in want and r['amount']:
                    self.nutrients[i][n] = float(r['amount'])

    def core_ok(self, i):
        if i in self.bad:
            return False
        n = self.nutrients.get(i, {})
        if any(v < 0 for v in n.values()):
            return False  # e.g. carbs by difference below zero: the catalog rejects it
        return (any(k in n for k in (1008, 2047, 2048)) and 1003 in n
                and 1004 in n and (1005 in n or 1050 in n))

    def has_fiber(self, i):
        return 1079 in self.nutrients.get(i, {})

    def kcal(self, i):
        n = self.nutrients[i]
        return n.get(1008, n.get(2048, n.get(2047)))


PIECE_WORDS = (
    'medium', 'large', 'small', 'fruit', 'piece', 'pieces', 'each', 'roll', 'cookie',
    'cookies', 'cracker', 'crackers', 'patty', 'patties', 'link', 'bar', 'biscuit',
    'muffin', 'bun', 'bagel', 'egg', 'pancake', 'waffle', 'doughnut', 'donut',
    'tortilla', 'taco', 'pretzel', 'shell', 'stick', 'strip', 'sandwich', 'wafers',
    'nugget', 'fillet', 'filet', 'steak', 'chop', 'breast', 'thigh', 'drumstick',
    'wing', 'leg', 'cake', 'pie', 'candy', 'olive', 'clove', 'stalk', 'spear',
    'leaf', 'head', 'ear', 'ball', 'sheet', 'cone', 'sausage', 'frankfurter',
    'slice', 'slices', 'pat', 'shrimp', 'cup cake', 'cupcake', 'eclair', 'croissant',
)
_VOLUME = re.compile(r'^(cups?|tbsp|tablespoons?|tsp|teaspoons?)\b')


def servings_for(portions, category=''):
    """Up to 3 serving units from the FDC portion list. Units: piece, slice,
    can, cup, tbsp, tsp (all known to the app). A `piece` is only taken from a
    label that names a countable thing; weights above 700 g are never a piece."""
    vol = {}
    count = None
    slc = None
    can = None
    for a, label, g in portions:
        l = label.lower().strip()
        per = g / a
        if re.match(r'^(cup|cups)\b', l):
            vol.setdefault('cup', per)
        elif re.match(r'^(tbsp|tablespoon|tablespoons)\b', l):
            vol.setdefault('tbsp', per)
        elif re.match(r'^(tsp|teaspoon)\b', l):
            vol.setdefault('tsp', per)
        elif re.match(r'^slices?\b', l):
            if slc is None:
                slc = per
        elif re.match(r'^can\b', l):
            if can is None:
                can = per
        else:
            first = re.match(r'^([a-z]+)', l)
            if first and first.group(1) in PIECE_WORDS and per <= 700 \
                    and not l.startswith('extra'):
                if count is None or l.startswith('medium'):
                    count = per
    out = []
    if count:
        out.append(('piece', count))
    elif slc:
        out.append(('slice', slc))
    if can and not out:
        out.append(('can', can))
    if 'cup' in vol:
        out.append(('cup', vol['cup']))
    if 'tbsp' in vol and (category in TBSP_CATS or 'cup' not in vol):
        out.append(('tbsp', vol['tbsp']))
    if 'tsp' in vol and category in TSP_CATS:
        out.append(('tsp', vol['tsp']))
    return out[:3]


TBSP_CATS = {'Fats and Oils', 'Spices and Herbs', 'Soups, Sauces, and Gravies',
             'Sweets', 'Legumes and Legume Products', 'Dairy and Egg Products'}
TSP_CATS = {'Spices and Herbs'}
