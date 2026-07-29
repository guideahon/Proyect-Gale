## Tests de registry_base.gd.
extends "res://tests/framework/test_case.gd"

func run() -> void:
	_test_register_and_get()
	_test_missing_id_returns_null()
	_test_no_namespace_rejected()
	_test_duplicate_id_reported()
	_test_get_all_ids()
	_test_verify_ok()
	_test_verify_invalid_namespace()
	_test_size()

func _test_register_and_get() -> void:
	var reg: Object = load("res://core/mods/registry_base.gd").new("test_items")
	var state: int = reg.register("official.sword", {"name": "Sword"})
	check(state, 0, "OK al registrar")
	var item: Variant = reg.lookup("official.sword")
	check_ok(item is Dictionary, "get devuelve el item")
	check(item.get("name"), "Sword", "datos correctos")

func _test_missing_id_returns_null() -> void:
	var reg: Object = load("res://core/mods/registry_base.gd").new("test_items")
	var item: Variant = reg.lookup("nonexistent.item")
	check_ok(item == null, "ID inexistente devuelve null")

func _test_no_namespace_rejected() -> void:
	var reg: Object = load("res://core/mods/registry_base.gd").new("test_items")
	var state: int = reg.register("sword", {"name": "Sword"})
	check(state, 3, "INVALID_NAMESPACE para ID sin punto")

func _test_duplicate_id_reported() -> void:
	var reg: Object = load("res://core/mods/registry_base.gd").new("test_items")
	reg.register("official.sword", {"name": "Sword"})
	var state: int = reg.register("official.sword", {"name": "Sword2"})
	check(state, 2, "DUPLICATE_ID para ID repetido")

func _test_get_all_ids() -> void:
	var reg: Object = load("res://core/mods/registry_base.gd").new("test_items")
	reg.register("official.sword", {})
	reg.register("official.shield", {})
	var ids: PackedStringArray = reg.get_all_ids()
	check(ids.size(), 2, "dos IDs registrados")
	check_ok(ids.has("official.sword"), "sword en lista")
	check_ok(ids.has("official.shield"), "shield en lista")

func _test_verify_ok() -> void:
	var reg: Object = load("res://core/mods/registry_base.gd").new("test_items")
	reg.register("official.sword", {})
	var state: int = reg.verify()
	check(state, 0, "OK cuando todos tienen namespace")

func _test_verify_invalid_namespace() -> void:
	var reg: Object = load("res://core/mods/registry_base.gd").new("test_items")
	# Registrar sin namespace (hack: escribir directo en _items)
	reg._items["bad_id"] = {}
	var state: int = reg.verify()
	check(state, 3, "INVALID_NAMESPACE detectado")

func _test_size() -> void:
	var reg: Object = load("res://core/mods/registry_base.gd").new("test_items")
	check(reg.size(), 0, "vacio al inicio")
	reg.register("official.sword", {})
	check(reg.size(), 1, "uno registrado")
