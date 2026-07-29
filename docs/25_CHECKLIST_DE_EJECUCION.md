# Checklist de ejecución

Traducción del plan (`docs/23`) a tareas marcables, cada una con su verificación. Es el documento de trabajo diario: se edita en cada commit.

**Convenciones**

| Marca | Significado |
|---|---|
| `[ ]` | pendiente |
| `[~]` | en curso |
| `[x]` | hecha y verificada |
| `[!]` | bloqueada — anotar motivo y ADR/RFC asociado |
| ⚑ | requiere hardware real (Quest o PCVR). Una IA sin visor no puede completarla **ni inventar el resultado** |

**Reglas**

1. Una tarea no se marca `[x]` sin haber ejecutado su verificación. El resultado se pega en el PR.
2. Antes de cada commit corre la batería de regresión completa, no sólo la prueba de la tarea.
3. Toda tarea que agrega un `.gd` a `core/` agrega su `tests/unit/test_*.gd` en el mismo commit.
4. Toda tarea que agrega un schema agrega casos positivos y negativos a `tests/data/schema_cases.json`.
5. Las tareas ⚑ bloqueadas no detienen el hito: se hace todo lo demás y se deja el gate explícitamente abierto.

---

## Batería de regresión

Se ejecuta antes de cada commit. Los cuatro comandos deben terminar en 0.

```bash
./Godot_v4.7.1-stable_win64_console.exe --headless --path . --import
./Godot_v4.7.1-stable_win64_console.exe --headless --path . --script tests/run_all.gd
python tools/ci/check_schemas.py
python tools/ci/build_file_index.py --check
```

Estado actual verificado: import limpio, 206/206 tests, 16 schemas + 6 ejemplos + 1 template + 33 casos, índice al día.

---

## Fase −1 — Spikes bloqueantes

- [x] **S1.a — Motor disponible.** Godot 4.7.1 stable, build `a13da4feb`, importa y ejecuta scripts headless. **Verificación:** `--import` termina en 0 y `Semver` aparece como clase global registrada.
- [x] **S1.b — Export templates.** `.tpz` verificado contra el SHA-256 de VERSION_BASELINE.md (`86409db6…`), instalación completa en `%APPDATA%\Godot\export_templates\4.7.1.stable\` (la primera copia parcial dejaba afuera `android_source.zip`, necesario para Gradle). Build template Gradle instalado en `android/build` (ignorado por git).
- [x] **S1.c — Addons compatibles.** godot_openxr_vendors 5.1.0-stable vendoreado en `addons/`, fijado en `addons/LOCKFILE.md` y VERSION_BASELINE.md; `--import` limpio y batería verde con el addon presente. **Hallazgo clave:** el plugin sólo inyecta las entradas de Meta al manifest con **Gradle build** (`gradle_build/use_gradle_build=true`); con el APK-plantilla el manifest sale sin nada de Meta y Horizon OS lanza la app como panel 2D (`isVrApplication:false`). **Verificación:** `aapt2 dump xmltree` sobre el APK Gradle (88 MB) muestra `com.oculus.intent.category.VR`, `android.hardware.vr.headtracking`, `com.oculus.supportedDevices` y `com.oculus.vr.focusaware`. XR Tools se difiere a M4 (no se usa todavía).
- [ ] **S2 — Renderer** ⚑. Comparar Compatibility contra Mobile en Quest 2 con la misma escena. **Test:** dos `performance_report.json` de la misma escena; se elige por evidencia. **Salida:** ADR-011 que cierra ADR-007.
- [ ] **S3 — 120 Hz real** ⚑. Solicitar display refresh rate por OpenXR y comprobar bajo qué condiciones el runtime lo revoca. **Test:** log de 5 minutos con la frecuencia efectiva reportada por frame.
- [ ] **S4 — Foveation y resolución** ⚑. Encontrar la combinación de foveation fijo, MSAA y render scale que entra en presupuesto. **Test:** tabla medida de al menos cuatro combinaciones.
- [ ] **S5 — PCK en Android** ⚑. Montar un PCK desde `user://` en el visor, con y sin reinicio. **Test:** el contenido del PCK aparece en un registry tras el arranque.
- [x] **S6 — Sandbox declarativo.** ¿Se puede garantizar que un PCK no contenga `.gd`/`.gdshader` ejecutable, y qué se ejecuta al montarlo? Se prueba en escritorio, no necesita visor. **Test:** spike ejecutado en Godot 4.7.1 headless; scripts `.gd` son cargables y ejecutables desde PCKs montados. **Salida:** ADR-012 — se necesita validador por lista blanca de extensiones y tipos de recurso.
- [~] **S7 — Impostores.** Decisión: Blender scripts (ADR-014). **Pendiente:** falta asset de prueba (.blend/.glb), generación de atlas y medición de coste (8 vs 16 vistas). Requiere hardware real para la comparación visual a 100 m.
- [ ] **S8 — Quest 1** ⚑. Confirmar sideload y runtime OpenXR requerido. **Test:** APK de prueba arranca, o se degrada el objetivo formalmente.

