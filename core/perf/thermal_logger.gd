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

## Tiempo de la última muestra (segundos).
var _last_sample_time: float = -1.0

## Umbral mínimo entre muestras (segundos).
var _min_interval: float = 0.0


func _init(interval_seconds: float = 5.0, log_dir: String = "user://logs") -> void:
	self.interval_seconds = interval_seconds
	self.log_dir = log_dir
	self._min_interval = interval_seconds


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
	_last_sample_time = -1.0


## Detiene el logger, hace flush y cierra el archivo.
func stop() -> void:
	_flush()
	_active = false
	if _current_file != null:
		_current_file.close()
		_current_file = null


## Escribe una muestra de rendimiento si pasó suficiente tiempo desde la última.
## Si `force` es true, se escribe sin verificar el intervalo.
func log_sample(cpu_ms: float, gpu_ms: float, temp_celsius: float = -1.0, force: bool = false) -> void:
	if not _active:
		return

	var now := Time.get_ticks_msec() / 1000.0

	# Respetar el intervalo entre muestras.
	if not force and _last_sample_time >= 0 and (now - _last_sample_time) < _min_interval:
		return

	if _current_file == null:
		_current_file = _open_log_file()
		if _current_file == null:
			return

	var timestamp := now
	var line := "%.3f,%.2f,%.2f,%.1f\n" % [timestamp, cpu_ms, gpu_ms, temp_celsius]
	_current_file.store_string(line)
	_sample_count += 1
	_last_sample_time = now

	# Flush periódico cada 10 muestras para no perder datos en crash.
	if _sample_count % 10 == 0:
		_flush()


## Fuerza un flush del archivo actual.
func _flush() -> void:
	if _current_file != null:
		_current_file.store_string("")  # trigger flush
		_current_file.flush()


## Devuelve el número de muestras escritas.
func get_sample_count() -> int:
	return _sample_count


## Devuelve el path del archivo actual (para tests).
func get_current_file_path() -> String:
	if _current_file != null:
		return _current_file.get_path()
	return ""


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
