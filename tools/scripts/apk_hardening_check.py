"""Release hardening check on a built Android APK (S06 plan A8).

Reads what aapt2 says is packaged (the merged manifest and the network
security config after resource shrinking) and fails closed: a value it can't
parse as an explicit boolean, an element or attribute it doesn't know, or a
resource with several variants is a failure, never a pass.

Rules, for a release build of FLAVOR:
  - <application>: android:debuggable and android:usesCleartextTraffic absent
    or explicitly false; `aapt2 dump badging` has no application-debuggable.
  - android:networkSecurityConfig: one xml resource with a single file.
  - network security config: one <base-config cleartextTrafficPermitted=false>;
    trust anchors only <certificates src="system">; no other elements.
    staging/prod: no <domain-config>. dev: <domain-config> only for 127.0.0.1
    and localhost (the local API over adb reverse, plan D6), no subdomains.
  - A11 PA5: packaged backup XML allows only local user.db/-wal/-shm for
    Android 12+ encrypted cloud/device transfer; legacy/cross-platform exclude all.

Usage (python3 -I, stdlib only):
  apk_hardening_check.py --flavor F --aapt2 AAPT2 APK       check an APK
  apk_hardening_check.py --flavor F --dumps DIR             check captured dumps
  apk_hardening_check.py --capture DIR --aapt2 AAPT2 APK    write the dumps
DIR holds badging.txt, resources.txt and xmltree/<path in the APK>.txt (the
self-test fixtures, tools/scripts/testdata/apk-hardening/).
Exit: 0 = hardened, 1 = a rule failed, 2 = usage or dump error.
"""

import argparse
import os
import re
import subprocess
import sys

NAME = "apk-hardening"
ANDROID_NS = "http://schemas.android.com/apk/res/android:"
FLAVORS = ("dev", "staging", "prod")
DEV_CLEARTEXT_DOMAINS = {"127.0.0.1", "localhost"}
MANIFEST = "AndroidManifest.xml"


class DumpError(Exception):
    pass


# --- Dump sources ---------------------------------------------------------------


class ApkDumps:
    def __init__(self, aapt2, apk):
        self.aapt2, self.apk = aapt2, apk

    def _run(self, *args):
        result = subprocess.run([self.aapt2, "dump", *args, self.apk],
                                capture_output=True, text=True, check=False)
        if result.returncode != 0:
            raise DumpError(f"aapt2 dump {' '.join(args)} failed: {result.stderr.strip()}")
        return result.stdout

    def badging(self):
        return self._run("badging")

    def resources(self):
        return self._run("resources")

    def xmltree(self, path):
        return self._run("xmltree", "--file", path)


class DirDumps:
    def __init__(self, root):
        self.root = root

    def _read(self, rel):
        try:
            with open(os.path.join(self.root, rel), encoding="utf-8") as f:
                return f.read()
        except OSError as e:
            raise DumpError(f"no captured dump {rel} in {self.root}") from e

    def badging(self):
        return self._read("badging.txt")

    def resources(self):
        return self._read("resources.txt")

    def xmltree(self, path):
        return self._read(os.path.join("xmltree", safe_path(path) + ".txt"))


def safe_path(path):
    parts = path.split("/")
    if path.startswith("/") or any(p in ("", ".", "..") for p in parts):
        raise DumpError(f"unexpected file path in the APK: {path!r}")
    return path


# --- aapt2 text parsing ---------------------------------------------------------


class Element:
    def __init__(self, name, indent):
        self.name, self.indent = name, indent
        self.attrs = {}  # name -> raw value; android: attributes as "android:name"
        self.children = []
        self.texts = []


ATTR_RE = re.compile(r"(?P<name>[\w.-]+)(?:\(0x[0-9a-f]+\))?=(?P<value>.*)$")


