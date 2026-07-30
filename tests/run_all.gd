## Runner de tests unitarios.
extends SceneTree

const UNIT_DIR := "res://tests/unit"
const INTEGRATION_DIR := "res://tests/integration"

func _initialize() -> void:
	# R3: pre-check de compilación de todos los .gd.
	var compile_errors: int = _precheck_compilation()
	if compile_errors > 0:
		printerr("PRE-CHECK: %d archivos .gd no compilan" % compile_errors)
		quit(1)
		return

	var filter: String = ""
	var user_args: Array = OS.get_cmdline_user_args()
	if user_args.size() > 0:
		filter = user_args[0]

	var files: Array = _discover(UNIT_DIR)
	# El directorio de integración es opcional: no se avisa si no está.
	files.append_array(_discover(INTEGRATION_DIR, false))
	var ran: int = 0
	var total_passed: int = 0
	var total_failed: int = 0

	for path in files:
		var file_path: String = path
		if not filter.is_empty() and not file_path.contains(filter):
			continue
		var script: Script = load(file_path)
		if script == null:
			printerr("no se pudo cargar %s" % file_path)
			total_failed += 1
			ran += 1
			continue
		var test_case: Object = script.new()
		test_case.run()
		ran += 1
		total_passed += test_case.passed
		total_failed += test_case.failed

		# R2: un test con 0 assertions es FALLA.
		if test_case.passed + test_case.failed == 0:
			total_failed += 1
			printerr("       %s: 0 assertions ejecutadas (test vacío o crasheado)" % file_path.get_file())

		var status: String = "OK   " if test_case.failed == 0 and test_case.passed > 0 else "FALLA"
		print("%s %-32s %d/%d" % [status, file_path.get_file(), test_case.passed, test_case.passed + test_case.failed])
		for failure in test_case.failures:
			printerr("       %s" % failure)

	print("")
	if ran == 0:
		printerr("ningún test coincidió con el filtro '%s'" % filter)
		quit(1)
		return
	print("%d archivos, %d pasaron, %d fallaron" % [ran, total_passed, total_failed])
	quit(1 if total_failed > 0 else 0)

func _precheck_compilation() -> int:
	# `load()` NO devuelve null ante un error de parseo: devuelve un GDScript
	# inválido. La señal confiable es `reload()`, que devuelve ERR_PARSE_ERROR (43),
	# confirmado con `can_instantiate()`.
	#
	# Un único archivo roto arrastra a otros: cuando un script no parsea, Godot
	# invalida la caché de clases globales y todo lo que dependa de ese
	# `class_name` deja de compilar. Por eso se listan todos los archivos que
	# fallan y se aclara que unos pueden ser consecuencia de otros.
	var failed: Array[String] = []
	var gd_files: Array[String] = _discover_all_gd("res://")
	for path: String in gd_files:
		var script: Variant = load(path)
		if script == null:
			failed.append("%s (no se pudo cargar)" % path)
			continue
		if not (script is GDScript):
			continue
		var gd: GDScript = script
		# No usar reload(): recargar scripts en uso los invalida y produce
		# falsos positivos sobre este mismo runner.
		if not gd.can_instantiate():
			failed.append(path)

	for entry: String in failed:
		printerr("PRE-CHECK: no compila %s" % entry)
	if failed.size() > 1:
		printerr("PRE-CHECK: un error de parseo invalida la caché de clases globales; algunos de estos archivos pueden ser consecuencia de otro.")
	return failed.size()

func _discover_all_gd(dir_path: String) -> Array[String]:
	var out: Array[String] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return out
	# `.gdignore` es la convención de Godot para «esto no es código del
	# proyecto». La usa el build template de Android, que trae sus propios
	# tests en GDScript y no compila fuera de su contexto.
	if FileAccess.file_exists(dir_path.path_join(".gdignore")):
		return out
	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while not entry.is_empty():
		if dir.current_is_dir():
			if not entry.begins_with("."):
				out.append_array(_discover_all_gd(dir_path.path_join(entry)))
		elif entry.ends_with(".gd"):
			out.append(dir_path.path_join(entry))
		entry = dir.get_next()
	dir.list_dir_end()
	return out

func _discover(dir_path: String, required: bool = true) -> Array:
	var out: Array = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		if required:
			printerr("no existe el directorio %s" % dir_path)
		return out
	dir.list_dir_begin()
	var entry := dir.get_next()
	while not entry.is_empty():
		if dir.current_is_dir():
			if not entry.begins_with("."):
				out.append_array(_discover(dir_path.path_join(entry)))
		elif entry.begins_with("test_") and entry.ends_with(".gd"):
			out.append(dir_path.path_join(entry))
		entry = dir.get_next()
	dir.list_dir_end()
	out.sort()
	return out
