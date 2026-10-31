#!/usr/bin/env python3
"""Reads the output of `catalog validate` and, for every `sanity fail` of an
A54-added food, either waives it with a stated reason (when the gap is the
fiber energy discount USDA applies, checked with 2 kcal/g for fiber) or
removes the food from the proposal. Usage:
  sanity_fix.py <validate-output.txt> <proposal.yaml>  (rewrites the proposal)
"""
import re
import sys

out, prop = sys.argv[1], sys.argv[2]
fails = {}
for line in open(out, encoding='utf-8'):
    m = re.search(r'sanity fail: (usda:\S+) per 100 g: ([\d.]+) kcal, P ([\d.]+), '
                  r'C ([\d.]+), F ([\d.]+), fiber ([\d.]+)', line)
    if m and line.startswith('error'):
        fails[m.group(1)] = tuple(float(x) for x in m.groups()[1:])
text = open(prop, encoding='utf-8').read()
head, *blocks = re.split(r'(?m)^(?=  - id: )', text)
kept, dropped, waived = [], [], []
for b in blocks:
    mid = re.match(r'  - id: (\S+)', b).group(1)
    if mid not in fails:
        kept.append(b)
        continue
    kcal, p, c, f, fib = fails[mid]
    est = 4 * p + 4 * max(c - fib, 0) + 2 * fib + 9 * f
    if fib >= 5 and abs(est - kcal) <= max(20, 0.15 * kcal):
        reason = ('USDA energy discounts the fiber share (fiber %g g per 100 g); '
                  'the FD-012 check expects 4 kcal/g for all carbs' % fib)
        b = b.rstrip('\n') + '\n    sanity_override: {reason: "%s"}\n' % reason
        kept.append(b)
        waived.append(mid)
    else:
        dropped.append(mid)
open(prop, 'w', encoding='utf-8').write(head + ''.join(kept))
print('waived', len(waived), waived)
print('dropped', len(dropped), dropped)
