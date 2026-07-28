# Proyecto Gale — Documentación maestra

**Estado:** preproducción técnica  
**Versión de la documentación:** 0.1  
**Fecha:** 2026-07-28  
**Nombre provisional:** Proyecto Gale

Proyecto Gale es un juego de aventura y exploración en realidad virtual, de estética cel-shaded y low-poly inspirada en la claridad visual de los juegos de la era GameCube. El proyecto será software libre, se distribuirá mediante APK y tendrá una arquitectura centrada en mods.

## Objetivos fundacionales

1. Mundo abierto por archipiélagos, islas y sectores.
2. Movimiento VR con locomoción, escalada, planeo, navegación, espada, escudo y arco.
3. Estética toon original, sin reutilizar propiedad intelectual de terceros.
4. Godot 4.7.1 + OpenXR como base técnica inicial.
5. Quest 2 como dispositivo mínimo del modo experimental de 120 Hz.
6. Quest 1 soportado a 72 Hz cuando sea técnicamente viable.
7. Contenido oficial construido con las mismas APIs públicas que los mods.
8. Assets gratuitos o libres cuando sean adecuados, reprocesados para una dirección artística coherente.
9. Ninguna función se considera terminada hasta probar rendimiento sostenido en hardware real.
10. Los 120 FPS son un objetivo de certificación por escena y por mod; no una promesa automática para contenido comunitario arbitrario.

## Índice recomendado

- `docs/01_VISION_Y_ALCANCE.md`
- `docs/02_BASE_TECNICA.md`
- `docs/03_PRESUPUESTOS_DE_RENDIMIENTO.md`
- `docs/04_RENDERIZADO_LOD_E_IMPOSTORES.md`
- `docs/05_MUNDO_STREAMING_Y_CULLING.md`
- `docs/06_GAMEPLAY_VR.md`
- `docs/07_ARQUITECTURA_DE_SOFTWARE.md`
- `docs/08_ARQUITECTURA_DE_MODS.md`
- `docs/09_API_DE_MODS.md`
- `docs/10_FORMATOS_DE_CONTENIDO.md`
- `docs/11_PIPELINE_DE_ASSETS.md`
- `docs/12_CATALOGO_DE_ASSETS_GRATUITOS.md`
- `docs/13_DISENO_DEL_JUEGO.md`
- `docs/14_ROADMAP.md`
- `docs/15_TESTING_Y_QA.md`
- `docs/16_REPOSITORIO_Y_CI.md`
- `docs/17_LICENCIAS_Y_GOBERNANZA.md`
- `docs/18_GUIA_DE_CONTRIBUCION.md`
- `docs/19_SEGURIDAD_DE_MODS.md`
- `docs/20_REGISTRO_DE_DECISIONES.md`
- `docs/21_REFERENCIAS_TECNICAS.md`
- `docs/22_GLOSARIO.md`
- `docs/23_PLAN_DE_IMPLEMENTACION.md`
- `docs/24_FIRMA_Y_EMPAQUETADO.md`
- `docs/25_CHECKLIST_DE_EJECUCION.md`
- `AGENTS.md` — instrucciones operativas para quien implementa
- `schemas/`
- `examples/sample_mod/`
- `core/`
- `tests/`

## Regla de oro

> El contenido oficial no debe depender de privilegios que no estén disponibles para un mod comunitario, salvo las funciones explícitamente reservadas al núcleo por seguridad, estabilidad o rendimiento.
