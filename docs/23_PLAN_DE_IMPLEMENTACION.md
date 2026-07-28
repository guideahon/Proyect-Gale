# Plan de implementación

**Estado:** propuesta inicial
**Fecha:** 2026-07-28
**Base:** `docs/00`–`docs/22`, `VERSION_BASELINE.md`, `schemas/`, `examples/sample_mod/`

Este documento traduce la especificación existente en trabajo ejecutable: estructura de repositorio, orden de construcción, entregables por hito, criterios de salida verificables y riesgos que deben resolverse antes de escribir código de producción.

Documentos hermanos: `docs/25_CHECKLIST_DE_EJECUCION.md` desglosa cada hito en tareas marcables con su verificación, y `AGENTS.md` fija cómo se trabaja. Este documento explica el porqué; el checklist es la lista de trabajo diaria.

---

## 0. Estado del proyecto

Lo que ya existe:

- documentación de producto, técnica y de gobernanza completa;
- quince JSON Schemas: `mod_manifest`, `weapon`, `ability`, `dialogue`, `quest`, `island`, `item`, `enemy`, `npc`, `biome`, `music`, `translation`, `sector`, `spawn_table`, `signature`;
- especificación de firma y empaquetado (`docs/24`, cierra ADR-015);
- un mod de ejemplo declarativo;
- tres plantillas (ADR, asset manifest, performance report);
- índice de archivos con hashes;
- `core/mods/semver.gd` con su batería de tests, primera pieza de la ruta crítica de mods;
- `project.godot` mínimo, sólo para importar y ejecutar tests headless.

Lo que no existe:

- configuración real del proyecto Godot: renderer, OpenXR, presets de exportación;
- runtime: autoloads, registries, streaming, sistemas;
- CI;
- herramientas de asset y ModKit;
- assets;
- licencias como archivos.

Consecuencia: la Fase 0 del roadmap todavía no comenzó. El trabajo hecho hasta ahora es especificación ejecutable, no producto.

---

## 1. Principios de ejecución

1. **Nada se declara terminado sin medición en hardware real.** Regla ya fijada en `docs/03`; este plan la convierte en gate de merge.
2. **El arnés de medición se construye antes que el contenido que debe medir.** No se puede aprobar la Fase 1 sin instrumentación.
3. **La API de mods se construye antes del contenido oficial, no después.** El contenido oficial es su primer consumidor (ADR-004).
4. **Los spikes bloqueantes se resuelven antes de invertir en producción.** Ver sección 3.
5. **Cada decisión abierta se cierra con un ADR numerado**, continuando desde ADR-011.
6. **Vertical antes que horizontal.** Una isla completa y certificada antes de seis islas incompletas.

---

## 2. Estructura de repositorio a crear

Concreta la estructura de `docs/16`.

