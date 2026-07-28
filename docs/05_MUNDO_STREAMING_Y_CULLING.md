# Mundo, streaming y culling

## Estructura

El mundo es un archipiélago. Cada isla es una unidad de contenido y streaming. Las islas grandes se dividen en sectores de 64 × 64 metros como valor inicial.

```text
World
├── Ocean
├── IslandRegistry
├── HLODManager
├── SectorStreamer
├── EntitySimulation
└── TravelGraph
```

## Estados de sector

- `UNLOADED`
- `LOADING_METADATA`
- `VISUAL_FAR`
- `VISUAL_NEAR`
- `COLLISION_READY`
- `SIMULATION_ACTIVE`
- `UNLOADING`

Ningún sector pasa de descargado a simulación completa en un solo cuadro.

## Anillos

### Anillo 0

Sector del jugador: máxima representación, interacción, física e IA.

### Anillo 1

Sectores vecinos: visual cercano, colisión selectiva y entidades preparadas.

### Anillo 2

HLOD, impostores y estado lógico.

### Resto

Islas como HLOD lejano o totalmente descargadas.

## Culling

- Frustum culling automático para geometría fuera de cámara.
- Culling por distancia para detalles.
- Occlusion culling en pueblos, cuevas, santuarios y calles.
- No usar oclusión indiscriminada en mar o llanuras.
- Diseño de niveles con curvas, desniveles, paredes y vegetación que corten líneas de visión.

## Streaming asíncrono

Cada carga se divide:

1. metadata;
2. HLOD;
3. terreno;
4. MultiMesh;
5. colisiones;
6. objetos interactivos;
7. navegación;
8. NPC y enemigos.

La activación se distribuye entre cuadros con presupuesto medido.

## Interiores

Santuarios y cuevas importantes son escenas separadas. Al ingresar se permite una transición breve que descarga contenido exterior pesado.

## Estado persistente

Las entidades descargadas se reducen a datos:

```json
{
  "id": "official:goblin_12",
  "region": "official:island_start",
  "sector": "04_07",
  "position": [12.0, 4.0, -8.0],
  "health": 40,
  "state": "PATROL",
  "last_update": 183492
}
```

No se simula cada paso fuera del área activa.
