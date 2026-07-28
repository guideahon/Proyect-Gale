---
name: Pull Request
about: Cambios al Proyecto Gale
---

## Resumen

<!-- Qué hace este PR y por qué. -->

## Tipo de cambio

- [ ] Nueva funcionalidad
- [ ] Corrección de bug
- [ ] Mejora de rendimiento
- [ ] Documentación
- [ ] Test
- [ ] CI / infraestructura

## Verificación

- [ ] `godot --headless --path . --import` limpio
- [ ] `godot --headless --path . --script tests/run_all.gd` verde
- [ ] `python tools/ci/check_schemas.py` verde
- [ ] `python tools/ci/build_file_index.py --check` verde
- [ ] `FILE_INDEX.json` regenerado

## Rendimiento (si aplica)

| Métrica | Antes | Después | Variación |
|---|---|---|---|
| CPU frame time P95 | | | |
| GPU frame time P95 | | | |
| Draw calls | | | |
| Triángulos | | | |
| Memoria de texturas | | | |
| Materiales | | | |

## Impacto

<!-- Qué otras áreas podría afectar este cambio. -->

## Capturas (si aplica)

<!-- Capturas de pantalla o video de la escena de prueba. -->