```text
project-gale/
├── project.godot
├── .gitattributes                # reglas Git LFS
├── .gitignore                    # .godot/, exports/, *.apk, *.keystore
├── .editorconfig
├── LICENSE                       # índice de licencias
├── LICENSE-CODE                  # MIT
├── LICENSE-ASSETS
├── LICENSE-DOCS                  # CC BY 4.0
├── THIRD_PARTY.md
├── CREDITS.md
├── VERSION_BASELINE.md
├── addons/
│   ├── godot_openxr_vendors/     # pin por tag
│   └── godot-xr-tools/           # pin por commit, subset importado
├── game/
│   ├── autoload/
│   │   ├── bootstrap.gd
│   │   ├── mod_manager.gd
│   │   ├── game_registries.gd
│   │   ├── settings_service.gd
│   │   ├── save_service.gd
│   │   ├── performance_service.gd
│   │   └── event_bus.gd
│   ├── scenes/
│   │   ├── main.tscn
│   │   ├── safe_mode.tscn
│   │   ├── loading.tscn
│   │   └── mod_manager_ui.tscn
│   └── ui/
├── core/
│   ├── mods/
│   │   ├── semver.gd
│   │   ├── manifest_parser.gd
│   │   ├── dependency_resolver.gd
│   │   ├── pack_mounter.gd
│   │   ├── content_scanner.gd
│   │   ├── schema_validator.gd
│   │   ├── override_engine.gd
│   │   └── mod_error.gd
│   ├── registries/
│   │   ├── registry_base.gd
│   │   └── {asset,item,weapon,ability,enemy,npc,dialogue,quest,map,biome,music,translation}_registry.gd
│   ├── content/                  # Resource classes tipadas por schema
│   ├── systems/
│   │   ├── player_system.gd
│   │   ├── interaction_system.gd
│   │   ├── combat_system.gd
│   │   ├── enemy_system.gd
│   │   ├── projectile_system.gd
│   │   ├── ability_system.gd
│   │   ├── quest_system.gd
│   │   ├── dialogue_system.gd
│   │   └── world_simulation_system.gd
│   ├── world/
│   │   ├── island_registry.gd
│   │   ├── sector_streamer.gd
│   │   ├── hlod_manager.gd
│   │   ├── travel_graph.gd
│   │   └── ocean.gd
│   ├── save/
│   │   ├── save_format.gd
│   │   ├── save_migrator.gd
│   │   └── atomic_writer.gd
│   ├── perf/
│   │   ├── frame_probe.gd
│   │   ├── profile_manager.gd
│   │   ├── dynamic_resolution.gd
│   │   └── thermal_logger.gd
│   ├── pool/
│   │   └── object_pool.gd
│   └── shaders/
│       ├── toon_opaque.gdshader
│       ├── toon_cutout.gdshader
│       ├── toon_character.gdshader
│       ├── toon_water.gdshader
│       ├── toon_unlit.gdshader
│       ├── toon_impostor.gdshader
│       └── particle_simple.gdshader
├── official_mods/
│   ├── official.base/
│   └── official.campaign/
├── schemas/                      # ya existe, se amplía
├── tools/
│   ├── blender/                  # scripts de docs/11
│   ├── validator/                # CLI de validación de mods
│   ├── impostor_baker/           # plugin de editor
│   ├── hlod_baker/               # plugin de editor
│   ├── modkit/                   # plantillas + exporter + instalador ADB
│   └── ci/
├── tests/
│   ├── unit/
│   └── integration/
├── benchmarks/
│   ├── benchmark_empty.tscn
│   ├── benchmark_ocean.tscn
│   ├── benchmark_forest.tscn
│   ├── benchmark_village.tscn
│   ├── benchmark_combat.tscn
│   ├── benchmark_streaming.tscn
│   ├── benchmark_worst_case.tscn
│   └── runner.gd
├── docs/
├── licenses/
└── .github/workflows/
    ├── pr.yml
    ├── release.yml
    └── modkit.yml
```

Los repos satélite (`project-gale-modkit`, `-api`, `-example-mods`, `-community-content`) se crean recién en M7. Antes son directorios dentro del repo principal para evitar sincronización prematura.

---

## 3. Fase −1 — Spikes bloqueantes

Trabajo de investigación acotado, con resultado escrito, **antes** de comprometer arquitectura. Cada spike se cierra con ADR o con nota en `docs/20`.

