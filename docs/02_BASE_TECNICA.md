# Base técnica

## Stack inicial fijado

- Godot Engine 4.7.1 estable.
- Renderer Compatibility como baseline de Quest.
- OpenXR.
- Godot OpenXR Vendors Plugin.
- Godot XR Tools, importando sólo módulos requeridos.
- GDScript para lógica ordinaria.
- GDExtension/C++ sólo después de medir cuellos de botella.
- Blender para creación y reprocesamiento de assets.
- glTF/GLB como formato de intercambio.
- PCK para contenido compilado.
- ZIP `.gmod` como contenedor de distribución de mods.
- Git, Git LFS y GitHub Actions.

## Razón de elegir Godot

Godot ofrece un editor completo, código disponible, licencia MIT, soporte de OpenXR, exportación Android, recursos serializables, PCK cargables en ejecución, LOD de mallas, rangos de visibilidad, MultiMesh, herramientas de animación, navegación, física y una comunidad XR activa.

No se pretende utilizar todo el motor. El proyecto define un subconjunto estricto de funciones aceptadas para Quest.

## Plataformas

### Quest 1

- Objetivo: 72 Hz.
- Perfil Legacy.
- Resolución y distancia visual reducidas.
- Distribución por sideload.
- No se promete modo 120 Hz porque el dispositivo no lo admite.

### Quest 2

- Objetivo principal: modo experimental estricto de 120 Hz.
- Perfil alternativo: 90 Hz estable.
- Foveated rendering fijo.
- Resolución dinámica.
- Presupuesto extremadamente restrictivo.

### Quest 3 y posteriores

- Objetivo: 120 Hz con mejor resolución y distancia de LOD.
- Misma lógica y contenido.
- Perfiles de calidad diferenciados.

### PCVR

- OpenXR.
- Frecuencia correspondiente al visor.
- Mejoras opcionales de sombras, distancia y resolución, sin romper la estética.

## Política de versiones

La versión de Godot se fija por release del juego. No se actualiza el motor en medio de un ciclo de producción sin:

1. rama de migración;
2. benchmark comparativo;
3. prueba de exportación Android;
4. prueba de carga de mods;
5. validación de partidas guardadas;
6. aprobación documentada en un ADR.
