## RegistryBase — base para las 12 registries de docs/07.
## Los sistemas consultan IDs namespaced, no rutas.
extends RefCounted

## Estado de verificación de un registro.
enum VerifyState {
	OK,
	MISSING_ID,
	DUPLICATE_ID,
	INVALID_NAMESPACE,
}

var _items: Dictionary = {}
var _registry_name: String = ""

func _init(name: String) -> void:
	_registry_name = name

## Registrar un item con ID namespaced: `namespace:nombre`, por ejemplo
## `official:sword_basic` o `autor.mod:contenido` (docs/08). El separador es
## dos puntos, igual que el patrón `^[a-z0-9_.-]+:[a-z0-9_.-]+$` que exigen
## todos los schemas; el namespace admite puntos, el nombre también.
## Devuelve OK o un error estructurado.
func register(id: String, data: Dictionary) -> int:
	if id.is_empty():
		return VerifyState.MISSING_ID
	if not is_valid_id(id):
		return VerifyState.INVALID_NAMESPACE
	if _items.has(id):
		push_warning("%s: ID duplicado '%s'" % [_registry_name, id])
		return VerifyState.DUPLICATE_ID
	_items[id] = data
	return VerifyState.OK


## Valida `namespace:nombre` con el mismo juego de caracteres que los schemas.
static func is_valid_id(id: String) -> bool:
	var parts: PackedStringArray = id.split(":", true)
	if parts.size() != 2:
		return false
	for part: String in parts:
		if part.is_empty():
			return false
		for c: String in part:
			var ok := (c >= "a" and c <= "z") or (c >= "0" and c <= "9") \
				or c == "_" or c == "." or c == "-"
			if not ok:
				return false
	return true

## Consultar por ID. Nunca devuelve rutas.
func lookup(id: String) -> Variant:
	if not _items.has(id):
		return null
	return _items[id]

## Listar todos los IDs.
func get_all_ids() -> PackedStringArray:
	var ids: PackedStringArray = []
	for id: String in _items:
		ids.append(id)
	return ids

## Cantidad de items registrados.
func size() -> int:
	return _items.size()

## Verificar integridad: todos los IDs son `namespace:nombre` válidos.
func verify() -> int:
	for id: String in _items:
		if not is_valid_id(id):
			return VerifyState.INVALID_NAMESPACE
	return VerifyState.OK
