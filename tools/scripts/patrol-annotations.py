#!/usr/bin/env python3
"""Print Patrol instrumentation failures as GitHub check-run annotations.

Job logs need a token, check-run annotations don't: the orchestrator reads
failures through ci-status/annotations (no gh, A07 backlog #87). Test data
only, never user content.
"""
import glob
import xml.etree.ElementTree as ET

files = glob.glob('apps/mobile/build/app/outputs/androidTest-results/**/*.xml', recursive=True)
found = 0
for f in files:
    for case in ET.parse(f).getroot().iter('testcase'):
        for bad in list(case.iter('failure')) + list(case.iter('error')):
            text = (bad.get('message') or '') + '\n' + (bad.text or '')
            text = '\n'.join(l[:300] for l in text.strip().splitlines()[:60])
            text = text.replace('%', '%25').replace('\r', '').replace('\n', '%0A')
            print(f"::error title=Patrol failure: {case.get('name', '?')[:120]}::{text}")
            found += 1
print(f"{len(files)} result files, {found} failures")
