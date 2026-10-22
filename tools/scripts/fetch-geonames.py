#!/usr/bin/env python3
"""Download pinned city dumps to an empty directory outside the repository.

The upstream URLs change daily. Preserve matching downloads for exact rebuilds;
checksum mismatch requires a reviewed sources.yaml refresh, never silent repins.
"""
import hashlib
import json
from pathlib import Path
import sys
import urllib.request
import zipfile


def fetch(output: Path, repo: Path) -> None:
    output = output.resolve()
    if output == repo or repo in output.parents:
        raise ValueError("bulk output must be outside the repository")
    if output.exists() and any(output.iterdir()):
        raise ValueError("output directory must be empty")
    # JSON is a YAML subset; this metadata deliberately needs no PyYAML.
    pins = json.loads((repo / "data/geonames/sources.yaml").read_text())
    datasets = pins["datasets"]
    expected = {"cities1000", "cities15000", "PS", "JO", *pins["selection"]["regional"]}
    if len(datasets) != len(expected) or {d["name"] for d in datasets} != expected:
        raise ValueError("expected city dumps and all local/regional alternate pins")
    output.mkdir(parents=True, exist_ok=True)
    for dataset in datasets:
        name = dataset["name"]
        relative = f"alternatenames/{name}" if len(name) == 2 else name
        url = f"https://download.geonames.org/export/dump/{relative}.zip"
        if dataset["url"] != url:
            raise ValueError("unexpected GeoNames URL")
        archive = output / f"{name}.zip"
        with urllib.request.urlopen(url, timeout=90) as response, archive.open("wb") as target:
            digest = hashlib.sha256()
            total = 0
            while block := response.read(1024 * 1024):
                total += len(block)
                if total > 50_000_000:
                    raise ValueError("download exceeds city archive budget")
                digest.update(block)
                target.write(block)
        if digest.hexdigest() != dataset["sha256"]:
            raise ValueError(f"{name}: checksum mismatch; retain the pinned downloads or review and refresh sources.yaml")
        with zipfile.ZipFile(archive) as source:
            info = source.getinfo(f"{name}.txt")
            if info.file_size > 100_000_000:
                raise ValueError("city text exceeds import budget")
            text = source.read(info)
        if hashlib.sha256(text).hexdigest() != dataset["text_sha256"]:
            raise ValueError(f"{name}: text checksum mismatch")
        (output / f"{name}.txt").write_bytes(text)
        print(f"fetch-geonames: verified {name}")


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: fetch-geonames.py <empty-directory-outside-repo>", file=sys.stderr)
        return 64
    try:
        fetch(Path(sys.argv[1]), Path(__file__).resolve().parents[2])
    except (OSError, ValueError, KeyError, zipfile.BadZipFile) as error:
        print(f"fetch-geonames: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
