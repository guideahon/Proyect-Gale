## OverrideEngine — gestiona overrides de definiciones entre mods.
## Modos: extend, patch, replace (con advertencia), disable (placeholder).
extends RefCounted

enum Mode { EXTEND, PATCH, REPLACE, DISABLE }

## Registro de overrides activos.
var _overrides: Dictionary = {}
var _conflicts: Array = []

## Registrar un override. Devuelve OK (0) o CONFLICT (1).
func register(mod_id: String, target_id: String, mode: int, data: Dictionary) -> int:
	var key: String = target_id
	if _overrides.has(key):
		var existing: Dictionary = _overrides[key]
		push_warning("OverrideEngine: conflicto en '%s' — '%s' vs '%s'" % [target_id, existing.mod_id, mod_id])
		_conflicts.append({"target": target_id, "mods": [existing.mod_id, mod_id]})
		# El ultimo mod gana (orden de carga)
	_overrides[key] = {"mod_id": mod_id, "mode": mode, "data": data}
	return 0

## Aplicar override a una definicion base.
func apply(base: Dictionary, target_id: String) -> Dictionary:
	if not _overrides.has(target_id):
		return base
	var override: Dictionary = _overrides[target_id]
	match override.mode:
		Mode.EXTEND:
			var result: Dictionary = base.duplicate()
			for k: String in override.data:
				result[k] = override.data[k]
			return result
		Mode.PATCH:
			var result: Dictionary = base.duplicate()
			for k: String in override.data:
				if result.has(k):
					result[k] = override.data[k]
			return result
		Mode.REPLACE:
			push_warning("OverrideEngine: REPLACE en '%s' por '%s'" % [target_id, override.mod_id])
			return override.data.duplicate()
		Mode.DISABLE:
			return {"disabled": true, "placeholder": true, "disabled_by": override.mod_id}
	return base

## Listar conflictos detectados.
func get_conflicts() -> Array:
	return _conflicts

## Cantidad de overrides activos.
func size() -> int:
	return _overrides.size()