| # | Spike | Pregunta que responde | Salida | Bloquea |
|---|---|---|---|---|
| S1 | Toolchain Godot | ~~¿Existe y es estable 4.7.1?~~ **Sí**: build `a13da4feb`, importa y ejecuta headless en Windows. Pendiente: export templates y su hash, release del vendor plugin y commit de XR Tools que compilen juntos, y build Android real | `VERSION_BASELINE.md` con versiones exactas + lockfile | Todo |
| S2 | Renderer | Compatibility vs Mobile en Quest 2 con la misma escena | ADR-011 que cierra ADR-007 | M1, M2 |
| S3 | 120 Hz real | ¿El runtime concede 120 Hz? ¿Bajo qué condiciones lo revoca? ¿Cómo se solicita el display refresh rate? | Nota técnica + código de `profile_manager.gd` | M1 |
| S4 | Foveation + resolución dinámica | ¿Qué combinación de foveation fijo, MSAA 2× y render scale entra en presupuesto? | Tabla de perfiles medida | M1 |
| S5 | Carga de PCK en Android | Montar PCK desde `user://` en Quest, con y sin reinicio; comportamiento de `res://` overrides | Nota técnica + `pack_mounter.gd` | M3 |
| S6 | Sandbox declarativo | ¿Se puede garantizar que un PCK no contenga `.gd` / `.gdshader` ejecutable? ¿Qué se ejecuta al montar? | ADR-012 sobre alcance real del modo estricto | M3, M7 |
| S7 | Impostores | ¿Baker propio en Blender o plugin de editor Godot? Coste de atlas 8 vs 16 vistas | Decisión de herramienta | M2 |
| S8 | Quest 1 | ¿Sigue siendo alcanzable el sideload y el runtime OpenXR requerido? | Confirmar o degradar objetivo | M1 |

**S6 es el más importante.** Todo el modelo de seguridad de `docs/19` asume que un mod declarativo no ejecuta código. Un PCK de Godot puede contener scripts y recursos con propiedades peligrosas; si no se puede garantizar por construcción, el validador debe rechazar por lista blanca de extensiones y de tipos de recurso, y eso cambia el diseño del empaquetador del ModKit.

Duración estimada: 2–4 semanas de una persona con hardware disponible.

---

## 4. Hitos

Los hitos M0–M10 corresponden a las fases 0–10 de `docs/14`, con entregables y criterios explícitos. Se indica desviación respecto del roadmap donde el plan propone adelantar trabajo.

### M0 — Fundación

**Objetivo:** build reproducible y vacío que arranca en Quest.

Tareas:

1. `git init`, `.gitattributes` con LFS para `*.glb *.blend *.wav *.ogg *.png *.psd *.apk`, y **no** para `*.json *.gd *.md *.gdshader`.
2. Archivos de licencia según `docs/17`: `LICENSE-CODE` (MIT), `LICENSE-DOCS` (CC BY 4.0), `LICENSE-ASSETS`, `THIRD_PARTY.md`, `CREDITS.md`.
3. `project.godot` con renderer del S2, Android export preset, ARM64, OpenXR habilitado.
4. Addons fijados por tag/commit + lockfile `addons/LOCKFILE.md`.
5. `bootstrap.gd` mínimo: inicializa XR, entra a `main.tscn`, sale con error legible si OpenXR falla.
6. CI `pr.yml`: import headless, comprobación de recursos faltantes, lint de GDScript, validación de `schemas/` con los ejemplos.
7. CI `release.yml`: export APK ARM64, firma, SHA-256, release con checksums.
8. `CONTRIBUTING.md` derivado de `docs/18` + plantilla de PR con la tabla de rendimiento de `docs/03`.

**Criterio de salida:** dos máquinas distintas producen APK con el mismo hash de contenido; el APK arranca en Quest y muestra una escena vacía en VR sin errores en el log.

**Riesgo:** firma de APK en CI requiere keystore como secreto. No exponer el keystore en el repositorio ni en logs.

---

### M1 — Laboratorio de rendimiento

**Objetivo:** baseline sostenido y medible antes de cualquier contenido.

Tareas:

1. `frame_probe.gd`: CPU/GPU frame time, P50/P95/P99, dropped frames, draw calls, triángulos, memoria de texturas, tiempos de carga.
2. `profile_manager.gd`: perfiles `quest1_72`, `quest2_120_strict`, `quest2_90`, `quest3_120`, `pcvr`. Cada perfil fija render scale, MSAA, foveation, distancias LOD, límites de entidades y frecuencias de simulación.
3. `dynamic_resolution.gd` con histéresis; nunca oscilar por cuadro.
4. `thermal_logger.gd`: registro cada N segundos, exporta a `user://logs/`.
5. `benchmarks/runner.gd`: ejecuta una escena, recorre un camino repetible, escribe `performance_report.json` con el formato de `templates/performance_report.example.json`.
6. `benchmark_empty.tscn` y sesión térmica de 30 minutos.
7. Escena de calibración con cubos que escala carga de draw calls y triángulos hasta encontrar el punto de ruptura real del dispositivo.

