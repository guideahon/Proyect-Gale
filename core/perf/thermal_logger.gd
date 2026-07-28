## ThermalLogger — muestreo periódico de temperatura y rendimiento.
#
# Escribe métricas a `user://logs/` en intervalos configurables.
# El archivo resultante es parseable y validable por tests.
#
# Uso típico como autoload `PerformanceService`:
#
#     var logger := ThermalLogger.new(interval_seconds=5)
#     logger.start()
#     logger.log_sample(cpu_ms, gpu_ms, temp_celsius)
#     logger.stop()

class_name ThermalLogger
extends RefCounted

## Intervalo entre muestras (segundos).
var interval_seconds: float

## Directorio de logs.
var log_dir: String

## Archivo actual de log.
var _current_file: FileAccess = null

## Activo o no.
var _active: bool = false

## Contador de muestras escritas.
var _sample_count: int = 0


func _init(interval_seconds: float = 5.0, log_dir: String = "user://logs") -> void:
	self.interval_seconds = interval_seconds
	self.log_dir = log_dir


## Inicia el logger: crea el directorio si no existe.
func start() -> void:
	var dir := DirAccess.open(log_dir)
	if dir == null:
		# Intentar crear el directorio.
		var err := DirAccess.make_dir_recursive_absolute(log_dir)
		if err != OK:
			push_error("ThermalLogger: no se pudo crear %s (error %d)" % [log_dir, err])
			return
	_active = true
	_sample_count = 0


## Detiene el logger y cierra el archivo.
func stop() -> void:
	_active = false
	if _current_file != null:
		_current_file.close()
		_current_file = null


## Escribe una muestra de rendimiento.
func log_sample(cpu_ms: float, gpu_ms: float, temp_celsius: float = -1.0) -> void:
	if not _active:
		return

	if _current_file == null:
		_current_file = _open_log_file()
		if _current_file == null:
			return

	var timestamp := Time.get_ticks_msec() / 1000.0
	var line := "%.3f,%.2f,%.2f,%.1f\n" % [timestamp, cpu_ms, gpu_ms, temp_celsius]
	_current_file.store_string(line)
	_sample_count += 1


## Devuelve el número de muestras escritas.
func get_sample_count() -> int:
	return _sample_count


func _open_log_file() -> FileAccess:
	var filename := "thermal_%d.csv" % Time.get_unix_time_from_system()
	var path := "%s/%s" % [log_dir, filename]

	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("ThermalLogger: no se pudo abrir %s" % path)
		return null

	# Escribir encabezado CSV.
	file.store_string("timestamp,cpu_ms,gpu_ms,temp_celsius\n")
	return file
