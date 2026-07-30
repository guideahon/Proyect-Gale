## OverrideEngine — aplica overrides de definiciones entre mods.
##
## Semántica de `docs/09`, que es el contrato público de la Mod API:
##
## - **EXTEND**: agrega comportamiento o listas **sin eliminar el original**.
##   Las claves nuevas se suman, los arrays se concatenan, y una clave escalar
##   que ya existe NO se pisa: para eso está PATCH.
## - **PATCH**: modifica propiedades concretas. Pisa sólo las claves indicadas.
## - **REPLACE**: sustituye toda la definición y emite advertencia.
## - **DISABLE**: saca la definición del registro activo conservando un
##   placeholder, así las partidas guardadas no pierden la referencia.
##
## Se aplican **todos** los overrides de un target, en orden de carga. Guardar
## uno solo por target hacía que dos mods que extienden la misma definición se
## pisaran y valiera nada más que el último.
extends RefCounted

enum Mode { EXTEND, PATCH, REPLACE, DISABLE }

## Resultado de `register`.
enum Result { OK, CONFLICT }

## target_id -> Array de overrides en orden de registro.
var _overrides: Dictionary = {}
var _conflicts: Array = []


## Registra un override. Devuelve CONFLICT cuando el nuevo choca de verdad con
## uno previo —REPLACE o DISABLE contra cualquier otro—, porque ahí no hay
## composición posible y alguien pierde. Dos EXTEND conviven sin conflicto.
func register(mod_id: String, target_id: String, mode: int, data: Dictionary) -> int:
	if not _overrides.has(target_id):
		_overrides[target_id] = []

	var result: int = Result.OK
	for existing: Dictionary in _overrides[target_id]:
		if _is_exclusive(existing.mode) or _is_exclusive(mode):
			push_warning("OverrideEngine: conflicto en '%s' — '%s' (%s) vs '%s' (%s)" % [
				target_id, existing.mod_id, _mode_name(existing.mode),
				mod_id, _mode_name(mode)])
			_conflicts.append({
				"target": target_id,
				"mods": [existing.mod_id, mod_id],
				"modes": [_mode_name(existing.mode), _mode_name(mode)],
			})
			result = Result.CONFLICT

	_overrides[target_id].append({"mod_id": mod_id, "mode": mode, "data": data})
	return result


## Aplica en orden todos los overrides del target sobre la definición base.
func apply(base: Dictionary, target_id: String) -> Dictionary:
	if not _overrides.has(target_id):
		return base

	var result: Dictionary = base.duplicate(true)
	for entry: Dictionary in _overrides[target_id]:
		match entry.mode:
			Mode.EXTEND:
				result = _extend(result, entry.data)
			Mode.PATCH:
				result = _patch(result, entry.data)
			Mode.REPLACE:
				push_warning("OverrideEngine: REPLACE en '%s' por '%s'" % [target_id, entry.mod_id])
				result = entry.data.duplicate(true)
			Mode.DISABLE:
				result = {
					"disabled": true,
					"placeholder": true,
					"disabled_by": entry.mod_id,
					"original_id": target_id,
				}
	return result


## Suma sin destruir: claves nuevas se agregan, arrays se concatenan,
## diccionarios se combinan en profundidad, y un escalar existente se conserva.
static func _extend(base: Dictionary, data: Dictionary) -> Dictionary:
	var out: Dictionary = base.duplicate(true)
	for key: String in data:
		if not out.has(key):
			out[key] = data[key]
			continue
		var current: Variant = out[key]
		var incoming: Variant = data[key]
		if current is Array and incoming is Array:
			var merged: Array = (current as Array).duplicate()
			merged.append_array(incoming as Array)
			out[key] = merged
		elif current is Dictionary and incoming is Dictionary:
			out[key] = _extend(current as Dictionary, incoming as Dictionary)
		# Escalar ya presente: EXTEND no elimina lo original.
	return out


## Pisa sólo las claves indicadas.
static func _patch(base: Dictionary, data: Dictionary) -> Dictionary:
	var out: Dictionary = base.duplicate(true)
	for key: String in data:
		out[key] = data[key]
	return out


static func _is_exclusive(mode: int) -> bool:
	return mode == Mode.REPLACE or mode == Mode.DISABLE


static func _mode_name(mode: int) -> String:
	match mode:
		Mode.EXTEND:
			return "extend"
		Mode.PATCH:
			return "patch"
		Mode.REPLACE:
			return "replace"
		Mode.DISABLE:
			return "disable"
	return "desconocido"


## Conflictos detectados, con los mods y modos involucrados.
func get_conflicts() -> Array:
	return _conflicts


## Cantidad de targets con overrides.
func size() -> int:
	return _overrides.size()


## Cantidad de overrides registrados para un target.
func count_for(target_id: String) -> int:
	if not _overrides.has(target_id):
		return 0
	return (_overrides[target_id] as Array).size()
