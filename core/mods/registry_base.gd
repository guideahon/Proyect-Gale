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

## Registrar un item con ID namespaced (ej. "official.sword_iron").
## Devuelve OK o un error estructurado.
func register(id: String, data: Dictionary) -> int:
	# Validar namespace
	if not id.contains("."):
		return VerifyState.INVALID_NAMESPACE
	# Duplicado
	if _items.has(id):
		push_warning("%s: ID duplicado '%s'" % [_registry_name, id])
		return VerifyState.DUPLICATE_ID
	_items[id] = data
	return VerifyState.OK

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

## Verificar integridad: todos los IDs tienen namespace.
func verify() -> int:
	for id: String in _items:
		if not id.contains("."):
			return VerifyState.INVALID_NAMESPACE
	return VerifyState.OK
