## Tests de registry_base.gd.
##
## Los IDs son `namespace:nombre` (docs/08): `official:sword_basic`,
## `autor.mod:contenido`. El separador es dos puntos, igual que el patrón
## `^[a-z0-9_.-]+:[a-z0-9_.-]+$` que exigen todos los schemas.
extends "res://tests/framework/test_case.gd"

const RegistryBase := preload("res://core/mods/registry_base.gd")

func run() -> void:
	_test_register_and_get()
	_test_missing_id_returns_null()
	_test_id_format()
	_test_duplicate_id_reported()
	_test_get_all_ids()
	_test_verify_ok()
	_test_verify_invalid_namespace()
	_test_size()

func _new_registry() -> Object:
	return RegistryBase.new("test_items")

func _test_register_and_get() -> void:
	var reg := _new_registry()
	check(reg.register("official:sword_basic", {"name": "Sword"}), RegistryBase.VerifyState.OK, "OK al registrar")
	var item: Variant = reg.lookup("official:sword_basic")
	check_ok(item is Dictionary, "lookup devuelve el item")
	check(item.get("name"), "Sword", "datos correctos")
	# Namespace con punto, como los mods de autor: autor.mod:contenido
	check(reg.register("guideahon.storm:storm_sword", {}), RegistryBase.VerifyState.OK, "namespace con punto aceptado")

func _test_missing_id_returns_null() -> void:
	var reg := _new_registry()
	check_ok(reg.lookup("official:nonexistent") == null, "ID inexistente devuelve null")

func _test_id_format() -> void:
	var reg := _new_registry()
	# Sin separador: es lo que el sistema tiene que rechazar.
	check(reg.register("sword", {}), RegistryBase.VerifyState.INVALID_NAMESPACE, "sin namespace rechazado")
	# Punto en lugar de dos puntos: formato viejo, ya no vale.
	check(reg.register("official.sword", {}), RegistryBase.VerifyState.INVALID_NAMESPACE, "punto no es separador de namespace")
	check(reg.register("", {}), RegistryBase.VerifyState.MISSING_ID, "ID vacío")
	check(reg.register(":sword", {}), RegistryBase.VerifyState.INVALID_NAMESPACE, "namespace vacío")
	check(reg.register("official:", {}), RegistryBase.VerifyState.INVALID_NAMESPACE, "nombre vacío")
	check(reg.register("official:a:b", {}), RegistryBase.VerifyState.INVALID_NAMESPACE, "dos separadores")
	check(reg.register("Official:Sword", {}), RegistryBase.VerifyState.INVALID_NAMESPACE, "mayúsculas rechazadas")
	check(reg.register("official:sword basico", {}), RegistryBase.VerifyState.INVALID_NAMESPACE, "espacios rechazados")
	check(reg.register("official:res://x.tscn", {}), RegistryBase.VerifyState.INVALID_NAMESPACE, "una ruta no es un ID")
	check(reg.size(), 0, "ninguno de los inválidos quedó registrado")

func _test_duplicate_id_reported() -> void:
	var reg := _new_registry()
	reg.register("official:sword_basic", {"name": "Sword"})
	check(reg.register("official:sword_basic", {"name": "Sword2"}), RegistryBase.VerifyState.DUPLICATE_ID, "DUPLICATE_ID para ID repetido")
	check(reg.lookup("official:sword_basic").get("name"), "Sword", "el duplicado no sobrescribe al original")

func _test_get_all_ids() -> void:
	var reg := _new_registry()
	reg.register("official:sword_basic", {})
	reg.register("official:shield_wood", {})
	var ids: PackedStringArray = reg.get_all_ids()
	check(ids.size(), 2, "dos IDs registrados")
	check_ok(ids.has("official:sword_basic"), "sword en lista")
	check_ok(ids.has("official:shield_wood"), "shield en lista")

func _test_verify_ok() -> void:
	var reg := _new_registry()
	reg.register("official:sword_basic", {})
	check(reg.verify(), RegistryBase.VerifyState.OK, "OK cuando todos los IDs son válidos")

func _test_verify_invalid_namespace() -> void:
	var reg := _new_registry()
	# Se escribe directo en _items para simular un registro corrupto que no
	# pasó por register(): verify() es la última red.
	reg._items["bad_id"] = {}
	check(reg.verify(), RegistryBase.VerifyState.INVALID_NAMESPACE, "INVALID_NAMESPACE detectado")

func _test_size() -> void:
	var reg := _new_registry()
	check(reg.size(), 0, "vacío al inicio")
	reg.register("official:sword_basic", {})
	check(reg.size(), 1, "uno registrado")
