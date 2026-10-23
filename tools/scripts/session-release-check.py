#!/usr/bin/env python3
"""A20: inspect the actual release APK, merged manifest and referenced rules."""
import argparse
import re
import sys
import zipfile

from apk_hardening_check import ApkDumps, DumpError, parse_xmltree, resource_files


def require(condition, message):
    if not condition:
        raise DumpError(message)


def check(aapt2, apk):
    dumps = ApkDumps(aapt2, apk)
    manifest = parse_xmltree(dumps.xmltree('AndroidManifest.xml'), 'manifest')
    apps = [c for r in manifest for c in r.children if c.name == 'application']
    require(len(apps) == 1, 'missing merged application')
    resources = dumps.resources()

    def rules(attr, root):
        ref = apps[0].attrs.get('android:' + attr, '')
        require(re.fullmatch(r'@0x7f[0-9a-f]{6}', ref), f'{attr}: missing resource reference')
        name, files = resource_files(resources, ref[1:])
        require(name and name.startswith('xml/') and files, f'{attr}: missing XML')
        trees = []
        for _, path, is_file in files:
            require(is_file, f'{attr}: non-file variant')
            tree = parse_xmltree(dumps.xmltree(path), path)
            require(len(tree) == 1 and tree[0].name == root, f'{attr}: unexpected root')
            trees.append(tree[0])
        return trees

    def excluded(node):
        return any(c.name == 'exclude' and
                   c.attrs.get('domain') == '"sharedpref" (Raw: "sharedpref")' and
                   c.attrs.get('path') == '"." (Raw: ".")' for c in node.children)

    for tree in rules('fullBackupContent', 'full-backup-content'):
        require(excluded(tree), 'legacy backup does not exclude all shared preferences')
    for tree in rules('dataExtractionRules', 'data-extraction-rules'):
        for name in ('cloud-backup', 'device-transfer', 'cross-platform-transfer'):
            nodes = [c for c in tree.children if c.name == name]
            require(nodes and all(excluded(n) for n in nodes), f'{name}: preferences not excluded')
    with zipfile.ZipFile(apk) as archive:
        require(any(n.endswith(".dex") for n in archive.namelist()), "release has no DEX")
        require(any(n.endswith("/libapp.so") for n in archive.namelist()), "release has no Dart AOT library")
        for name in archive.namelist():
            if name.endswith(('.dex', '.so', '.dill', '.bin')):
                data = archive.read(name)
                for marker in (b'fitness_buddy/session_test', b'a20-status',
                               b'debug_probe_only', b'session_durability_probe.dart'):
                    require(marker not in data, f'debug hook or probe packaged in {name}')
    print('A20 release: debug hook and probe absent, merged backup and extraction exclusions present')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--aapt2', required=True)
    parser.add_argument('apk')
    args = parser.parse_args()
    try:
        check(args.aapt2, args.apk)
    except (DumpError, OSError, zipfile.BadZipFile) as error:
        print(f'::error title=A20 release safety::{error}', file=sys.stderr)
        sys.exit(1)
