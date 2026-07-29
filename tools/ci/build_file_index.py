#!/usr/bin/env python3
"""Regenera FILE_INDEX.json."""

import argparse
import hashlib
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
INDEX = ROOT / "FILE_INDEX.json"
PROJECT = "Proyecto Gale"
DOCUMENTATION_VERSION = "0.2"

SKIP_DIRS = {".git", ".godot", ".import", "exports", "__pycache__", ".venv",
             "node_modules", ".llamacode", ".playwright-mcp"}
SKIP_FILES = {"FILE_INDEX.json", ".DS_Store"}
SKIP_SUFFIXES = {".pyc", ".apk", ".aab", ".keystore", ".jks", ".import", ".exe", ".zip"}


def iter_files():
    for path in ROOT.rglob("*"):
        if not path.is_file():
            continue
        rel = path.relative_to(ROOT)
        if any(part in SKIP_DIRS for part in rel.parts):
            continue
        if rel.name in SKIP_FILES or path.suffix in SKIP_SUFFIXES:
            continue
        yield rel, path


def sha256_of(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(65536), b""):
            digest.update(chunk)
    return digest.hexdigest()


def build(generated_at: str) -> dict:
    entries = []
    for rel, path in iter_files():
        entries.append({
            "path": rel.as_posix(),
            "bytes": path.stat().st_size,
            "sha256": sha256_of(path),
        })
    entries.sort(key=lambda e: e["path"].encode("utf-8"))
    return {
        "project": PROJECT,
        "documentation_version": DOCUMENTATION_VERSION,
        "generated_at": generated_at,
        "files": entries,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--date", default=None)
    args = parser.parse_args()

    previous = json.loads(INDEX.read_text(encoding="utf-8")) if INDEX.exists() else {}
    generated_at = args.date or previous.get("generated_at", "")
    index = build(generated_at)

    if args.check:
        if previous.get("files") == index["files"]:
            print("FILE_INDEX.json actualizado")
            return 0
        print("FILE_INDEX.json desactualizado: correr tools/ci/build_file_index.py", file=sys.stderr)
        return 1

    INDEX.write_text(json.dumps(index, indent=2, ensure_ascii=False) + "\n",
                     encoding="utf-8", newline="\n")
    print("FILE_INDEX.json: %d archivos" % len(index["files"]))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
