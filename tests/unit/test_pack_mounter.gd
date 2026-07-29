## Tests de pack_mounter.gd.
##
## Lo que importa acá es el ORDEN de docs/24 §5: estructura y lista blanca de
## ADR-012 primero, firma después, montaje al final. Montar y validar luego
## sería inútil, porque al montar el contenido ya quedó disponible al motor.
extends "res://tests/framework/test_case.gd"

const PackMounter := preload("res://core/mods/pack_mounter.gd")

func run() -> void:
	_test_hash_function()
	_test_safe_name_unique()
	_test_rejects_missing_zip()
	_test_rejects_package_with_script()
	_test_rejects_tampered_package()
	_test_unsigned_requires_hash()
	_test_wrong_hash_rejected()
	_test_discard_cached_pack()


func _test_hash_function() -> void:
	check(PackMounter._hash("test".to_utf8_buffer()).length(), 64, "hash produce 64 chars hex")


func _test_safe_name_unique() -> void:
	# El bug que había: al descartar caracteres, dos nombres distintos daban el
	# mismo archivo de caché y un paquete sobrescribía al otro en silencio.
	var a: String = PackMounter._safe_name("res://mods/mi-mod.gmod")
	var b: String = PackMounter._safe_name("res://mods/mimod.gmod")
	check_ok(a != b, "nombres distintos no colapsan en el mismo archivo")
	# Mismo path, mismo nombre: el caché tiene que ser estable.
	check(PackMounter._safe_name("res://mods/mi-mod.gmod"), a, "determinístico para el mismo path")
	for c: String in a:
		var ok := (c >= "a" and c <= "z") or (c >= "0" and c <= "9") or c == "_"
		check_ok(ok, "sólo caracteres seguros en el nombre de caché")


func _test_rejects_missing_zip() -> void:
	var r: Variant = PackMounter.mount("res://tests/data/nonexistent.gmod", "")
	check_ok(not r.ok, "rechaza ZIP inexistente")


func _test_rejects_package_with_script() -> void:
	# e2e_extra.gmod trae malicious.gd: la lista blanca de ADR-012 tiene que
	# frenarlo ANTES de montar nada.
	var r: Variant = PackMounter.mount("res://tests/data/e2e_extra.gmod", "")
	check_ok(not r.ok, "rechaza paquete con .gd adentro")
	check_ok(r.message.contains("rechazado"), "el motivo dice que lo rechazó el validador de paquete")


func _test_rejects_tampered_package() -> void:
	var r: Variant = PackMounter.mount("res://tests/data/e2e_tampered.gmod", "")
	check_ok(not r.ok, "rechaza paquete alterado tras firmar")


func _test_unsigned_requires_hash() -> void:
	# Sin firma es legítimo (docs/24 §6), pero entonces el hash del PCK es
	# obligatorio: si no, nada verificaría la integridad.
	var r: Variant = PackMounter.mount("res://tests/data/e2e_none.gmod", "")
	check_ok(not r.ok, "sin firma y sin hash: rechazado")


func _test_wrong_hash_rejected() -> void:
	var r: Variant = PackMounter.mount("res://tests/data/e2e_valid.gmod", "0".repeat(64))
	check_ok(not r.ok, "rechaza hash incorrecto")


func _test_discard_cached_pack() -> void:
	var path := "user://mod_cache/test_discard.pck"
	DirAccess.make_dir_recursive_absolute("user://mod_cache")
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string("x")
	f.close()
	check_ok(PackMounter.discard_cached_pack(path), "borra el PCK del caché")
	check_ok(not FileAccess.file_exists(path), "el archivo ya no está")
	check_ok(not PackMounter.discard_cached_pack(path), "borrar algo que no existe devuelve false")
