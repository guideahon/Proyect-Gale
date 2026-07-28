# ADR-014 — Herramienta de impostores: Blender scripts

**Estado:** aceptada  
**Fecha:** 2026-07-28  
**Responsables:** equipo Gale

## Contexto

docs/04 define impostores multivista como etapa 4 de la cadena de representación (100–300 m). Se necesita una herramienta para generar atlas de 8 o 16 vistas a partir de un modelo 3D. Las opciones son:

1. Scripts de Blender que generen renders ortográficos y los compongan en un atlas.
2. Plugin de editor Godot que capture vistas desde la escena.

## Opciones

1. **Blender scripts.** Pipeline fuera del motor: render ortográfico desde N ángulos, composición de atlas, export GLB con UV impostor. Ventaja: se puede correr en CI, no requiere motor abierto. Desventaja: pipeline adicional.
2. **Plugin de editor Godot.** Captura directa desde la escena. Ventaja: integración nativa. Desventaja: requiere editor abierto, no automatizable en CI, más acoplado a versión de Godot.

## Decisión

Blender scripts. Motivos:

- Automatizable en CI: se puede validar que un asset produce un atlas correcto sin abrir el editor.
- Independiente de versión de Godot: el atlas es un archivo de textura, no depende de APIs internas.
- docs/11 ya define scripts de Blender como pipeline de assets; el baker de impostores se integra naturalmente.
- El plugin de editor se puede añadir después como conveniencia, sin cambiar el formato de salida.

## Consecuencias

### Positivas

- Pipeline de impostores testeable y reproducible.
- CI puede verificar que un asset nuevo genera un atlas válido.
- Separación clara entre generación de assets y runtime.

### Negativas

- Requiere Blender instalado en la máquina de desarrollo.
- Pipeline adicional entre modelado y uso en el motor.

## Validación

- `tools/blender/impostor_baker.py` genera un atlas de 8 vistas de un modelo de prueba.
- El atlas se usa en una escena de benchmark con `ToonImpostor`.
- Coste medido: draw calls y memoria de textura del atlas vs LOD2 del mismo modelo.
- S7 marcado `[x]` con la evidencia de coste.
