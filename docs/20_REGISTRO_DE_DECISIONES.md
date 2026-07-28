# Registro de decisiones arquitectónicas

## ADR-001 — Godot 4.7.1

**Estado:** aceptada provisionalmente.  
**Motivo:** motor libre, OpenXR, Android, editor, PCK, recursos y ecosistema XR.  
**Revisión:** después del benchmark de isla.

## ADR-002 — Quest 2 como objetivo 120 Hz

**Estado:** aceptada.  
Quest 1 usa 72 Hz. El modo 120 Hz es certificado por contenido, no garantizado para cualquier mod.

## ADR-003 — Archipiélago

**Estado:** aceptada.  
Facilita streaming, HLOD y líneas de visión controladas.

## ADR-004 — Contenido oficial como mod

**Estado:** aceptada.  
Evita APIs de segunda clase y prueba la moddeabilidad continuamente.

## ADR-005 — Mods declarativos por defecto

**Estado:** aceptada.  
Permite validación, seguridad y control de rendimiento.

## ADR-006 — GDScript sólo en modo desarrollador

**Estado:** aceptada.  
No existe garantía de sandbox completo para código arbitrario.

## ADR-007 — Renderer Compatibility como baseline

**Estado:** provisional.  
Debe compararse con Mobile/Vulkan mediante benchmark en hardware real.

## ADR-008 — Toon shader limitado

**Estado:** aceptada.  
Evita proliferación de shaders y facilita batching, estética y certificación.

## ADR-009 — Assets CC0 preferidos

**Estado:** aceptada.  
Simplifica redistribución, forks y ModKit.

## ADR-010 — No prometer 120 FPS antes del benchmark

**Estado:** aceptada.  
La documentación distingue objetivo, presupuesto y garantía medida.

## ADR-012 — Alcance real de la garantía del modo declarativo

**Estado:** aceptada.  
**Cierra:** Spike S6.  
**Motivo:** Godot 4.7.1 carga y ejecuta scripts `.gd` de PCKs montados sin restricción. No existe mecanismo nativo para bloquear la ejecución de scripts en un PCK sin deshabilitar scripts por completo.  
**Decisión:** validador por lista blanca de extensiones y tipos de recurso. El validador de paquetes (`core/mods/package_reader.gd`, T3.5) debe rechazar `.gd`, `.gdshader`, `.gdnlib`, `.cgf` y escenas con scripts adjuntos antes de montar.  
**Revisión:** si Godot añade un sandbox nativo o una bandera para deshabilitar scripts por origen.

## ADR-014 — Herramienta de impostores: Blender scripts

**Estado:** aceptada.  
**Motivo:** docs/04 define impostores multivista (100–300 m). Se eligieron scripts de Blender sobre plugin de editor Godot porque son automatizables en CI, independientes de versión de Godot y se integran con el pipeline de assets de docs/11.  
**Consecuencias:** requiere Blender instalado; pipeline adicional entre modelado y motor.  
**Validación pendiente:** medición de coste de atlas (8 vs 16 vistas) requiere hardware real (S7 ⚑).

## ADR-015 — Firma RSA sobre payload canónico

**Estado:** aceptada provisionalmente.  
**Motivo:** el APK público debe verificar firmas sin extensiones nativas, y la API de criptografía del motor expone RSA y X.509, no Ed25519. Se firma un payload canónico de hashes en lugar del ZIP porque el ZIP no es reproducible entre herramientas.  
**Alcance:** la firma indica procedencia, no seguridad; la confianza es TOFU y el contenido oficial usa clave anclada.  
**Revisión:** si el motor expone Ed25519.  
**Detalle:** `docs/24`.