**Criterio de salida:** `benchmark_empty` sostiene el perfil estricto 30 minutos con P99 ≤ 8,0 ms, y el reporte se genera automáticamente. Punto de ruptura del dispositivo documentado y comparado con la tabla de `docs/03`.

**Salida secundaria crítica:** si el punto de ruptura medido contradice los presupuestos de `docs/03`, se actualiza `docs/03` con evidencia antes de continuar. Presupuestos con evidencia, no aspiracionales.

---

### M2 — Benchmark visual

**Objetivo:** demostrar que la estética objetivo entra en presupuesto.

Tareas:

1. Familia de shaders toon completa (`docs/04`), con variantes por perfil y sin ramas dinámicas costosas.
2. `ocean.gd`: malla en anillos centrada en jugador, olas analíticas; la **misma función** expuesta a GDScript para altura de barco (`docs/06`).
3. Isla de prueba 200 × 200 m con sectores de 64 m.
4. Pipeline mínimo de assets (`tools/blender/`): `normalize_scale`, `merge_materials`, `palette_remap`, `generate_lods`, `generate_colliders`, `export_glb`. Los demás scripts en M6.
5. MultiMesh por sector y por nivel de LOD, nunca por isla.
6. Baker de impostores según S7; atlas 8 vistas, albedo + alpha scissor + luz horneada.
7. Baker de HLOD: fusión, atlas compartido, sin colisión, sin scripts.
8. 500 árboles visuales, aldea de prueba.
9. `benchmark_ocean`, `benchmark_forest`, `benchmark_village`, `benchmark_worst_case`.

**Criterio de salida (gate duro de `docs/14`):** 120 Hz sostenido 30 minutos en Quest 2 con `benchmark_village`, o decisión formal y documentada de reducir alcance (bajar a 90 Hz como objetivo principal, reducir densidad, o reducir distancia visual). No se produce contenido masivo sin cerrar este gate.

**Desviación propuesta respecto del roadmap:** montar aquí ya un PCK trivial y cargar la isla benchmark desde `official.base.pck`, aunque el ModManager completo llegue en M3. Evita reconstruir la isla como contenido embebido y luego migrarla.

---

### M3 — Núcleo de mods

**Objetivo:** el juego no conoce ninguna espada, isla ni misión; sólo capacidades.

Tareas:

1. ~~`semver.gd`: parseo y comparación de rangos (`^1.0`, `>=0.1.0 <1.0.0`). No hay librería; se implementa y se testea primero.~~ **Hecho.** Falta ejecutar `tests/unit/test_semver.gd` en Godot real; la lógica está verificada, la sintaxis GDScript no.
2. `manifest_parser.gd` + `schema_validator.gd`: validación estricta contra `schemas/`, Draft 2020-12, `additionalProperties: false`.
3. `dependency_resolver.gd`: grafo, orden topológico, `load_after`, `conflicts`, dependencias opcionales, detección de ciclos, error estructurado sin crash.
4. `pack_mounter.gd`: extraer `content.pck` de `.gmod` a `user://mod_cache/`, verificar hash, montar, revertir en caso de fallo.
5. `registry_base.gd` y las doce registries de `docs/07`. IDs namespaced obligatorios; nunca rutas.
6. `override_engine.gd`: `extend`, `patch`, `replace` (con advertencia), `disable` (con placeholder persistente).
7. Modo seguro: contador de arranques fallidos, arranque sólo con contenido oficial, UI que nombra el mod causante, desactivación sin borrado.
8. `mod_error.gd`: errores estructurados; un mod defectuoso se desactiva, no cierra el juego.
9. `official.base` como mod real que registra la isla benchmark.
10. Tests unitarios: resolver, semver, registries, overrides, validador.
11. Tests de integración: varios PCK, overrides encadenados, mod ausente, orden de carga.

