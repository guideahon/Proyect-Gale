# Version baseline

Fecha: 2026-07-28

- Godot Engine: 4.7.1 stable, build oficial `a13da4feb`. Verificado: importa el proyecto y ejecuta scripts headless en Windows.
- Export templates: `Godot_v4.7.1-stable_export_templates.tpz`, SHA-256 `86409db6200b6f8fd3230989c2d2002851f3dd18acf11d7bdbafddf5a0dd0f72`. Instalación completa (incluye `android_source.zip`; el build template Gradle vive en `android/`, ignorado por git).
- Android export: **Gradle build obligatorio** (`gradle_build/use_gradle_build=true`). El vendor plugin sólo inyecta las entradas VR de Meta al manifest vía Gradle; con el APK-plantilla la app se lanza como panel 2D.
- Renderer Quest baseline: provisional `mobile` (Vulkan Mobile, requerido por el vendor plugin en Quest 3). ADR-007 proponía Compatibility; la decisión final es ADR-011 y sale de medir S2 en el visor.
- OpenXR: integrado en Godot.
- Vendor plugin: godot_openxr_vendors 5.1.0-stable (GodotVR/godot_openxr_vendors).
- Mod API: 1.0 provisional.
- Formato `.gmod`: 1 provisional.
- JSON Schema: Draft 2020-12.
- Quest 1: 72 Hz.
- Quest 2: 120 Hz como objetivo estricto medido, con perfiles alternativos.
- Licencia de código propuesta: MIT.

Toda versión exacta de addon debe quedar fijada por commit o tag en el lockfile del proyecto.