---

## M0 — Fundación

Criterio de salida: build reproducible que arranca en Quest.

- [x] **T0.1 — `.gitignore`.** Excluir motor, `.godot/`, APK, keystores y artefactos. **Test:** `git status --short` no lista binarios.
- [x] **T0.2 — `.gitattributes` con LFS.** GLB, BLEND, audio, texturas fuente, APK y capturas por LFS; JSON, GDScript, Markdown y schemas **no**. Además `eol=lf` en todo el árbol: sin eso, Windows convierte a CRLF al clonar y los SHA-256 de `FILE_INDEX.json` dejan de coincidir. **Test:** `git check-attr filter -- assets/source/models/tree.glb` → `lfs`; `git check-attr filter -- core/mods/semver.gd` → `unspecified`; `git check-attr eol -- core/mods/semver.gd` → `lf`. Verificado.
- [x] **T0.3 — Archivos de licencia.** `LICENSE`, `LICENSE-CODE` (MIT), `LICENSE-ASSETS`, `LICENSE-DOCS` (CC BY 4.0), `THIRD_PARTY.md`, `CREDITS.md` según `docs/17`. **Test:** los seis existen y `THIRD_PARTY.md` tiene la tabla con las columnas exigidas por `docs/12`.
- [ ] **T0.4 — `project.godot` real.** Renderer según ADR-011, OpenXR habilitado, autoloads declarados. **Test:** `--import` limpio; arrancar la escena principal headless no emite errores.
- [ ] **T0.5 — Addons fijados.** Vendor plugin y XR Tools importando sólo los módulos usados, con `addons/LOCKFILE.md`. **Test:** `--import` limpio y el lockfile nombra tag o commit exacto de cada addon.
- [x] **T0.6 — `bootstrap.gd` y `main.tscn`.** Inicializa XR; si OpenXR falla, sale con error legible en lugar de crashear. **Test:** `tests/unit/test_bootstrap.gd` 5/5 — incluye test de autoload declarado en project.godot (R5).
- [x] **T0.7 — Preset de exportación Android ARM64** y `export_presets.template.cfg` sin credenciales. **Test:** exportación headless produce APK de 28.4 MB (`exports/gale.apk`). Key correcta: `textures/vram_compression/import_etc2_astc=true`. Template versionado sin credenciales.
- [~] **T0.8 — Workflow `pr.yml`.** Import headless, tests, `check_schemas.py`, `build_file_index.py --check`, recursos faltantes, export desktop, reporte. **Test:** workflow corregido (sin `--dump-resources`, con hash de Godot, jsonschema instalado, export desktop con fallback). **Bloqueado:** sin remoto git, CI no ejecutado.
- [ ] **T0.9 — Workflow `release.yml`.** APK ARM64, firma, SHA-256, release con checksums. **Test:** tag de prueba produce artefactos y el SHA-256 publicado coincide con el descargado.
- [x] **T0.10 — `CONTRIBUTING.md` y plantilla de PR** con la tabla de rendimiento de `docs/03`. **Test:** existen y la plantilla aparece al abrir una PR nueva.
- [~] **T0.11 — Gate M0** ⚑. **Evidencia:** APK Gradle de 88 MB instalado en el Quest 3 (`adb install` → `Success`), manifest VR verificado con `aapt2`, y al lanzarlo Horizon OS dispara `RequiresControllersLaunchInterceptor` → `LaunchCheckControllerRequiredDialogActivity`, un interceptor que **sólo se aplica a apps VR**: confirma que el sistema la reconoce como inmersiva. La app no llega a arrancar porque el visor está `mWakefulness=Asleep` y sin controllers encendidos; `adb shell am start` tampoco sirve (`SecurityException: not exported`), así que el arranque VR no se puede forzar desde la PC. **Pendiente, y no se puede cerrar sin humano:** ponerse el visor con los controllers encendidos, abrir la app desde Fuentes desconocidas, y confirmar que se ve la escena y que el logcat no dice «OpenXR falló al inicializarse».