def parse_xmltree(text, what):
    """`aapt2 dump xmltree` output -> list of root elements."""
    roots, stack = [], []
    for raw in text.splitlines():
        if not raw.strip():
            continue
        indent = len(raw) - len(raw.lstrip(" "))
        line = raw.strip()
        kind, _, rest = line.partition(": ")
        if kind == "N":
            continue
        while stack and stack[-1].indent >= indent:
            stack.pop()
        if kind == "E":
            el = Element(rest.split(" ", 1)[0], indent)
            (stack[-1].children if stack else roots).append(el)
            stack.append(el)
        elif kind in ("A", "T"):
            if not stack:
                raise DumpError(f"{what}: {kind} line outside an element: {line}")
            if kind == "T":
                m = re.fullmatch(r"'(.*)'", rest)
                if not m:
                    raise DumpError(f"{what}: unreadable text node: {line}")
                stack[-1].texts.append(m.group(1))
                continue
            prefix = ""
            if rest.startswith(ANDROID_NS):
                prefix, rest = "android:", rest[len(ANDROID_NS):]
            elif rest.startswith("http"):
                prefix, rest = "other-ns:", rest.split(":", 2)[-1]
            m = ATTR_RE.match(rest)
            if not m:
                raise DumpError(f"{what}: unreadable attribute: {line}")
            key = prefix + m.group("name")
            if key in stack[-1].attrs:
                raise DumpError(f"{what}: duplicate attribute")
            stack[-1].attrs[key] = m.group("value")
        else:
            raise DumpError(f"{what}: unknown line: {line}")
    return roots


def boolean(raw):
    """True/False for an explicit boolean as aapt2 prints it, None otherwise
    (string, resource reference, anything unknown)."""
    if raw in ("true", "(type 0x12)0xffffffff"):
        return True
    if raw in ("false", "(type 0x12)0x0"):
        return False
    return None


def resource_files(resources, res_id):
    """(type/name, [(config, value, is_file)]) of resource res_id in `aapt2
    dump resources`: every entry, so an alias variant (`(v24) @0x7f…`) counts too."""
    lines = resources.splitlines()
    for i, line in enumerate(lines):
        m = re.match(rf"\s*resource {re.escape(res_id)} (\S+)", line)
        if not m:
            continue
        files = []
        for follow in lines[i + 1:]:
            if re.match(r"\s*(resource|type) ", follow):
                break
            f = re.match(r"\s*\((.*?)\) (\(file\) )?(\S+)", follow)
            if f:
                files.append((f.group(1), f.group(3), f.group(2) is not None))
        return m.group(1), files
    return None, []


# --- Rules ------------------------------------------------------------------------


UNWANTED_PERMISSIONS = {"android.permission.USE_BIOMETRIC", "android.permission.USE_FINGERPRINT"}


def check(dumps, flavor):
    """Returns (problems, facts): the rules broken and what was seen."""
    problems, facts = [], []

    if re.search(r"(?m)^application-debuggable\b", dumps.badging()):
        problems.append("aapt2 badging reports application-debuggable")

    manifest = parse_xmltree(dumps.xmltree(MANIFEST), MANIFEST)
    apps = [c for r in manifest if r.name == "manifest" for c in r.children if c.name == "application"]
    if len(manifest) != 1 or manifest[0].name != "manifest" or len(apps) != 1:
        return problems + ["the manifest does not have exactly one <manifest><application>"], facts
    app = apps[0].attrs

    # A50: androidx.credentials pulls androidx.biometric, whose manifest asks
    # for these; Google sign-in doesn't need them (removed in the app manifest).
    granted = {re.match(r'"?([^"\s]*)', c.attrs.get("android:name", "")).group(1)
               for c in manifest[0].children if c.name == "uses-permission"}
    for permission in sorted(granted & UNWANTED_PERMISSIONS):
        problems.append(f"uses-permission {permission} must be removed (tools:node=\"remove\")")

    for attr in ("android:debuggable", "android:usesCleartextTraffic"):
        raw = app.get(attr)
        facts.append(f"{attr}={raw if raw is not None else '(unset)'}")
        if raw is not None and boolean(raw) is not False:
            problems.append(f"{attr} is {raw} (must be absent or explicitly false)")

    config = app.get("android:networkSecurityConfig")
    facts.append(f"android:networkSecurityConfig={config}")
    m = re.fullmatch(r"@(0x7f[0-9a-f]{6})", config or "")
    if not m:
        return problems + [f"android:networkSecurityConfig is {config} (expected @xml/network_security_config)"], facts
    res_name, files = resource_files(dumps.resources(), m.group(1))
    if res_name is None or not res_name.startswith("xml/"):
        return problems + [f"resource {m.group(1)} is not an xml resource ({res_name})"], facts
    if len(files) != 1 or files[0][0] != "" or not files[0][2]:
        found = ", ".join(f"{path} ({cfg or 'default'})" for cfg, path, _ in files) or "none"
        return problems + [f"{res_name} must have exactly one file and no variants (found: {found})"], facts
    path = files[0][1]
    facts.append(f"{res_name} -> {path}")
    problems += check_network_config(parse_xmltree(dumps.xmltree(path), path), flavor, facts)
    problems += check_backup_rules(dumps, app)
    return problems, facts


