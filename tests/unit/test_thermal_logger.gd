## Tests de `core/perf/thermal_logger.gd`.
##
## Verifica que genera archivos CSV parseables con la estructura esperada,
## que respeta el intervalo entre muestras, y que flush() funciona.
extends "res://tests/framework/test_case.gd"

const ThermalLogger := preload("res://core/perf/thermal_logger.gd")

func run() -> void:
	_test_logger_creates_csv()
	_test_csv_structure()
	_test_sample_count()
	_test_inactive_ignores_samples()
	_test_stop_closes_file()
	_test_interval_respected()
	_test_flush_on_stop()


func _test_logger_creates_csv() -> void:
	var log_dir := "user://test_logs_t1"
	_cleanup_dir(log_dir)

	var logger := ThermalLogger.new(1.0, log_dir)
	logger.start()
	logger.log_sample(5.0, 6.0, 42.0, true)
	logger.stop()

	var dir := DirAccess.open(log_dir)
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
	_cleanup_dir(log_dir)


func _test_csv_structure() -> void:
	var log_dir := "user://test_logs_t2"
	_cleanup_dir(log_dir)

	var logger := ThermalLogger.new(1.0, log_dir)
	logger.start()
	logger.log_sample(3.0, 4.0, 38.5, true)
	logger.log_sample(7.0, 8.0, 45.0, true)
	logger.stop()

	var dir := DirAccess.open(log_dir)
	dir.list_dir_begin()
	var csv_file := ""
	var file := dir.get_next()
	while not file.is_empty():
		if file.begins_with("thermal_"):
			csv_file = "%s/%s" % [log_dir, file]
		file = dir.get_next()
	dir.list_dir_end()

	check_ok(not csv_file.is_empty(), "archivo CSV encontrado")

	var content := FileAccess.open(csv_file, FileAccess.READ)
	check_ok(content != null, "archivo CSV legible")

	var lines := content.get_as_text().strip_edges().split("\n")
	content.close()

	check_ok(lines.size() >= 3, "CSV tiene encabezado + 2 muestras")
	check(lines[0], "timestamp,cpu_ms,gpu_ms,temp_celsius", "encabezado CSV correcto")
	_cleanup_dir(log_dir)


func _test_sample_count() -> void:
	var log_dir := "user://test_logs_t3"
	_cleanup_dir(log_dir)

	var logger := ThermalLogger.new(1.0, log_dir)
	logger.start()
	logger.log_sample(5.0, 6.0, -1.0, true)
	logger.log_sample(7.0, 8.0, -1.0, true)
	logger.log_sample(9.0, 10.0, -1.0, true)
	logger.stop()

	check(logger.get_sample_count(), 3, "3 muestras registradas")
	_cleanup_dir(log_dir)


func _test_inactive_ignores_samples() -> void:
	var logger := ThermalLogger.new(1.0, "user://test_logs_t4")
	# No llamar start().
	logger.log_sample(5.0, 6.0, -1.0, true)
	check(logger.get_sample_count(), 0, "sin start(), no se registran muestras")


func _test_stop_closes_file() -> void:
	var log_dir := "user://test_logs_t5"
	_cleanup_dir(log_dir)

	var logger := ThermalLogger.new(1.0, log_dir)
	logger.start()
	logger.log_sample(5.0, 6.0, -1.0, true)
	logger.stop()

	var dir := DirAccess.open(log_dir)
	dir.list_dir_begin()
	var csv_file := ""
	var file := dir.get_next()
	while not file.is_empty():
		if file.begins_with("thermal_"):
			csv_file = "%s/%s" % [log_dir, file]
		file = dir.get_next()
	dir.list_dir_end()

	var content := FileAccess.open(csv_file, FileAccess.READ)
	check_ok(content != null, "archivo CSV legible tras stop()")
	content.close()
	_cleanup_dir(log_dir)


func _test_interval_respected() -> void:
	var log_dir := "user://test_logs_t6"
	_cleanup_dir(log_dir)

	# interval=1.0: sin force, las muestras rápidas se ignoran.
	var logger := ThermalLogger.new(1.0, log_dir)
	logger.start()
	logger.log_sample(5.0, 6.0, -1.0, false)  # primera: siempre se escribe
	logger.log_sample(7.0, 8.0, -1.0, false)  # misma llamada, < 1s: ignorada
	logger.log_sample(9.0, 10.0, -1.0, false) # misma llamada, < 1s: ignorada
	logger.stop()

	check(logger.get_sample_count(), 1, "intervalo respeta: solo 1 muestra sin force")
	_cleanup_dir(log_dir)


func _test_flush_on_stop() -> void:
	var log_dir := "user://test_logs_t7"
	_cleanup_dir(log_dir)

	var logger := ThermalLogger.new(1.0, log_dir)
	logger.start()
	for i in range(12):
		logger.log_sample(float(i), float(i + 1), -1.0, true)
	logger.stop()

	# Verificar que el archivo tiene todas las líneas.
	var dir := DirAccess.open(log_dir)
	dir.list_dir_begin()
	var csv_file := ""
	var file := dir.get_next()
	while not file.is_empty():
		if file.begins_with("thermal_"):
			csv_file = "%s/%s" % [log_dir, file]
		file = dir.get_next()
	dir.list_dir_end()

	var content := FileAccess.open(csv_file, FileAccess.READ)
	var lines := content.get_as_text().strip_edges().split("\n")
	content.close()

	# 1 encabezado + 12 muestras = 13 líneas.
	check_ok(lines.size() >= 13, "flush en stop: todas las 12 muestras presentes")
	_cleanup_dir(log_dir)


## Limpia un directorio de logs para tests determinísticos.
func _cleanup_dir(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var file := dir.get_next()
	while not file.is_empty():
		dir.remove("%s/%s" % [path, file])
		file = dir.get_next()
	dir.list_dir_end()