---

## M1 — Laboratorio de rendimiento

Criterio de salida: baseline sostenido, medido y automatizado.

- [x] **T1.1 — `frame_probe.gd`.** CPU/GPU frame time, P50/P95/P99, dropped frames, draw calls, triángulos, memoria de texturas. **Nota:** en headless GPU, draw_calls, triángulos y textura son null (no medible). **Test:** `tests/unit/test_frame_probe.gd` calcula percentiles sobre series sintéticas de valor conocido.
- [x] **T1.2 — `profile_manager.gd`.** Perfiles `quest1_72`, `quest2_120_strict`, `quest2_90`, `quest3_120`, `pcvr`, cada uno con render scale, MSAA, foveation, distancias LOD, límites de entidades y frecuencias. **Test:** `tests/unit/test_profile_manager.gd` 36/36 — verifica que ningún perfil declara valores fuera de los rangos de `docs/03` y que cambiar de perfil es idempotente.
- [x] **T1.3 — `dynamic_resolution.gd` con histéresis.** **Test:** con una serie sintética de frame times oscilando alrededor del umbral, la resolución cambia como máximo N veces en 10 segundos.
- [x] **T1.4 — `thermal_logger.gd`.** Muestreo periódico a `user://logs/`. **Test:** `tests/unit/test_thermal_logger.gd` genera archivo CSV parseable; el test lo lee y valida su estructura.
- [x] **T1.5 — `schemas/performance_report.schema.json`.** Formaliza `templates/performance_report.example.json`. **Test:** `check_schemas.py` valida la plantilla y 4 casos nuevos (32 casos dorados totales).
- [~] **T1.6 — `benchmarks/runner.gd` + `runner_entry.gd`.** runner.gd es la lógica de reporte (usa FrameProbe con window=0 ilimitado); runner_entry.gd es el entrypoint SceneTree ejecutable. **Pendiente:** validar que el reporte JSON producido pasa contra el schema (G3: gpu_ms null, draw_calls null, duration_minutes < 1).
- [~] **T1.7 — `benchmark_empty.tscn`.** Escena mínima sin geometría. **Pendiente:** misma validación de schema que T1.6.
- [!] **T1.8 — Escena de calibración.** `benchmarks/calibration_scene.gd` + `calibration_entry.gd` listos: 6 niveles de complejidad, produce curva JSON. **Bloqueado:** requiere hardware real (Quest) para producir datos válidos; en headless los percentiles reflejan overhead de Godot, no GPU real.
- [ ] **T1.9 — Sesión térmica de 30 minutos** ⚑. **Test:** P99 ≤ 8,0 ms sostenido en el perfil estricto; reporte adjunto.
- [ ] **T1.10 — Reconciliar `docs/03`.** Si el punto de ruptura medido contradice la tabla, actualizarla con la evidencia **antes** de seguir a M2. **Test:** la tabla cita el reporte que la respalda.

---

## M2 — Benchmark visual

Criterio de salida: gate duro. 120 Hz sostenido 30 minutos con `benchmark_village`, o decisión formal de recortar alcance.