# A11 PA5: compare the packaged rules, including shrinking/variants, fail closed.
BACKUP_DOMAINS = ('root', 'file', 'database', 'sharedpref', 'external',
                  'device_root', 'device_file', 'device_database', 'device_sharedpref')


def check_backup_rules(dumps, app):
    def leaf(name, **attrs):
        return (name, tuple(sorted(attrs.items())), ())

    excluded = tuple(sorted(leaf('exclude', domain=d, path='.') for d in BACKUP_DOMAINS))
    # Includes already exclude every other path; redundant excludes fail Android lint.
    allowed = tuple(sorted(
        leaf('include', domain='file', path='profiles/local/user.db' + suffix)
        for suffix in ('', '-wal', '-shm')))
    expected = {
        'fullBackupContent': ('full-backup-content', (), excluded),
        'dataExtractionRules': ('data-extraction-rules', (), tuple(sorted([
            ('cloud-backup', (('disableIfNoEncryptionCapabilities', True),), allowed),
            ('device-transfer', (), allowed),
            ('cross-platform-transfer', (('platform', 'ios'),), excluded),
        ]))),
    }

    def canonical(el):
        if el.texts:
            raise DumpError('backup rules contain unexpected text')
        attrs = []
        for key, raw in el.attrs.items():
            value = boolean(raw)
            if value is None:
                match = re.fullmatch(r'"([^"\\]*)"(?: \(Raw: "\1"\))?', raw)
                if not match:
                    raise DumpError('backup rules contain unreadable attributes')
                value = match.group(1)
            attrs.append((key, value))
        return (el.name, tuple(sorted(attrs)), tuple(sorted(canonical(c) for c in el.children)))

    problems = []
    if boolean(app.get('android:allowBackup')) is not True:
        problems.append('android:allowBackup must be explicitly true for the pinned backup policy')
    for attr, policy in expected.items():
        match = re.fullmatch(r'@(0x7f[0-9a-f]{6})', app.get('android:' + attr, ''))
        if not match:
            problems.append(attr + ': expected one explicit XML resource')
            continue
        name, files = resource_files(dumps.resources(), match.group(1))
        if not name or not name.startswith('xml/') or len(files) != 1 or files[0][0] or not files[0][2]:
            problems.append(attr + ': expected one XML file without variants')
            continue
        roots = parse_xmltree(dumps.xmltree(files[0][1]), attr)
        if len(roots) != 1 or canonical(roots[0]) != policy:
            problems.append(attr + ': does not match A11 database-only encrypted backup policy')
    return problems


def check_network_config(roots, flavor, facts):
    problems = []

    def unexpected(el, allowed_attrs, allowed_children, where):
        for a in el.attrs:
            if a not in allowed_attrs:
                problems.append(f"{where}: unexpected attribute {a}={el.attrs[a]}")
        for c in el.children:
            if c.name not in allowed_children:
                problems.append(f"{where}: unexpected element <{c.name}>")
        if el.texts and el.name != "domain":
            problems.append(f"{where}: unexpected text {el.texts}")

    def trust_anchors(el, where):
        unexpected(el, (), ("certificates",), where)
        for cert in el.children:
            if cert.name != "certificates":
                continue
            unexpected(cert, ("src",), (), where + "/certificates")
            if cert.attrs.get("src") != '"system" (Raw: "system")':
                problems.append(f"{where}: trust anchor <certificates src={cert.attrs.get('src')}> "
                                "(only src=\"system\" is allowed)")

    if len(roots) != 1 or roots[0].name != "network-security-config":
        return ["network security config: not exactly one <network-security-config>"]
    root = roots[0]
    unexpected(root, (), ("base-config", "domain-config"), "network-security-config")

    bases = [c for c in root.children if c.name == "base-config"]
    if len(bases) != 1:
        problems.append(f"network security config: {len(bases)} <base-config> elements (need exactly one)")
    for base in bases:
        raw = base.attrs.get("cleartextTrafficPermitted")
        facts.append(f"base-config cleartextTrafficPermitted={raw if raw is not None else '(unset)'}")
        if raw is None:
            problems.append("base-config does not set cleartextTrafficPermitted (must be explicitly false)")
        elif boolean(raw) is not False:
            problems.append(f"base-config cleartextTrafficPermitted is {raw} (must be explicitly false)")
        unexpected(base, ("cleartextTrafficPermitted",), ("trust-anchors",), "base-config")
        for ta in base.children:
            if ta.name == "trust-anchors":
                trust_anchors(ta, "base-config/trust-anchors")

    for dc in (c for c in root.children if c.name == "domain-config"):
        domains = [(d.texts, d.attrs.get("includeSubdomains")) for d in dc.children if d.name == "domain"]
        names = ", ".join(t for texts, _ in domains for t in texts)
        facts.append(f"domain-config cleartextTrafficPermitted={dc.attrs.get('cleartextTrafficPermitted')} "
                     f"domains: {names}")
        if flavor != "dev":
            problems.append(f"{flavor}: <domain-config> is not allowed (domains: {names})")
            continue
        unexpected(dc, ("cleartextTrafficPermitted",), ("domain",), "domain-config")
        if boolean(dc.attrs.get("cleartextTrafficPermitted", "false")) is None:
            problems.append(f"domain-config cleartextTrafficPermitted is {dc.attrs['cleartextTrafficPermitted']}")
        if not domains:
            problems.append("domain-config without a <domain>")
        for texts, sub in domains:
            if len(texts) != 1 or texts[0] not in DEV_CLEARTEXT_DOMAINS:
                problems.append(f"dev: domain-config names {', '.join(texts) or '(empty)'} "
                                "(only 127.0.0.1 and localhost)")
            if sub is not None and boolean(sub) is not False:
                problems.append(f"dev: domain {', '.join(texts)} has includeSubdomains={sub} (must be absent or false)")
        for d in dc.children:
            if d.name == "domain":
                unexpected(d, ("includeSubdomains",), (), "domain-config/domain")
    return problems


