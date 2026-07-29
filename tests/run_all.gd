## Runner de tests unitarios.
##
##     godot --headless --path . --script tests/run_all.gd
##     godot --headless --path . --script tests/run_all.gd -- semver
##
## El argumento posterior a `--` filtra por subcadena de la ruta del test.
## Salida 0 si todo pasa, 1 si algo falla o si el filtro no encontró nada.
extends SceneTree

const UNIT_DIR := "res://tests/unit"

func _initialize() -> void:
	var filter := ""
	var user_args := OS.get_cmdline_user_args()
	if user_args.size() > 0:
		filter = user_args[0]

	var files := _discover(UNIT_DIR)
	var ran := 0
	var total_passed := 0
	var total_failed := 0

	for path in files:
		var file_path: String = path
		if not filter.is_empty() and not file_path.contains(filter):
			continue
		var script: Script = load(file_path)
		if script == null:
			printerr("no se pudo cargar %s" % file_path)
			total_failed += 1
			continue
		var test_case = script.new()
		test_case.run()
		ran += 1
		total_passed += test_case.passed
		total_failed += test_case.failed
		var status := "OK   " if test_case.failed == 0 else "FALLA"
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

func _discover(dir_path: String) -> Array:
	var out: Array = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
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