- [ ] **T2.1 — Familias de shader toon.** Las siete de `docs/04`, con variantes por perfil. **Test:** todas compilan en import; una escena de muestra las usa; ningún shader fuera de la lista existe en el repositorio (chequeo automatizable por nombre de archivo).
- [ ] **T2.2 — `ocean.gd`.** Malla en anillos, olas analíticas, la **misma función** expuesta a GDScript para la altura del barco. **Test:** `tests/unit/test_ocean.gd` compara la altura calculada en GDScript contra valores de referencia; el barco no flota por física.
- [ ] **T2.3 — Isla de prueba 200 × 200 m** en sectores de 64 m. **Test:** el recorrido del runner la atraviesa entera sin huecos.
- [ ] **T2.4 — Scripts de Blender base:** `normalize_scale`, `merge_materials`, `palette_remap`, `generate_lods`, `generate_colliders`, `export_glb`. **Test:** correr el pipeline sobre un asset de prueba y verificar conteo de triángulos, materiales y presencia de LODs contra valores esperados.
- [ ] **T2.5 — MultiMesh por sector y por LOD.** **Test:** el reporte de `benchmark_forest` muestra draw calls dentro de presupuesto; ningún MultiMesh cubre la isla entera.
- [ ] **T2.6 — Baker de impostores** según ADR-014. **Test:** atlas generado, comparación visual a 100 m, coste medido.
- [ ] **T2.7 — Baker de HLOD.** Atlas compartido, sin interiores, sin colisión, sin scripts. **Test:** el HLOD generado no contiene nodos con script ni colisionadores (verificable automáticamente).
- [ ] **T2.8 — 500 árboles visuales.** **Test:** `benchmark_forest` en presupuesto.
- [ ] **T2.9 — Aldea de prueba con oclusión.** **Test:** `benchmark_village` en presupuesto.
- [ ] **T2.10 — Escenas `benchmark_ocean`, `benchmark_forest`, `benchmark_village`, `benchmark_worst_case`.** **Test:** las cuatro producen reporte válido.
- [ ] **T2.11 — Isla desde `official.base.pck`.** Desviación deliberada respecto del roadmap: montar el PCK ya acá evita rehacer la isla en M3. **Test:** la escena de benchmark carga desde el paquete, no desde `res://`.
- [ ] **T2.12 — Gate M2** ⚑. 30 minutos a 120 Hz en Quest 2, o ADR que baje el objetivo. **No se produce contenido masivo sin cerrar esto.**

---

## M3 — Núcleo de mods

Criterio de salida: el juego no conoce ninguna espada, isla ni misión concreta.

- [x] **T3.1 — `semver.gd`.** Rangos `^`, `~`, `x`, comparadores, guion, `||`, filtro de prereleases. **Test:** 94 casos en `tests/unit/test_semver.gd`, verde.
- [x] **T3.2 — `manifest_parser.gd`.** Lee `manifest.json` sin montar contenido, validando contra mod_manifest.schema.json. **Test:** 7 tests — manifiesto válido (sample_mod), JSON inválido, campo requerido faltante, ID sin namespace, type inválido, get_id válido e inválido.
- [x] **T3.3 — `schema_validator.gd`.** Subconjunto de Draft 2020-12 en GDScript: `type`, `required`, `enum`, `const`, `pattern`, `minimum`/`maximum`, `minItems`/`maxItems`, `uniqueItems`, `additionalProperties`, `$defs`/`$ref`, `oneOf`/`anyOf`/`allOf`, `not`, `if/then/else`. **Test:** 33/33 casos dorados en `tests/data/schema_cases.json` (idéntico a Python). Integrado en `benchmarks/runner.gd` reemplazando validación ad-hoc. 227 tests verdes.
- [x] **T3.4 — `dependency_resolver.gd`.** Orden topológico, `load_after`, `conflicts`, opcionales, ciclos, faltantes, sobre semver.gd. **Test:** 9 tests — lineal, diamante, ciclo detectado, dependencia faltante, conflicto, load_after, orden estable alfabetico, lista vacia, version incompatible.
- [x] **T3.5 — `package_reader.gd`.** Abre `.gmod`, valida estructura del contenedor segun docs/24 §2 + lista blanca ADR-012. **Test:** 10 tests — paquete valido, sin manifest, path traversal, segmento oculto, ruta absoluta, duplicado exacto, duplicado case-insensitive, extension .gd rechazada, extension .gdshader rechazada.
- [x] **T3.6 — Verificación de firma.** Payload canónico, SHA-256 por archivo, RSA. **Test:** `test_signature_verifier.gd` — payload canonico ordenado, hash correcto, archivos extra rechazados, archivos faltantes rechazados.
- [x] **T3.7 — `key_store.gd` TOFU.** Ancla `official.*` a la clave oficial. **Test:** NEW → OK, KEY_CHANGED, OFFICIAL_MISMATCH. 13/13 assertions verdes.
- [ ] **T3.8 — `pack_mounter.gd`.** Extrae a `user://mod_cache/`, verifica hash, monta, revierte si falla. **Test:** fallo a mitad de montaje deja el estado anterior intacto.
- [ ] **T3.9 — `registry_base.gd` y las doce registries** de `docs/07`. **Test:** IDs sin namespace rechazados; colisión de IDs reportada; consulta por ID nunca devuelve rutas.
- [ ] **T3.10 — `override_engine.gd`.** `extend`, `patch`, `replace` con advertencia, `disable` con placeholder. **Test:** los cuatro modos sobre una misma definición, más el caso de dos mods que sobrescriben lo mismo.
- [ ] **T3.11 — `mod_error.gd`.** Errores estructurados con mod causante y motivo. **Test:** un mod defectuoso se desactiva y el juego sigue vivo.
- [ ] **T3.12 — Modo seguro.** Contador de arranques fallidos, arranque sólo oficial, UI que nombra el mod, sin borrado automático. **Test:** simular tres fallos consecutivos activa el modo seguro y conserva los archivos del mod.
- [ ] **T3.13 — `official.base` registra la isla de M2.** **Test:** quitar `official.base` deja el juego arrancando en modo seguro, no crasheando.
- [ ] **T3.14 — Tests de integración multi-PCK.** Varios paquetes, overrides encadenados, mod ausente, orden de carga. **Test:** `tests/integration/` verde.
- [ ] **T3.15 — Validador CLI headless.** Reemplaza `tools/ci/check_schemas.py` reusando `schema_validator.gd`. **Test:** CLI y runtime dan el mismo veredicto sobre el mismo corpus; se retira el script Python en el mismo commit.
- [ ] **T3.16 — Gate M3.** `examples/sample_mod` valida, monta y aparece en registries; la isla de benchmark carga desde paquete oficial.

