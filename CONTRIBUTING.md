# Contribuir al Proyecto Gale

Gracias por tu interés. Este documento explica cómo contribuir de forma efectiva.

## Reglas básicas

1. **El núcleo implementa capacidad, no contenido.** Ninguna espada, isla, misión ni enemigo concreto vive en `core/`.
2. **IDs namespaced siempre**: `official:sword_basic`, `autor.mod:contenido`.
3. **Sin contenido de terceros con derechos de autor.** No usar assets, nombres, música ni símbolos de Zelda, Nintendo u otros juegos.
4. **Todo asset externo se registra** en `THIRD_PARTY.md` con fuente, licencia, modificaciones y hash.

## Flujo de trabajo

1. Forkeá el repositorio.
2. Creá una rama `feature/<tema>` desde `main`.
3. Implementá el cambio mínimo.
4. Escribí tests. Cada `.gd` nuevo en `core/` necesita su `tests/unit/test_*.gd`.
5. Corré la batería de regresión completa:

   ```bash
   godot --headless --path . --import
   godot --headless --path . --script tests/run_all.gd
   python tools/ci/check_schemas.py
   python tools/ci/build_file_index.py --check
   ```

6. Actualizá `FILE_INDEX.json` si agregaste o modificaste archivos.
7. Commit con formato: `tipo(scope): descripción en inglés, imperativo, sin punto final`.

   Ejemplos:
   - `feat(modding): add dependency resolver`
   - `fix(save): preserve missing mod entities`
   - `test(mods): cover semver prerelease gate`

## Convenciones de código

- GDScript con tipos explícitos. `snake_case` para funciones, `PascalCase` para clases.
- Identificadores en inglés, comentarios en español.
- Comentá el *porqué*, no el *qué*.

## Pull requests

Usá la plantilla de PR. Toda PR visual debe incluir la tabla de rendimiento:

| Métrica | Antes | Después | Variación |
|---|---|---|---|
| CPU frame time P95 | | | |
| GPU frame time P95 | | | |
| Draw calls | | | |
| Triángulos | | | |
| Memoria de texturas | | | |
| Materiales | | | |

## Licencia

Al contribuir, declarás que:

- poseés derechos sobre el aporte;
- aceptás la licencia del repositorio (MIT para código, CC BY 4.0 para docs);
- no incluís assets extraídos de terceros sin permiso.

## Preguntas

Mirá primero `AGENTS.md` y `docs/25_CHECKLIST_DE_EJECUCION.md`. Si tu cambio toca la Mod API, el formato de save o la arquitectura, necesitás un RFC (`docs/17`).
