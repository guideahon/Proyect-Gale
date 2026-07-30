## Tests de `override_engine.gd`.
##
## Verifican la semántica de docs/09, que es el contrato público de la Mod API:
## EXTEND suma sin destruir, PATCH pisa propiedades concretas, REPLACE sustituye
## con advertencia, DISABLE deja placeholder. Y que dos mods que extienden la
## misma definición se compongan en vez de pisarse.
##
## Los tests anteriores afirmaban que EXTEND sobrescribía el valor original, que
## es exactamente lo que docs/09 prohíbe: describían la implementación, no el
## contrato.
extends "res://tests/framework/test_case.gd"

const OverrideEngine := preload("res://core/mods/override_engine.gd")

func run() -> void:
	_test_sin_override_devuelve_base()
	_test_extend_suma_sin_destruir()
	_test_extend_concatena_listas()
	_test_patch_pisa_propiedades()
	_test_replace_sustituye()
	_test_disable_deja_placeholder()
	_test_dos_extend_se_componen()
	_test_conflicto_solo_con_exclusivos()
	_test_orden_de_carga()


func _base() -> Dictionary:
	return {
		"damage": 12,
		"abilities": ["official:slash"],
		"audio": {"hit": "official:sword_light"},
	}


func _test_sin_override_devuelve_base() -> void:
	var eng := OverrideEngine.new()
	check(eng.apply(_base(), "official:sword").get("damage"), 12, "sin override no cambia nada")
	check(eng.size(), 0, "sin overrides registrados")


func _test_extend_suma_sin_destruir() -> void:
	var eng := OverrideEngine.new()
	eng.register("autor.mod", "official:sword", OverrideEngine.Mode.EXTEND, {
		"damage": 999,
		"reach": 2.5,
	})
	var out: Dictionary = eng.apply(_base(), "official:sword")
	check(out.get("damage"), 12, "EXTEND no elimina el valor original")
	check(out.get("reach"), 2.5, "EXTEND agrega la clave nueva")


func _test_extend_concatena_listas() -> void:
	var eng := OverrideEngine.new()
	eng.register("autor.mod", "official:sword", OverrideEngine.Mode.EXTEND, {
		"abilities": ["autor.mod:lightning"],
	})
	var out: Dictionary = eng.apply(_base(), "official:sword")
	check(out.get("abilities"), ["official:slash", "autor.mod:lightning"], "EXTEND concatena listas")


func _test_patch_pisa_propiedades() -> void:
	var eng := OverrideEngine.new()
	eng.register("autor.mod", "official:sword", OverrideEngine.Mode.PATCH, {"damage": 20, "reach": 3.0})
	var out: Dictionary = eng.apply(_base(), "official:sword")
	check(out.get("damage"), 20, "PATCH pisa la propiedad")
	check(out.get("reach"), 3.0, "PATCH agrega la indicada que faltaba")
	check(out.get("abilities"), ["official:slash"], "PATCH no toca el resto")


func _test_replace_sustituye() -> void:
	var eng := OverrideEngine.new()
	eng.register("autor.mod", "official:sword", OverrideEngine.Mode.REPLACE, {"damage": 1})
	var out: Dictionary = eng.apply(_base(), "official:sword")
	check(out.get("damage"), 1, "REPLACE deja su valor")
	check_ok(not out.has("abilities"), "REPLACE sustituye toda la definición")


func _test_disable_deja_placeholder() -> void:
	var eng := OverrideEngine.new()
	eng.register("autor.mod", "official:sword", OverrideEngine.Mode.DISABLE, {})
	var out: Dictionary = eng.apply(_base(), "official:sword")
	check(out.get("disabled"), true, "queda marcada como deshabilitada")
	check(out.get("placeholder"), true, "queda placeholder para las partidas")
	check(out.get("disabled_by"), "autor.mod", "dice quién la deshabilitó")
	check(out.get("original_id"), "official:sword", "conserva a qué se refería")


func _test_dos_extend_se_componen() -> void:
	# El bug que había: se guardaba un solo override por target, así que el
	# segundo mod borraba al primero.
	var eng := OverrideEngine.new()
	eng.register("mod.a", "official:sword", OverrideEngine.Mode.EXTEND, {"abilities": ["mod.a:fire"]})
	eng.register("mod.b", "official:sword", OverrideEngine.Mode.EXTEND, {"abilities": ["mod.b:ice"]})
	check(eng.count_for("official:sword"), 2, "los dos overrides quedan registrados")
	var out: Dictionary = eng.apply(_base(), "official:sword")
	check(out.get("abilities"), ["official:slash", "mod.a:fire", "mod.b:ice"], "se componen en orden")
	check(eng.get_conflicts().size(), 0, "dos EXTEND no son conflicto")


func _test_conflicto_solo_con_exclusivos() -> void:
	var eng := OverrideEngine.new()
	eng.register("mod.a", "official:sword", OverrideEngine.Mode.EXTEND, {})
	var r: int = eng.register("mod.b", "official:sword", OverrideEngine.Mode.REPLACE, {"damage": 1})
	check(r, OverrideEngine.Result.CONFLICT, "REPLACE sobre otro override es conflicto")
	var c: Array = eng.get_conflicts()
	check(c.size(), 1, "un conflicto registrado")
	check(c[0].get("mods"), ["mod.a", "mod.b"], "nombra los dos mods")
	check(c[0].get("modes"), ["extend", "replace"], "nombra los dos modos")


func _test_orden_de_carga() -> void:
	var eng := OverrideEngine.new()
	eng.register("mod.a", "official:sword", OverrideEngine.Mode.PATCH, {"damage": 20})
	eng.register("mod.b", "official:sword", OverrideEngine.Mode.PATCH, {"damage": 30})
	check(eng.apply(_base(), "official:sword").get("damage"), 30, "el último en cargar gana")