# --- Capture (for fixtures) -------------------------------------------------------


def capture(dumps, out):
    """Writes what check() reads. resources.txt keeps only the xml type (the
    full table is ~1600 lines; the network security config is an xml resource)."""
    def write(rel, text):
        path = os.path.join(out, rel)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w", encoding="utf-8") as f:
            f.write(text)

    resources = dumps.resources()
    kept, keep = [], False
    for line in resources.splitlines():
        if re.match(r"\s*type ", line):
            keep = re.match(r"\s*type xml ", line) is not None
        if keep or re.match(r"(Binary APK|Package )", line):
            kept.append(line)
    write("badging.txt", dumps.badging())
    write("resources.txt", "\n".join(kept) + "\n")
    write(f"xmltree/{MANIFEST}.txt", dumps.xmltree(MANIFEST))
    manifest = parse_xmltree(dumps.xmltree(MANIFEST), MANIFEST)
    for root in manifest:
        for app in (c for c in root.children if c.name == "application"):
            for attr in ('networkSecurityConfig', 'fullBackupContent', 'dataExtractionRules'):
                m = re.fullmatch(r"@(0x7f[0-9a-f]{6})", app.attrs.get('android:' + attr, ''))
                if m:
                    for _, path, is_file in resource_files(resources, m.group(1))[1]:
                        if is_file:
                            write(f"xmltree/{safe_path(path)}.txt", dumps.xmltree(path))


def main():
    p = argparse.ArgumentParser(prog="apk_hardening_check.py", description=__doc__.split("\n")[0])
    p.add_argument("--flavor", choices=FLAVORS)
    p.add_argument("--aapt2")
    p.add_argument("--dumps", metavar="DIR")
    p.add_argument("--capture", metavar="DIR")
    p.add_argument("apk", nargs="?")
    a = p.parse_args()
    try:
        if a.capture:
            if not (a.aapt2 and a.apk):
                p.error("--capture needs --aapt2 and an APK")
            capture(ApkDumps(a.aapt2, a.apk), a.capture)
            return 0
        if not a.flavor or bool(a.dumps) == bool(a.apk):
            p.error("give --flavor and either an APK (with --aapt2) or --dumps DIR")
        if a.apk and not a.aapt2:
            p.error("an APK needs --aapt2")
        dumps = DirDumps(a.dumps) if a.dumps else ApkDumps(a.aapt2, a.apk)
        problems, facts = check(dumps, a.flavor)
    except DumpError as e:
        print(f"{NAME}: error: {e}", file=sys.stderr)
        return 2
    for fact in facts:
        print(f"  {fact}")
    sys.stdout.flush()
    for problem in problems:
        print(f"{NAME}: error: {problem}", file=sys.stderr)
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
