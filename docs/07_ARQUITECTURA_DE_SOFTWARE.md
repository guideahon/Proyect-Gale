# Arquitectura de software

## Capas

```text
GameRoot
├── XRRuntime
├── PerformanceManager
├── ModManager
├── Registries
├── WorldStreamer
├── EntitySimulation
├── SaveManager
├── AudioManager
├── UIManager
└── Player
```

## Autoloads mínimos

- `Bootstrap`
- `ModManager`
- `GameRegistries`
- `SettingsService`
- `SaveService`
- `PerformanceService`
- `EventBus`

No convertir cada función en un singleton.

## Sistemas centralizados

- `PlayerSystem`
- `InteractionSystem`
- `CombatSystem`
- `EnemySystem`
- `ProjectileSystem`
- `AbilitySystem`
- `QuestSystem`
- `DialogueSystem`
- `WorldSimulationSystem`

Evitar miles de nodos con `_process()`.

## Registries

- `AssetRegistry`
- `ItemRegistry`
- `WeaponRegistry`
- `AbilityRegistry`
- `EnemyRegistry`
- `NPCRegistry`
- `DialogueRegistry`
- `QuestRegistry`
- `MapRegistry`
- `BiomeRegistry`
- `MusicRegistry`
- `TranslationRegistry`

Los sistemas consultan IDs namespaced, no rutas.

## Frecuencias

| Sistema | Frecuencia |
|---|---:|
| Cabeza y manos | frecuencia XR |
| Física del jugador | frecuencia XR |
| Física secundaria | 60 o 120 según perfil |
| IA combate | 15–30 Hz |
| Patrulla | 5–10 Hz |
| Animación lejana | 10–15 Hz |
| Simulación distante | 1–2 Hz |

## Pools

Pools obligatorios para:

- flechas;
- efectos;
- impactos;
- pickups;
- enemigos comunes cuando sea útil;
- audio one-shot frecuente.

## GDExtension

Sólo migrar a C++ después de profiling. Candidatos:

- streaming masivo;
- actualización de MultiMesh;
- simulación distante;
- validación binaria de mods;
- descompresión;
- navegación personalizada.

## Manejo de errores

Los subsistemas devuelven errores estructurados. Un mod defectuoso no debe cerrar el juego; se desactiva, registra el motivo y se ofrece un modo seguro.
