#!/usr/bin/env python3
"""Export the contract-owned bounded sync vocabulary; --check is offline CI freshness."""
import argparse
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
KEYWORDS = {"type", "required", "properties", "additionalProperties", "minimum", "maximum", "maxLength", "enum", "format", "items", "maxItems"}


def validate(schema):
    if set(schema) - KEYWORDS:
        raise ValueError("Unsupported sync schema keyword")
    types = schema["type"]
    types = types if isinstance(types, list) else [types]
    if not set(types) <= {"null", "object", "array", "string", "integer", "number", "boolean"}:
        raise ValueError("Unsupported sync schema type")
    if "format" in schema and schema["format"] not in {"uuid", "date"}:
        raise ValueError("Unsupported sync schema format")
    if "object" in types:
        if schema.get("additionalProperties") is not False or set(schema["required"]) != set(schema["properties"]):
            raise ValueError("Sync objects require explicit fields")
        for child in schema["properties"].values():
            validate(child)
    if "items" in schema:
        validate(schema["items"])


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    source = ROOT / "contracts/openapi/sync-entities.json"
    data = json.loads(source.read_text())
    for versions in data["entities"].values():
        for schema in versions.values():
            validate(schema)
    content = json.dumps(data, separators=(",", ":"), ensure_ascii=True) + "\n"
    target = ROOT / "backend/src/Modules/UserData/Infrastructure/Schemas/entities.json"
    if args.check:
        if not target.exists() or target.read_text() != content:
            raise SystemExit("Sync schema export stale: run make gen-sync-schemas")
    else:
        target.write_text(content)


if __name__ == "__main__":
    main()