---

## M4 — Player VR

Puede solaparse con M3: no depende del sistema de mods, sólo del arnés de M1.

- [ ] **T4.1 — Origen XR, cápsula, calibración de altura, modo sentado y de pie, mano dominante.** **Test:** unitario de la calibración; verificación en visor ⚑.
- [ ] **T4.2 — Locomoción continua y teleportación.** **Test:** unitario del cálculo de desplazamiento; sesión de comodidad ⚑.
- [ ] **T4.3 — Giro suave, snap turn, viñeta configurable.** **Test:** las opciones persisten entre sesiones.
- [ ] **T4.4 — Escalada por etiqueta `climbable`,** resistencia a baja frecuencia, agarre asistido. **Test:** unitario de la máquina de agarre; sin física por piedra.
- [ ] **T4.5 — Planeador cinemático.** **Test:** descenso y aceleración acotados por los límites declarados.
- [ ] **T4.6 — Barco cinemático** con altura derivada de la función de olas de T2.2. **Test:** la altura del barco coincide con la del shader dentro de una tolerancia.
- [ ] **T4.7 — `settings_service.gd`** persiste todas las opciones de comodidad. **Test:** guardar, reiniciar, verificar.
- [ ] **T4.8 — Batería de comodidad** ⚑ con al menos tres personas. **Test:** todo mareo reproducible se registra como bug de prioridad alta.
- [ ] **T4.9 — Gate M4** ⚑. Recorrido completo de la isla caminando, escalando, planeando y navegando, en presupuesto y sin mareo reproducible.

---

## M5 — Combate

- [ ] **T5.1 — `object_pool.gd`.** **Test:** unitario de reutilización, tope y liberación; sin asignaciones en régimen.
- [ ] **T5.2 — Espada:** pose amortiguada, barrido entre posiciones, cápsula de daño, límite de velocidad efectiva, cooldown por objetivo, háptica. **Test:** agitar el control a alta frecuencia no supera el DPS máximo declarado.
- [ ] **T5.3 — Escudo:** bloqueo por ángulo, parry por ventana. **Test:** unitario de ángulos y ventanas límite.
- [ ] **T5.4 — Arco:** pool de flechas, tope de proyectiles, flechas lejanas dormidas. **Test:** disparar más allá del tope no asigna memoria nueva.
- [ ] **T5.5 — `enemy_system.gd`** con la máquina de estados de `docs/06` a 15–30 Hz. **Test:** unitario de transiciones; la pose visual interpola sin subir la frecuencia de IA.
- [ ] **T5.6 — `combat_system.gd` centralizado.** **Test:** ninguna entidad de combate usa `_process()` propio.
- [ ] **T5.7 — Feedback visual, sonoro y háptico.** **Test:** cada golpe produce las tres respuestas.
- [ ] **T5.8 — `benchmark_combat`** con el peor caso del presupuesto. **Test:** reporte en presupuesto con 5 enemigos y 20 rigid bodies.

