## Tests de override_engine.gd.
extends "res://tests/framework/test_case.gd"

func run() -> void:
	_test_extend_mode()
	_test_patch_mode()
	_test_replace_mode()
	_test_disable_mode()
	_test_two_mods_conflict()
	_test_no_override_passes_through()

func _test_extend_mode() -> void:
	var engine: Object = load("res://core/mods/override_engine.gd").new()
	var base: Dictionary = {"name": "Sword", "damage": 10}
	engine.register("mod_a", "official.sword", engine.Mode.EXTEND, {"damage": 15, "enchant": "fire"})
	var result: Dictionary = engine.apply(base, "official.sword")
	check(result.damage, 15, "damage extendido")
	check(result.enchant, "fire", "nuevo campo agregado")
	check(result.name, "Sword", "campo original conservado")

func _test_patch_mode() -> void:
	var engine: Object = load("res://core/mods/override_engine.gd").new()
	var base: Dictionary = {"name": "Sword", "damage": 10, "weight": 2}
	engine.register("mod_a", "official.sword", engine.Mode.PATCH, {"damage": 20})
	var result: Dictionary = engine.apply(base, "official.sword")
	check(result.damage, 20, "damage parcheado")
	check(result.weight, 2, "campo no parcheado conservado")
	check_ok(not result.has("enchant"), "no agrega campos nuevos")

func _test_replace_mode() -> void:
	var engine: Object = load("res://core/mods/override_engine.gd").new()
	var base: Dictionary = {"name": "Sword", "damage": 10}
	engine.register("mod_a", "official.sword", engine.Mode.REPLACE, {"name": "MegaSword", "damage": 999})
	var result: Dictionary = engine.apply(base, "official.sword")
	check(result.name, "MegaSword", "nombre reemplazado")
	check(result.damage, 999, "damage reemplazado")
	check_ok(not result.has("weight"), "campos originales eliminados")

func _test_disable_mode() -> void:
	var engine: Object = load("res://core/mods/override_engine.gd").new()
	var base: Dictionary = {"name": "Sword", "damage": 10}
	engine.register("mod_a", "official.sword", engine.Mode.DISABLE, {})
	var result: Dictionary = engine.apply(base, "official.sword")
	check_ok(result.disabled, "marcado como deshabilitado")
	check_ok(result.placeholder, "es un placeholder")
	check(result.disabled_by, "mod_a", "nombra al mod causante")

func _test_two_mods_conflict() -> void:
	var engine: Object = load("res://core/mods/override_engine.gd").new()
	engine.register("mod_a", "official.sword", engine.Mode.EXTEND, {"damage": 15})
	engine.register("mod_b", "official.sword", engine.Mode.EXTEND, {"damage": 25})
	var conflicts: Array = engine.get_conflicts()
	check_ok(conflicts.size() > 0, "conflicto reportado")
	var last: Dictionary = engine.apply({"name": "Sword"}, "official.sword")
	check(last.damage, 25, "ultimo mod gana")

func _test_no_override_passes_through() -> void:
	var engine: Object = load("res://core/mods/override_engine.gd").new()
	var base: Dictionary = {"name": "Sword", "damage": 10}
	var result: Dictionary = engine.apply(base, "official.shield")
	check(result.name, "Sword", "base sin cambios")
	check(result.damage, 10, "base sin cambios")
