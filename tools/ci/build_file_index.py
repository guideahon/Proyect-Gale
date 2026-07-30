#!/usr/bin/env python3
"""Regenera FILE_INDEX.json."""

import argparse
import hashlib
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
INDEX = ROOT / "FILE_INDEX.json"
PROJECT = "Proyecto Gale"
DOCUMENTATION_VERSION = "0.2"

# El índice cubre exactamente los archivos VERSIONADOS, no lo que haya en disco.
# Escanear el disco lo desincronizaba solo: metía archivos ignorados por git
# (export_presets.cfg, que tiene credenciales y no se versiona) y dejaba afuera
# los `.uid` que Godot crea al importar, después del commit. En un clon limpio
# —o en el runner de CI— el índice nunca podía coincidir.
SKIP_FILES = {"FILE_INDEX.json"}


def tracked_files():
    """Archivos versionados, según git. Es la única fuente de verdad."""
    out = subprocess.run(
        ["git", "-C", str(ROOT), "ls-files", "-z"],
        capture_output=True, text=True, check=True,
    ).stdout
    return [p for p in out.split("\0") if p]


def iter_files():
    for rel_str in tracked_files():
        rel = Path(rel_str)
        if rel.name in SKIP_FILES:
            continue
        path = ROOT / rel
        # Un archivo versionado pero ausente del disco significa árbol sucio;
        # se salta y `--check` lo va a marcar como desactualizado.
        if not path.is_file():
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
