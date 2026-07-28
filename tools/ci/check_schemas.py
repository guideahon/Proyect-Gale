#!/usr/bin/env python3
"""Valida los JSON Schemas, el mod de ejemplo, templates y los casos dorados.

python tools/ci/check_schemas.py

Comprueba cuatro cosas:

1. cada archivo de `schemas/` es un JSON Schema Draft 2020-12 válido;
2. cada archivo de `examples/` valida contra el schema que le corresponde por
   convención de nombre (`*.weapon.json` -> `weapon.schema.json`);
3. cada archivo de `templates/*.example.json` valida contra su schema;
4. cada caso de `tests/data/schema_cases.json` valida o falla según lo declarado.

PROVISORIO. Sólo verifica forma, no reglas de juego: no resuelve IDs entre
registries, no comprueba presupuestos agregados ni dependencias. Esa validación
es la del runtime y se escribe en GDScript en M3 (`core/mods/schema_validator.gd`)
para cumplir el riesgo R6: una sola implementación de reglas compartida entre el
juego y el validador de línea de comandos. Cuando exista, este script se retira.
"""

import json
import pathlib
import sys

try:
    from jsonschema import Draft202012Validator
except ImportError:
    print("falta la dependencia: pip install jsonschema", file=sys.stderr)
    raise SystemExit(2)

ROOT = pathlib.Path(__file__).resolve().parents[2]
SCHEMA_DIR = ROOT / "schemas"
CASES_FILE = ROOT / "tests" / "data" / "schema_cases.json"
TEMPLATES_DIR = ROOT / "templates"

# Archivos de ejemplo cuyo nombre no sigue la convención `*.<tipo>.json`.
EXPLICIT_EXAMPLES = {
    "manifest.json": "mod_manifest",
}

failures = []


def load_schemas() -> dict:
    schemas = {}
    for path in sorted(SCHEMA_DIR.glob("*.schema.json")):
        name = path.name[: -len(".schema.json")]
        data = json.loads(path.read_text(encoding="utf-8"))
        try:
            Draft202012Validator.check_schema(data)
        except Exception as exc:  # noqa: BLE001 - queremos el mensaje crudo
            failures.append("schema inválido %s: %s" % (path.name, exc))
            continue
        schemas[name] = data
    return schemas


def schema_for(path: pathlib.Path) -> str:
    if path.name in EXPLICIT_EXAMPLES:
        return EXPLICIT_EXAMPLES[path.name]
    parts = path.name.split(".")
    # *.example.json -> el schema es el segmento antes de "example"
    if parts[-2] == "example":
        return parts[-3] if len(parts) >= 3 else ""
    # *.weapon.json -> el schema es el segmento antes de "weapon"
    if len(parts) >= 3:
        return parts[-2]
    return ""


def validate(schema: dict, document, label: str, should_pass: bool) -> None:
    errors = list(Draft202012Validator(schema).iter_errors(document))
    passed = not errors
    if passed == should_pass:
        print("  ok   %s" % label)
        return
    detail = errors[0].message if errors else "validó cuando debía fallar"
    failures.append("%s: %s" % (label, detail))
    print("  FALLA %s -> %s" % (label, detail))


def main() -> int:
    schemas = load_schemas()
    print("schemas válidos: %d" % len(schemas))

    print("\nejemplos:")
    example_count = 0
    for path in sorted((ROOT / "examples").rglob("*.json")):
        name = schema_for(path)
        if not name:
            continue
        if name not in schemas:
            failures.append("%s no tiene schema '%s'" % (path, name))
            print("  FALLA %s -> no existe schemas/%s.schema.json" % (path.name, name))
            continue
        document = json.loads(path.read_text(encoding="utf-8"))
        validate(schemas[name], document, str(path.relative_to(ROOT)), True)
        example_count += 1
    if example_count == 0:
        failures.append("no se encontró ningún ejemplo para validar")

    print("\ntemplates:")
    template_count = 0
    for path in sorted(TEMPLATES_DIR.glob("*.example.json")):
        name = schema_for(path)
        if not name:
            continue
        if name not in schemas:
            # No es un error: algunos templates no tienen schema (ej. asset_manifest).
            print("  skip %s -> no schema '%s'" % (path.name, name))
            continue
        document = json.loads(path.read_text(encoding="utf-8"))
        validate(schemas[name], document, str(path.relative_to(ROOT)), True)
        template_count += 1
    if template_count == 0:
        print("  (no hay templates/*.example.json con schema)")

    print("\ncasos dorados:")
    cases = json.loads(CASES_FILE.read_text(encoding="utf-8"))["cases"]
    for case in cases:
        name = case["schema"]
        if name not in schemas:
            failures.append("caso '%s' apunta a un schema inexistente: %s" % (case["label"], name))
            continue
        validate(schemas[name], case["document"], case["label"], case["valid"])

    print("")
    if failures:
        print("FALLÓ: %d problema(s)" % len(failures), file=sys.stderr)
        return 1
    print("OK: %d schemas, %d ejemplos, %d templates, %d casos" % (len(schemas), example_count, template_count, len(cases)))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