---

## M6 — Contenido declarativo

Criterio de salida: Mod API congelada como 1.0.

- [x] **T6.1 — Schemas faltantes.** `item`, `enemy`, `npc`, `biome`, `music`, `translation`, `sector`, `spawn_table`. **Test:** `check_schemas.py` verde con casos positivos y negativos.
- [ ] **T6.2 — Contenido de ejemplo para los ocho schemas nuevos** dentro de `examples/sample_mod`. **Test:** cada archivo valida por convención de nombre.
- [ ] **T6.3 — `ability_system.gd`.** Triggers, condiciones y acciones con whitelist exacta de `docs/09`; validación antes de registrar. **Test:** una acción fuera de la whitelist impide el registro del mod completo, no sólo de esa habilidad.
- [ ] **T6.4 — `quest_system.gd`.** Etapas, objetivos, recompensas, IDs estables. **Test:** avanzar y retroceder etapas; misión con mod ausente.
- [ ] **T6.5 — `dialogue_system.gd`.** Grafo, condiciones, opciones, acciones. **Test:** grafo con nodo inexistente da error estructurado; ciclo no cuelga.
- [ ] **T6.6 — `event_bus.gd`** con los quince eventos públicos. **Test:** cada evento se emite al menos una vez en la suite de integración. **Congela la Mod API 1.0.**
- [ ] **T6.7 — Localización PO.** Claves nunca visibles. **Test:** falta de traducción cae al idioma de respaldo y no muestra la clave cruda.
- [ ] **T6.8 — `sector_streamer.gd`.** Estados de sector, anillos 0/1/2, carga en ocho etapas con presupuesto por cuadro. **Test:** ningún sector pasa de `UNLOADED` a `SIMULATION_ACTIVE` en un cuadro; test unitario de la máquina de estados.
- [ ] **T6.9 — `hlod_manager.gd`.** **Test:** las transiciones entre impostor, HLOD y silueta no producen pop visible por encima del umbral definido.
- [ ] **T6.10 — `world_simulation_system.gd`.** Entidades descargadas reducidas a datos, simulación distante a 1–2 Hz. **Test:** salir y volver a un sector conserva estado sin simular cada paso.
- [ ] **T6.11 — `save_format.gd` por IDs.** Nunca rutas ni índices. **Test:** el archivo de guardado no contiene ninguna ruta `res://`.
- [ ] **T6.12 — `save_migrator.gd`.** Backup, validación, aplicación en copia, reemplazo atómico. **Test:** interrumpir la migración a mitad deja la partida anterior intacta.
- [ ] **T6.13 — Batería de compatibilidad de guardado** de `docs/15`: guardar con mod, quitar, cargar, guardar, reinstalar, verificar. **Test:** los seis pasos automatizados en `tests/integration/`.
- [ ] **T6.14 — Scripts de Blender restantes:** `remove_hidden_faces`, `create_lightmap_uv`, `build_atlas`. **Test:** pipeline completo sobre asset de prueba.
- [ ] **T6.15 — `benchmark_streaming`.** **Test:** reporte con tiempos de carga y sin picos por encima del presupuesto.
- [ ] **T6.16 — Gate M6.** Una isla, un arma, una habilidad, un enemigo, un diálogo y una misión definidos **sólo** en JSON, sin código específico de ese contenido.

---

## M7 — ModKit

