## Tests de `core/mods/manifest_parser.gd`.
extends "res://tests/framework/test_case.gd"

func run() -> void:
	_test_valid_sample_mod_manifest()
	_test_invalid_json()
	_test_missing_required_field()
	_test_bad_id_format()
	_test_bad_type()
	_test_get_id_on_valid()
	_test_get_id_on_invalid()

func _get_parser() -> Object:
	var script: Script = load("res://core/mods/manifest_parser.gd")
	return script.new()

func _test_valid_sample_mod_manifest() -> void:
	var mp: Object = _get_parser()
	var result: Variant = mp.parse("res://examples/sample_mod/manifest.json")
	check_ok(result is Dictionary, "sample_mod manifest es Dictionary")
	var manifest: Dictionary = result
	check(manifest.id, "example.storm_island", "id correcto")
	check(manifest.name, "Storm Island Example", "name correcto")
	check(manifest.type, "content", "type es content")
	check_ok(manifest.format_version == 1 or manifest.format_version == 1.0, "format_version es 1")
	check_ok(manifest.has("dependencies"), "tiene dependencies")
	var deps: Array = manifest.dependencies
	check_ok(deps.size() > 0, "al menos una dependencia")

func _write_temp(path: String, content: String) -> String:
	var tmp: String = "user://test_tmp_" + path.get_file()
	var f: FileAccess = FileAccess.open(tmp, FileAccess.WRITE)
	if f:
		f.store_string(content)
		f.close()
	return tmp

func _test_invalid_json() -> void:
	var mp: Object = _get_parser()
	var tmp: String = _write_temp("bad_manifest.json", "{invalid json}")
	var result: Variant = mp.parse(tmp)
	check_ok(result is Object, "JSON invalido devuelve un objeto de error")
	DirAccess.remove_absolute(tmp)

func _test_missing_required_field() -> void:
	var mp: Object = _get_parser()
	var tmp: String = _write_temp("incomplete_manifest.json", "{\"format_version\": 1}")
	var result: Variant = mp.parse(tmp)
	check_ok(result is Object, "manifiesto incompleto devuelve error")
	DirAccess.remove_absolute(tmp)

func _test_bad_id_format() -> void:
	var mp: Object = _get_parser()
	var tmp: String = _write_temp("bad_id_manifest.json", "{\"format_version\":1,\"id\":\"sin_namespace\",\"name\":\"T\",\"author\":\"T\",\"version\":\"1.0.0\",\"game_version\":\">=0.1.0\",\"mod_api\":\"^1.0\",\"type\":\"content\",\"license\":\"MIT\"}")
	var result: Variant = mp.parse(tmp)
	check_ok(result is Object, "ID sin namespace devuelve error")
	DirAccess.remove_absolute(tmp)

func _test_bad_type() -> void:
	var mp: Object = _get_parser()
	var tmp: String = _write_temp("bad_type_manifest.json", "{\"format_version\":1,\"id\":\"test.mod\",\"name\":\"T\",\"author\":\"T\",\"version\":\"1.0.0\",\"game_version\":\">=0.1.0\",\"mod_api\":\"^1.0\",\"type\":\"invalid_type\",\"license\":\"MIT\"}")
	var result: Variant = mp.parse(tmp)
	check_ok(result is Object, "type invalido devuelve error")
	DirAccess.remove_absolute(tmp)

func _test_get_id_on_valid() -> void:
	var mp: Object = _get_parser()
	var mid: String = mp.get_id("res://examples/sample_mod/manifest.json")
	check(mid, "example.storm_island", "get_id devuelve el id correcto")

func _test_get_id_on_invalid() -> void:
	var mp: Object = _get_parser()
	var mid: String = mp.get_id("res://nonexistent/manifest.json")
	check_ok(mid.find("inaccesible") >= 0 or mid.find("sin") >= 0, "get_id maneja archivo inexistente")
