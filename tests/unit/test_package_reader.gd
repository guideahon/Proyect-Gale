## Tests de `core/mods/package_reader.gd`.
extends "res://tests/framework/test_case.gd"

func run() -> void:
	_test_valid_package()
	_test_missing_manifest()
	_test_path_traversal()
	_test_hidden_segment()
	_test_absolute_path()
	_test_duplicate_entry()
	_test_case_duplicate()
	_test_disallowed_extension_gd()
	_test_disallowed_extension_gdshader()
	_test_case_insensitive_duplicate()

func _get_reader() -> Object:
	var script: Script = load("res://core/mods/package_reader.gd")
	return script.new()

## Construye un ZIP minimo con las entradas dadas usando Python.
func _build_zip(path: String, entries: Array[String]) -> void:
	DirAccess.make_dir_recursive_absolute("user://test_pkg")
	var abs_path: String = ProjectSettings.globalize_path(path)
	var list_path: String = abs_path + ".list"
	var f: FileAccess = FileAccess.open(list_path, FileAccess.WRITE)
	if f:
		for entry: String in entries:
			f.store_line(entry)
		f.close()
	var py_script: String = "user://test_pkg/_make_zip.py"
	var abs_py: String = ProjectSettings.globalize_path(py_script)
	var pf: FileAccess = FileAccess.open(py_script, FileAccess.WRITE)
	if pf:
		pf.store_line("import zipfile, sys")
		pf.store_line("path, list_path = sys.argv[1], sys.argv[2]")
		pf.store_line("with open(list_path) as f:")
		pf.store_line("    entries = [l.strip() for l in f]")
		pf.store_line("with zipfile.ZipFile(path, 'w') as z:")
		pf.store_line("    for e in entries:")
		pf.store_line("        z.writestr(e, 'test')")
		pf.close()
	var output: Array = []
	OS.execute("python", [abs_py, abs_path, list_path], output, true)
	DirAccess.remove_absolute(list_path)
	DirAccess.remove_absolute(py_script)

func _test_valid_package() -> void:
	var reader: Object = _get_reader()
	var tmp: String = "user://test_pkg/valid_package.gmod"
	_build_zip(tmp, ["manifest.json", "content.pck", "icon.webp", "README.md"])
	check_ok(FileAccess.file_exists(tmp), "ZIP creado correctamente")
	var result: Variant = reader.validate(tmp)
	check_ok(result == null, "paquete valido pasa")
	DirAccess.remove_absolute(tmp)

func _test_missing_manifest() -> void:
	var reader: Object = _get_reader()
	var tmp: String = "user://test_pkg/no_manifest.gmod"
	_build_zip(tmp, ["content.pck", "icon.webp"])
	var result: Variant = reader.validate(tmp)
	check_ok(result != null, "paquete sin manifest falla")
	DirAccess.remove_absolute(tmp)

func _test_path_traversal() -> void:
	var reader: Object = _get_reader()
	var tmp: String = "user://test_pkg/traversal.gmod"
	_build_zip(tmp, ["manifest.json", "../evil.txt"])
	var result: Variant = reader.validate(tmp)
	check_ok(result != null, "path traversal rechazado")
	DirAccess.remove_absolute(tmp)

func _test_hidden_segment() -> void:
	var reader: Object = _get_reader()
	var tmp: String = "user://test_pkg/hidden.gmod"
	_build_zip(tmp, ["manifest.json", ".hidden/file.txt"])
	var result: Variant = reader.validate(tmp)
	check_ok(result != null, "segmento oculto rechazado")
	DirAccess.remove_absolute(tmp)

func _test_absolute_path() -> void:
	var reader: Object = _get_reader()
	var tmp: String = "user://test_pkg/absolute.gmod"
	_build_zip(tmp, ["manifest.json", "etc/passwd"])
	var result: Variant = reader.validate(tmp)
	check_ok(result != null, "ruta absoluta rechazada")
	DirAccess.remove_absolute(tmp)

func _test_duplicate_entry() -> void:
	var reader: Object = _get_reader()
	var tmp: String = "user://test_pkg/duplicate.gmod"
	_build_zip(tmp, ["manifest.json", "content.pck", "content.pck"])
	var result: Variant = reader.validate(tmp)
	check_ok(result != null, "entrada duplicada rechazada")
	DirAccess.remove_absolute(tmp)

func _test_case_duplicate() -> void:
	var reader: Object = _get_reader()
	var tmp: String = "user://test_pkg/case_dup.gmod"
	_build_zip(tmp, ["manifest.json", "Content.pck", "content.PCK"])
	var result: Variant = reader.validate(tmp)
	check_ok(result != null, "duplicado case-insensitive rechazado")
	DirAccess.remove_absolute(tmp)

func _test_disallowed_extension_gd() -> void:
	var reader: Object = _get_reader()
	var tmp: String = "user://test_pkg/bad_ext_gd.gmod"
	_build_zip(tmp, ["manifest.json", "evil.gd"])
	var result: Variant = reader.validate(tmp)
	check_ok(result != null, "extension .gd rechazada")
	DirAccess.remove_absolute(tmp)

func _test_disallowed_extension_gdshader() -> void:
	var reader: Object = _get_reader()
	var tmp: String = "user://test_pkg/bad_ext_shader.gmod"
	_build_zip(tmp, ["manifest.json", "evil.gdshader"])
	var result: Variant = reader.validate(tmp)
	check_ok(result != null, "extension .gdshader rechazada")
	DirAccess.remove_absolute(tmp)

func _test_case_insensitive_duplicate() -> void:
	var reader: Object = _get_reader()
	var tmp: String = "user://test_pkg/case_dup2.gmod"
	_build_zip(tmp, ["manifest.json", "Readme.md", "README.MD"])
	var result: Variant = reader.validate(tmp)
	check_ok(result != null, "duplicado case-insensitive 2 rechazado")
	DirAccess.remove_absolute(tmp)