**Criterio de salida:** la isla de M2 carga desde `official.base.pck`; el mod de ejemplo `examples/sample_mod` valida, monta y aparece en registries; quitar el mod no rompe el arranque.

---

### M4 — Player VR

Tareas:

1. Origen XR, cápsula de cuerpo, calibración de altura, modo sentado y de pie, mano dominante.
2. Locomoción continua, teleportación, giro suave, snap turn, viñeta configurable, control de velocidad.
3. Escalada por etiqueta `climbable`, agarre por manos, resistencia a baja frecuencia, agarre asistido.
4. Planeador cinemático, dirección por pose, sin aerodinámica.
5. Barco cinemático con altura derivada de la función de olas de M2; colisión simple.
6. `settings_service.gd` con persistencia de todas las opciones de comodidad.
7. Batería de comodidad: sesiones con al menos tres personas distintas, registro de mareo reproducible como bug de prioridad alta.

**Criterio de salida:** recorrido de la isla benchmark caminando, escalando, planeando y navegando, sin salir de presupuesto y sin mareo reproducible.

---

### M5 — Combate

Tareas:

1. `object_pool.gd` genérico; pools obligatorios de flechas, efectos, impactos, pickups, audio one-shot.
2. Espada: pose amortiguada, barrido entre posición previa y actual, cápsula de daño, límite de velocidad efectiva, cooldown por objetivo, háptica proporcional.
3. Escudo: bloqueo por ángulo, parry por ventana temporal y velocidad, respuesta visual/sonora/háptica.
4. Arco: pool de flechas, máximo de proyectiles activos, física simplificada, flechas lejanas dormidas, ajustes de accesibilidad.
5. `enemy_system.gd`: máquina de estados `SLEEP/IDLE/PATROL/ALERT/CHASE/ATTACK/STUN/RETURN/DEAD`, IA a 15–30 Hz, pose interpolada a frecuencia de pantalla.
6. `combat_system.gd` centralizado; no un `_process()` por entidad.
7. `benchmark_combat` con el peor caso del presupuesto (5 enemigos, 20 rigid bodies).

**Criterio de salida:** `benchmark_combat` en presupuesto; agitar el control no produce daño infinito.

---

### M6 — Contenido declarativo

**Objetivo:** cerrar la API de mods 1.0.

Tareas:

1. ~~Completar `schemas/`: faltan `enemy`, `npc`, `item`, `biome`, `music`, `translation`, `sector`, `spawn_table`.~~ **Hecho.** Los ocho existen y validan contra Draft 2020-12. Queda escribir el contenido de ejemplo para cada uno y ampliar `examples/sample_mod/` para ejercitarlos.
2. `ability_system.gd`: motor de triggers/condiciones/acciones con **whitelist** exacta de `docs/09`; validación de cada acción antes de registrar.
3. `quest_system.gd`: etapas, objetivos, recompensas, eventos, IDs estables entre versiones.
4. `dialogue_system.gd`: grafo de nodos, condiciones, opciones, acciones, texto localizado por clave.
5. `event_bus.gd` con los quince eventos públicos de `docs/09`; contrato congelado al cerrar Mod API 1.0.
6. Localización PO, claves nunca visibles como texto.
7. `sector_streamer.gd` y `hlod_manager.gd` completos: estados de sector, anillos 0/1/2, carga en ocho etapas con presupuesto por cuadro.
8. `world_simulation_system.gd`: entidades descargadas reducidas a datos, simulación distante a 1–2 Hz.
9. `save_format.gd` por IDs, nunca rutas ni índices; `save_migrator.gd` con backup, validación, aplicación en copia y reemplazo atómico.
10. Batería obligatoria de compatibilidad de guardado de `docs/15` (guardar con mod → quitar → cargar → guardar → reinstalar → verificar).
11. Scripts de Blender restantes: `remove_hidden_faces`, `create_lightmap_uv`, `build_atlas`.
12. `benchmark_streaming`.

