#!/usr/bin/env python3
"""Regenera FILE_INDEX.json.

El índice declara tamaño y SHA-256 de cada archivo versionado del repositorio,
para que una copia descargada pueda verificarse sin git. Debe regenerarse en
cada cambio de contenido; el CI lo recalcula y falla si difiere del commit.

    python tools/ci/build_file_index.py            # escribe FILE_INDEX.json
    python tools/ci/build_file_index.py --check    # sólo verifica, salida 1 si difiere
"""

import argparse
import hashlib
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
INDEX = ROOT / "FILE_INDEX.json"
PROJECT = "Proyecto Gale"
DOCUMENTATION_VERSION = "0.2"

# Directorios que nunca entran al índice.
SKIP_DIRS = {".git", ".godot", ".import", "exports", "__pycache__", ".venv", "node_modules", ".llamacode"}
# Archivos que nunca entran al índice.
SKIP_FILES = {"FILE_INDEX.json", ".DS_Store"}
# Extensiones de artefactos de build y binarios que no se versionan.
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
    # Orden byte a byte de la ruta: estable entre plataformas.
    entries.sort(key=lambda e: e["path"].encode("utf-8"))
    return {
        "project": PROJECT,
        "documentation_version": DOCUMENTATION_VERSION,
        "generated_at": generated_at,
        "files": entries,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true", help="no escribe; falla si el índice está desactualizado")
    parser.add_argument("--date", default=None, help="fecha ISO a registrar; por defecto conserva la del índice actual")
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

    INDEX.write_text(json.dumps(index, indent=2, ensure_ascii=False) + "\n", encoding="utf-8", newline="\n")
    print("FILE_INDEX.json: %d archivos" % len(index["files"]))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
