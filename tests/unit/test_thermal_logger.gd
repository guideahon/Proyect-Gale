## Tests de `core/perf/thermal_logger.gd`.
##
## Verifica que genera archivos CSV parseables con la estructura esperada.
extends "res://tests/framework/test_case.gd"

const ThermalLogger := preload("res://core/perf/thermal_logger.gd")

func run() -> void:
	_test_logger_creates_csv()
	_test_csv_structure()
	_test_sample_count()
	_test_inactive_ignores_samples()
	_test_stop_closes_file()


func _test_logger_creates_csv() -> void:
	var logger := ThermalLogger.new(1.0, "user://test_logs")
	logger.start()
	logger.log_sample(5.0, 6.0, 42.0)
	logger.stop()

	# Verificar que el directorio y archivo existen.
	var dir := DirAccess.open("user://test_logs")
	check_ok(dir != null, "directorio de logs creado")

	dir.list_dir_begin()
	var found_csv := false
	var file := dir.get_next()
	while not file.is_empty():
		if file.begins_with("thermal_") and file.ends_with(".csv"):
			found_csv = true
		file = dir.get_next()
	dir.list_dir_end()

	check_ok(found_csv, "archivo CSV creado")


func _test_csv_structure() -> void:
	var logger := ThermalLogger.new(1.0, "user://test_logs2")
	logger.start()
	logger.log_sample(3.0, 4.0, 38.5)
	logger.log_sample(7.0, 8.0, 45.0)
	logger.stop()

	# Leer el archivo CSV y verificar estructura.
	var dir := DirAccess.open("user://test_logs2")
	dir.list_dir_begin()
	var csv_file := ""
	var file := dir.get_next()
	while not file.is_empty():
		if file.begins_with("thermal_"):
			csv_file = "user://test_logs2/%s" % file
		file = dir.get_next()
	dir.list_dir_end()

	check_ok(not csv_file.is_empty(), "archivo CSV encontrado")

	var content := FileAccess.open(csv_file, FileAccess.READ)
	check_ok(content != null, "archivo CSV legible")

	var lines := content.get_as_text().strip_edges().split("\n")
	content.close()

	check_ok(lines.size() >= 3, "CSV tiene encabezado + 2 muestras")
	check(lines[0], "timestamp,cpu_ms,gpu_ms,temp_celsius", "encabezado CSV correcto")


func _test_sample_count() -> void:
	var logger := ThermalLogger.new(1.0, "user://test_logs3")
	logger.start()
	logger.log_sample(5.0, 6.0)
	logger.log_sample(7.0, 8.0)
	logger.log_sample(9.0, 10.0)
	logger.stop()

	check(logger.get_sample_count(), 3, "3 muestras registradas")


func _test_inactive_ignores_samples() -> void:
	var logger := ThermalLogger.new(1.0, "user://test_logs4")
	# No llamar start().
	logger.log_sample(5.0, 6.0)
	check(logger.get_sample_count(), 0, "sin start(), no se registran muestras")


func _test_stop_closes_file() -> void:
	var logger := ThermalLogger.new(1.0, "user://test_logs5")
	logger.start()
	logger.log_sample(5.0, 6.0)
	logger.stop()

	# Verificar que el archivo se puede leer (cerrado correctamente).
	var dir := DirAccess.open("user://test_logs5")
	dir.list_dir_begin()
	var csv_file := ""
	var file := dir.get_next()
	while not file.is_empty():
		if file.begins_with("thermal_"):
			csv_file = "user://test_logs5/%s" % file
		file = dir.get_next()
	dir.list_dir_end()

	var content := FileAccess.open(csv_file, FileAccess.READ)
	check_ok(content != null, "archivo CSV legible tras stop()")
	content.close()