**Criterio de salida:** una isla, un arma, una habilidad, un enemigo, un diálogo y una misión completos, definidos exclusivamente en JSON, sin una línea de código específica de ese contenido. Mod API congelada como 1.0 y versionada aparte del juego.

---

### M7 — ModKit

Tareas:

1. CLI validador (`tools/validator/`) que reproduce exactamente las reglas del juego: schema, IDs, dependencias, licencia, rutas, presupuesto, shaders, scripts, LOD, HLOD, impostores, compatibilidad de API. Una sola fuente de reglas compartida con el runtime; divergencia entre CLI y juego es bug de prioridad alta.
2. Exporter `.gmod`: manifest + content.pck + icon + README + LICENSE + CHANGELOG + signature.
3. Definir `signature.json` (algoritmo, formato de clave, qué cubre el hash) — pendiente en `docs/19`, requiere ADR.
4. Instalador ADB y flujo de instalación en visor según `docs/19` (leer manifest sin montar → tamaño → paths → hash → permisos → copiar → activar al reiniciar).
5. Plantillas de mod y componentes de UI VR reutilizables (`docs/09`).
6. Extracción a `project-gale-modkit` y `project-gale-api` como repos propios.
7. Workflow `modkit.yml`: construir y validar mods de ejemplo en cada PR.

**Criterio de salida:** una persona externa, con sólo el ModKit y la documentación, produce un `.gmod` que instala y funciona sin asistencia.

---

### M8 — Vertical slice

Isla completa de `docs/13`: playa, aldea, torre escalable, bosque, campamento, cueva, santuario, miniboss, salto con planeador, trayecto de barco. 30–45 minutos.

**Criterio de salida:** recorrido completo en Quest 2, dentro de presupuesto, con guardado, sesión térmica de 30 minutos aprobada, y todo el contenido entregado como paquete oficial declarativo.

---

### M9 — Alpha

Tres islas, cinco familias de enemigos, dos santuarios, campaña parcial, traducciones, catálogo de assets procesados y registrados en `THIRD_PARTY.md` con hash.

---

### M10 — 1.0

Seis islas, diez a doce islotes, dos aldeas, cinco santuarios, campaña de cuatro a seis horas, documentación de modding publicada, APK firmado, release reproducible con versiones de juego, Mod API, formato `.gmod`, Godot y hash de export templates.

---

## 5. Ruta crítica y paralelización

Ruta crítica (secuencial, no comprimible):

```text
S1/S2/S3 → M0 → M1 → M2 (gate) → M3 → M6 → M8 → M10
```

Trabajo paralelizable desde temprano:

| Corriente | Puede empezar en | Independiente de |
|---|---|---|
| Pipeline de assets y Blender scripts | M0 | Runtime |
| Shaders toon | M0 (prototipo en desktop) | Mods |
| Schemas faltantes y validador CLI | M0 | Runtime |
| Diseño de niveles en papel y bloqueo gris | M1 | Todo lo demás |
| Locomoción VR (M4) | tras M1 | M2, M3 |
| Combate (M5) | tras M4 | M3 |
| Documentación de modding | tras M6 | M8 |

M4 y M5 pueden solaparse con M3 si hay dos personas: el player VR no depende del sistema de mods, sólo del arnés de rendimiento.

---

## 6. Riesgos

