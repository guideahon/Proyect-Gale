## official.base — registra el contenido oficial base (isla de benchmark).
##
## Vive en `official_mods/`, no en `core/`: la regla de oro de `docs/00` y
## `docs/08` §92 dicen que el núcleo implementa capacidad y los paquetes
## registran contenido — «no se permite hardcodear directamente una espada,
## misión o isla dentro del núcleo». Esto es contenido, así que es un paquete
## oficial y usa las mismas APIs públicas que un mod comunitario (ADR-004).
##
## Sin `official.base` el juego arranca en modo seguro; no crashea.
extends RefCounted

## IDs de contenido: `namespace:nombre`, con dos puntos. El ID del paquete es
## `official.base`, con punto, y vive en su `manifest.json`.
const ISLAND_ID := "official:base_island"


## Registra el contenido del paquete en la registry que se le pase.
## Devuelve el estado de `RegistryBase.register`.
static func register(registry: Object) -> int:
	return registry.register(ISLAND_ID, {
		"type": "map",
		"name": "Base Island",
		"version": "0.1.0",
		"required": true,
	})