- [ ] **T7.1 — `tools/modkit/pack.gd`.** Empaqueta `.gmod` y calcula el payload canónico. **Test:** empaquetar, verificar y montar el `sample_mod` de punta a punta.
- [ ] **T7.2 — Firma con clave de autor.** **Test:** firmar y verificar; alterar un byte y confirmar rechazo.
- [ ] **T7.3 — Clave oficial en CI.** Anclada en el APK, rotación con dos versiones de solapamiento. **Test:** paquete `official.*` firmado con otra clave se rechaza.
- [ ] **T7.4 — Instalador ADB.** **Test:** instalar en visor desde línea de comandos ⚑.
- [ ] **T7.5 — Flujo de instalación en visor** según `docs/19` y `docs/24` §5. **Test:** los once pasos en orden; el rechazo ocurre antes de copiar nada.
- [ ] **T7.6 — Plantillas de mod.** **Test:** una plantilla recién generada valida sin editarla.
- [ ] **T7.7 — Componentes de UI VR reutilizables.** **Test:** tamaño, profundidad y legibilidad verificados en visor ⚑.
- [ ] **T7.8 — Separación en `project-gale-modkit` y `project-gale-api`.** **Test:** el repo principal sigue verde tras la extracción. **Requiere ADR-018.**
- [ ] **T7.9 — Workflow `modkit.yml`.** **Test:** construye y valida los mods de ejemplo en cada PR.
- [ ] **T7.10 — Gate M7.** Una persona externa produce un `.gmod` funcional usando sólo el ModKit y la documentación, sin ayuda.

---

## M8 — Vertical slice

- [ ] **T8.1 — Primera isla completa:** playa, aldea, torre escalable, bosque, campamento, cueva, santuario, miniboss, salto con planeador, trayecto de barco.
- [ ] **T8.2 — Todo el contenido como paquete oficial declarativo.** **Test:** ninguna definición de contenido vive en `core/`.
- [ ] **T8.3 — Guardado y carga en el recorrido completo.** **Test:** batería de seis pasos sobre la partida real.
- [ ] **T8.4 — Reportes de rendimiento de cada zona.** **Test:** las siete escenas de benchmark en presupuesto.
- [ ] **T8.5 — Sesión térmica de 30 minutos sobre el recorrido** ⚑.
- [ ] **T8.6 — Duración 30–45 minutos** medida con jugadores reales ⚑.
- [ ] **T8.7 — Gate M8.** Recorrido completo en Quest 2, en presupuesto, con guardado y sin mareo reproducible.

---

## M9 — Alpha

- [ ] **T9.1 — Tres islas** con sus HLOD e impostores.
- [ ] **T9.2 — Cinco familias de enemigos.**
- [ ] **T9.3 — Dos santuarios.**
- [ ] **T9.4 — Campaña parcial** con misiones encadenadas. **Test:** partida completa automatizable por script de QA.
- [ ] **T9.5 — Traducciones** con catálogo base y al menos un idioma adicional. **Test:** cobertura reportada por el validador.
- [ ] **T9.6 — `THIRD_PARTY.md` completo** con hash de cada asset externo. **Test:** chequeo automático de que cada archivo en `assets/source/` tiene entrada.
- [ ] **T9.7 — Sesión térmica por isla** ⚑.

---

## M10 — 1.0

- [ ] **T10.1 — Seis islas, diez a doce islotes, dos aldeas, cinco santuarios.**
- [ ] **T10.2 — Campaña completa de cuatro a seis horas.**
- [ ] **T10.3 — Documentación de modding publicada.**
- [ ] **T10.4 — APK firmado y reproducible.** **Test:** dos builds independientes con el mismo hash de contenido.
- [ ] **T10.5 — Release con versiones de juego, Mod API, formato `.gmod`, Godot y hash de export templates.**
- [ ] **T10.6 — Batería completa verde** en las cuatro plataformas soportadas ⚑.
- [ ] **T10.7 — Gate 1.0.** Todos los gates anteriores cerrados y ninguna tarea `[!]` sin ADR.

---

## Tareas transversales permanentes

No pertenecen a un hito; se revisan en cada PR.

- [ ] Ninguna definición de contenido concreto dentro de `core/`.
- [ ] Todos los IDs namespaced.
- [ ] Ningún shader fuera de las familias autorizadas.
- [ ] Presupuestos de `docs/03` respetados o modificados con evidencia.
- [ ] `THIRD_PARTY.md` al día.
- [ ] `FILE_INDEX.json` regenerado.
- [ ] Checklist actualizado en el mismo commit que el cambio.