| # | Riesgo | Impacto | Mitigación |
|---|---|---|---|
| R1 | 120 Hz en Quest 2 no es alcanzable con la densidad visual deseada | Alto | Gate M2 con decisión formal; perfil 90 Hz ya previsto como alternativa; ADR-010 ya evita prometerlo |
| R2 | El modo declarativo no es realmente sandbox | Alto | Spike S6 antes de M3; validador por lista blanca de extensiones y tipos de recurso; advertencia explícita si la garantía es parcial |
| R3 | Godot 4.7.1 / vendor plugin / XR Tools no compatibles entre sí | Alto | Spike S1; lockfile; migración de motor sólo por rama + ADR (`docs/02`) |
| R4 | Impostores y HLOD requieren herramientas propias inexistentes | Medio | S7 temprano; presupuestar M2 con margen; degradar a billboard Y si el baker se atrasa |
| R5 | Quest 1 no llega a presupuesto | Medio | Ya declarado como "cuando sea técnicamente viable"; degradar a objetivo secundario tras M1 |
| R6 | Divergencia entre validador CLI y runtime | Medio | Una sola implementación de reglas, consumida por ambos; test que ejecuta ambos sobre el mismo corpus |
| R7 | Alcance de 1.0 excede la capacidad del equipo | Alto | Gates de `docs/14` ya prohíben producción masiva anticipada; M8 define el corte mínimo publicable |
| R8 | Assets CC0 reprocesados no logran coherencia estética | Medio | `palette_remap` y revisión artística obligatoria en M2, no en M9 |
| R9 | Migraciones de save corrompen partidas | Alto | Backup + copia + validación + reemplazo atómico ya especificados; batería de seis pasos como test de CI |

---

## 7. Decisiones pendientes

Requieren ADR antes de los hitos indicados.

| ADR | Tema | Necesario antes de |
|---|---|---|
| ADR-011 | Renderer definitivo (cierra ADR-007) | M1 |
| ADR-012 | Alcance real de la garantía del modo declarativo | M3 |
| ADR-013 | Framework de tests (gdUnit4 recomendado por soporte headless en CI) | M0 |
| ADR-014 | Herramienta de impostores: Blender vs plugin de editor | M2 |
| ~~ADR-015~~ | ~~Especificación de `signature.json`~~ — **cerrada**, ver `docs/24` | — |
| ADR-016 | Formato binario o texto de partidas guardadas y política de compresión | M6 |
| ADR-017 | Estrategia de lightmaps vs vertex colors por tipo de asset | M2 |
| ADR-018 | Momento y criterio de división en repos satélite | M7 |
| ADR-019 | Licencia final del arte original (CC BY 4.0 o CC0) | M8 |

---

## 8. Definición de terminado

Una tarea está terminada cuando:

1. el código pasa lint y tests;
2. la funcionalidad tiene test unitario o de integración;
3. si es visual o de simulación, adjunta reporte de rendimiento con variación respecto de `main`;
4. si toca la Mod API, actualiza schema, documentación y mod de ejemplo;
5. si toca guardado, pasa la batería de seis pasos;
6. si toca contenido, se expresa mediante la API pública y no mediante privilegios del núcleo;
7. no introduce shaders fuera de las familias autorizadas;
8. queda registrada en el CHANGELOG.

Una función que cumple visualmente pero rompe el presupuesto no está terminada.

---

## 9. Primeros diez pasos concretos

1. Ejecutar S1 y fijar versiones exactas en `VERSION_BASELINE.md`.
2. `git init`, `.gitattributes`, `.gitignore`, archivos de licencia.
3. Crear `project.godot` y el árbol de la sección 2 con archivos vacíos.
4. Configurar export preset Android ARM64 y producir el primer APK.
5. Escribir `pr.yml` con import headless y validación de schemas.
6. Implementar `frame_probe.gd` y `benchmarks/runner.gd`.
7. Ejecutar `benchmark_empty` en Quest 2 y publicar el primer `performance_report.json`.
8. Ejecutar S2 y S3, escribir ADR-011.
9. ~~Implementar `semver.gd` con tests; es la pieza más pequeña de la ruta crítica de mods.~~ **Hecho**, pendiente de ejecución en Godot.
10. Escribir el validador CLI sobre los schemas existentes y hacerlo pasar contra `examples/sample_mod`.
