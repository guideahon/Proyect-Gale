# Testing y QA

## Capas

### Unitarias

- resolución de dependencias;
- registries;
- migraciones;
- quests;
- habilidades;
- serialization;
- validadores.

### Integración

- carga de varios PCK;
- overrides;
- partida con mod ausente;
- streaming de isla;
- cambio de perfil gráfico;
- exportación APK.

### Rendimiento

Escenas fijas:

- `benchmark_empty`;
- `benchmark_ocean`;
- `benchmark_forest`;
- `benchmark_village`;
- `benchmark_combat`;
- `benchmark_streaming`;
- `benchmark_worst_case`.

## Hardware

- Quest 1.
- Quest 2.
- Quest 3 o superior cuando esté disponible.
- PCVR de referencia.

## Sesión térmica

Cada milestone ejecuta 30 minutos continuos con:

- recorrido repetible;
- combate;
- streaming;
- guardado;
- giro frecuente;
- bosque con transparencias recortadas.

## Métricas

- CPU frame time;
- GPU frame time;
- P50/P95/P99;
- dropped frames;
- memoria;
- temperatura/clock cuando el runtime lo exponga;
- draw calls;
- triángulos;
- cantidad de objetos;
- tiempos de carga.

## Mods

El validador prueba:

- esquema JSON;
- IDs;
- dependencias;
- licencia;
- rutas;
- presupuesto;
- shaders;
- scripts;
- LOD;
- HLOD;
- impostores;
- compatibilidad de API.

## Compatibilidad de guardado

Tests obligatorios:

1. guardar con mod;
2. quitar mod;
3. cargar sin mod;
4. guardar otra vez;
5. reinstalar mod;
6. verificar restauración.

## Criterio de bug

Todo mareo reproducible, frame drop sostenido, pérdida de save o crash del loader de mods es de prioridad alta.
