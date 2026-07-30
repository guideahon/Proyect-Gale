## Tests de integración: varios paquetes, overrides encadenados, mod ausente,
## orden de carga.
##
## ALCANCE: por ahora se compone en memoria, sin montar PCKs de verdad. Los
## fixtures `.gmod` de `tests/data` llevan un `content.pck` de relleno, no un
## PCK real, así que `pack_mounter` los rechazaría. Montaje real de dos paquetes
## queda pendiente en T3.14, y necesita fixtures con PCKs generados por Godot.
extends "res://tests/framework/test_case.gd"

func run() -> void:
	_test_multiple_packages_load_order()
	_test_chained_overrides()
	_test_missing_mod_safe_fallback()
	_test_official_base_without_island()

func _test_multiple_packages_load_order() -> void:
	# Simular carga de 3 mods en orden: A, B, C.
	var engine: Object = load("res://core/mods/override_engine.gd").new()
	engine.register("mod_a", "official:weapon", engine.Mode.EXTEND, {"damage": 10})
	engine.register("mod_b", "official:weapon", engine.Mode.PATCH, {"damage": 20})
	engine.register("mod_c", "official:weapon", engine.Mode.EXTEND, {"enchant": "ice"})
	var base: Dictionary = {"name": "Sword"}
	var result: Dictionary = engine.apply(base, "official:weapon")
	check(result.damage, 20, "mod_b PATCH pisó damage")
	check(result.enchant, "ice", "mod_c EXTEND agregó enchant")
	check(result.name, "Sword", "base conservada")

func _test_chained_overrides() -> void:
	# Dos mods sobrescriben lo mismo: ultimo gana.
	var engine: Object = load("res://core/mods/override_engine.gd").new()
	engine.register("mod_x", "official:armor", engine.Mode.REPLACE, {"defense": 50})
	engine.register("mod_y", "official:armor", engine.Mode.REPLACE, {"defense": 100})
	var result: Dictionary = engine.apply({"defense": 10}, "official:armor")
	check(result.defense, 100, "ultimo mod gana")
	var conflicts: Array = engine.get_conflicts()
	check_ok(conflicts.size() > 0, "conflicto reportado")

func _test_missing_mod_safe_fallback() -> void:
	# Sin official.base, el juego no crashea: modo seguro.
	#
	# Ojo con las dos formas de ID, que no son intercambiables (docs/08):
	#   - paquete de mod: `official.base`, con PUNTO (patrón de mod_manifest)
	#   - contenido:      `official:base_island`, con DOS PUNTOS
	# `should_load_mod` recibe el ID del paquete, y además exige que la firma se
	# haya verificado contra la clave anclada: el nombre no prueba procedencia.
	var sm: Script = load("res://core/mods/safe_mode.gd")
	sm.record_success()
	sm.record_failure()
	sm.record_failure()
	sm.record_failure()
	check_ok(sm.is_active(), "modo seguro tras 3 fallos")
	check_ok(not sm.should_load_mod("third_party.mod", true), "bloquea mods terceros")
	check_ok(sm.should_load_mod("official.base", true), "permite official con firma verificada")
	check_ok(not sm.should_load_mod("official.base", false), "no alcanza con el nombre oficial")
	sm.record_success()

func _test_official_base_without_island() -> void:
	# official.base registra la isla. Sin ella, registry queda vacio pero no crashea.
	var reg: Object = load("res://core/mods/registry_base.gd").new("maps")
	var item: Variant = reg.lookup("official:base_island")
	check_ok(item == null, "sin official.base, isla no registrada")
	# Registrar official.base
	var ob: Script = load("res://official_mods/official.base/register.gd")
	ob.register(reg)
	item = reg.lookup("official:base_island")
	check_ok(item is Dictionary, "isla registrada tras official.base")
	check(item.get("type"), "map", "tipo correcto")
	check(item.get("required"), true, "marcado como requerido")
