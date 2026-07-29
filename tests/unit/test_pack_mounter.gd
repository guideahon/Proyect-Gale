## Tests de pack_mounter.gd.
extends "res://tests/framework/test_case.gd"

func run() -> void:
	_test_hash_function()
	_test_safe_name()
	_test_mount_wrong_hash()
	_test_mount_corrupt_zip()

func _test_hash_function() -> void:
	var mounter: Script = load("res://core/mods/pack_mounter.gd")
	var h: String = mounter._hash("test".to_utf8_buffer())
	check_ok(h.length() == 64, "hash produce 64 chars hex")

func _test_safe_name() -> void:
	var mounter: Script = load("res://core/mods/pack_mounter.gd")
	check(mounter._safe_name("res://path/my_mod.gmod"), "my_mod", "nombre seguro")
	check(mounter._safe_name("res://path/123.gmod"), "123", "numeros OK")

func _test_mount_wrong_hash() -> void:
	var mounter: Script = load("res://core/mods/pack_mounter.gd")
	var result: Variant = mounter.mount("res://tests/data/e2e_valid.gmod", "wrong_hash")
	check_ok(not result.ok, "rechaza hash incorrecto")

func _test_mount_corrupt_zip() -> void:
	var mounter: Script = load("res://core/mods/pack_mounter.gd")
	var result: Variant = mounter.mount("res://tests/data/nonexistent.gmod", "")
	check_ok(not result.ok, "rechaza ZIP inexistente")
