"""A03 D11/D12: Open Food Facts coverage for Palestine / Jordan / Israel.

Reads the OFF TSV export on stdin (decompressed), streaming, constant memory.
Prints aggregates only (Markdown). Never writes or echoes product rows.
Usage: gzip -dc export.csv.gz | python3 -I off_coverage.py SAMPLE.yaml
"""

import csv
import re
import sys
from collections import Counter

REGION_RE = re.compile(r"palest|jordan|israel|west-bank|gaza")
REQUIRED = [
    "code",
    "countries_tags",
    "brands_tags",
    "product_name",
    "energy-kcal_100g",
    "energy_100g",
    "proteins_100g",
    "carbohydrates_100g",
    "fat_100g",
    "fiber_100g",
]
THRESHOLD = 0.40


def parse_sample(text):
    """Parse the restricted YAML subset of data/sources/off_local_sample.yaml."""
    items, cur = [], None
    for raw in text.splitlines():
        line = raw.rstrip()
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        m = re.match(r"^- (\w+):\s*(.*)$", line)
        if m:
            cur = {}
            items.append(cur)
        else:
            m = re.match(r"^\s+(\w+):\s*(.*)$", line)
        if not m or cur is None:
            raise ValueError("unparseable sample line: " + line)
        key, val = m.group(1), m.group(2).strip()
        if val.startswith("[") and val.endswith("]"):
            cur[key] = [v.strip().lower() for v in val[1:-1].split(",") if v.strip()]
        else:
            cur[key] = val
    return items


def num(s):
    try:
        return float(s)
    except (TypeError, ValueError):
        return None


def completeness(row):
    kcal = num(row["energy-kcal_100g"])
    if kcal is None:
        kj = num(row["energy_100g"])
        kcal = None if kj is None else kj / 4.184
    c4 = (
        kcal is not None
        and all(num(row[k]) is not None for k in ("proteins_100g", "carbohydrates_100g", "fat_100g"))
    )
    c5 = c4 and num(row["fiber_100g"]) is not None
    return c4, c5


def matches(item, brands, name):
    if not any(b in tag for b in item["brand_any"] for tag in brands):
        return False
    return any(w in name for w in item["name_any"])


def analyze(lines, sample):
    reader = csv.DictReader(lines, delimiter="\t", quoting=csv.QUOTE_NONE)
    missing = [c for c in REQUIRED if c not in (reader.fieldnames or [])]
    if missing:
        raise SystemExit("missing columns in export: " + ", ".join(missing))
    total = 0
    tags = Counter()
    per = {}  # group -> [products, c4, c5]
    prefixes = {}
    found = {s["id"]: [0, 0, 0] for s in sample}  # found, c4, c5 (any country)
    for row in reader:
        total += 1
        brands = (row["brands_tags"] or "").lower().split(",")
        name = (row["product_name"] or "").lower()
        # sample matching is global: the question is whether OFF knows the product
        c4 = c5 = None
        for s in sample:
            if matches(s, brands, name):
                if c4 is None:
                    c4, c5 = completeness(row)
                f = found[s["id"]]
                f[0] += 1
                f[1] += c4
                f[2] += c5
        ctags = [t.strip() for t in (row["countries_tags"] or "").lower().split(",") if t.strip()]
        region = [t for t in ctags if REGION_RE.search(t)]
        if not region:
            continue
        tags.update(region)
        if c4 is None:
            c4, c5 = completeness(row)
        code = (row["code"] or "").strip()
        pre = code[:3] if code.isdigit() else "n/a"
        groups = set(region)
        groups.add("ALL")
        if any("palest" in t or "jordan" in t for t in region):
            groups.add("PS_or_JO")
        for g in groups:
            r = per.setdefault(g, [0, 0, 0])
            r[0] += 1
            r[1] += c4
            r[2] += c5
        for g in ("ALL", "PS_or_JO"):
            if g in groups:
                prefixes.setdefault(g, Counter())[pre] += 1
    return {"total": total, "tags": tags, "per": per, "prefixes": prefixes, "found": found}


def pct(a, b):
    return "n/a" if not b else "%.1f%%" % (100.0 * a / b)


def report(res, sample):
    out = ["### Rows in export", "", "%d" % res["total"], "", "### Discovered country tags", "",
           "| tag | products |", "|---|---:|"]
    for t, n in sorted(res["tags"].items(), key=lambda x: -x[1]):
        out.append("| `%s` | %d |" % (t, n))
    out += ["", "### Products and completeness", "",
            "| group | products | complete-4 | % | complete-5 | % |", "|---|---:|---:|---:|---:|---:|"]
    for g in sorted(res["per"], key=lambda g: (g not in ("PS_or_JO", "ALL"), g)):
        n, c4, c5 = res["per"][g]
        out.append("| `%s` | %d | %d | %s | %d | %s |" % (g, n, c4, pct(c4, n), c5, pct(c5, n)))
    out += ["", "complete-4 = kcal (or kJ/4.184), protein, carbs, fat; complete-5 adds fiber.", ""]
    for g in ("PS_or_JO", "ALL"):
        c = res["prefixes"].get(g)
        if not c:
            continue
        out += ["### GS1 prefix split (`%s`, top 10 of %d)" % (g, sum(c.values())), "",
                "| prefix | products | share |", "|---|---:|---:|"]
        for p, n in c.most_common(10):
            out.append("| %s | %d | %s |" % (p, n, pct(n, sum(c.values()))))
        out.append("")
    out += ["### Local sample (matched anywhere in OFF)", "",
            "| product | region | found | complete-4 | complete-5 |", "|---|---|---:|---:|---:|"]
    n_found4 = 0
    for s in sample:
        f, c4, c5 = res["found"][s["id"]]
        n_found4 += c4 > 0
        out.append("| %s | %s | %d | %d | %d |" % (s["name"], s.get("region", ""), f, c4, c5))
    n = len(sample)
    share = n_found4 / n if n else 0
    verdict = ("label scan is the MAIN path (A28 optimises it first)" if share < THRESHOLD
               else "barcode first, label scan as the fallback")
    out += ["", "### D12 verdict", "",
            "Sample products found with complete-4 data: %d of %d (%s); threshold %d%%."
            % (n_found4, n, pct(n_found4, n), THRESHOLD * 100),
            "", "**Verdict: %s.**" % verdict]
    return "\n".join(out)


def main(argv):
    if len(argv) != 2:
        raise SystemExit("usage: off_coverage.py SAMPLE.yaml < export.tsv")
    csv.field_size_limit(1 << 30)
    with open(argv[1], encoding="utf-8") as f:
        sample = parse_sample(f.read())
    stdin = open(sys.stdin.fileno(), encoding="utf-8", errors="replace", newline="")
    print(report(analyze(stdin, sample), sample))


if __name__ == "__main__":
    main(sys.argv)
