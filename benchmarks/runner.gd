## BenchmarkRunner — lógica de reporte de benchmarks.
#
# Clase reutilizable que acumula muestras de frame time vía FrameProbe
# y genera un reporte JSON que valida contra
# schemas/performance_report.schema.json.
#
# El entrypoint ejecutable es benchmarks/runner_entry.gd (SceneTree):
#     godot --headless --path . --script benchmarks/runner_entry.gd
#
# GPU no es medible en headless: pasa -1.0 como gpu_ms y el reporte
# publica null para gpu_ms con la semántica "no medido".

class_name BenchmarkRunner
extends RefCounted

## Escena a benchmarkear.
var scene_name: String

## Dispositivo (para el reporte).
var device: String

## Frecuencia de refresco objetivo.
var refresh_rate_hz: int

## Duración objetivo en segundos.
var duration_seconds: int

## FrameProbe compartido (evita duplicar matemática de percentiles).
var _probe: FrameProbe

## GPU medible o no.
var _gpu_measurable: bool = false


func _init(
	scene_name: String = "benchmark_empty",
	device: String = "headless",
	refresh_rate_hz: int = 120,
	duration_seconds: int = 60
) -> void:
	self.scene_name = scene_name
	self.device = device
	self.refresh_rate_hz = refresh_rate_hz
	self.duration_seconds = duration_seconds
	_probe = FrameProbe.new(0, 1000.0 / refresh_rate_hz)


## Agrega una muestra de frame time.
## gpu_ms = -1.0 significa "no medible" (headless sin GPU).
func add_sample(cpu_ms: float, gpu_ms: float) -> void:
	_probe.add_sample(cpu_ms, gpu_ms)
	if gpu_ms >= 0:
		_gpu_measurable = true


## Genera el reporte JSON.
func generate_report() -> Dictionary:
	var report := _probe.get_report()

	var gpu_p50: Variant = null
	var gpu_p95: Variant = null
	var gpu_p99: Variant = null
	if _gpu_measurable:
		gpu_p50 = report.gpu_p50
		gpu_p95 = report.gpu_p95
		gpu_p99 = report.gpu_p99

	var notes: String = "Benchmark ejecutado en modo headless."
	if not _gpu_measurable:
		notes += " GPU no medible en headless: gpu_ms es null."

	return {
		"scene": scene_name,
		"device": device,
		"refresh_rate_hz": refresh_rate_hz,
		"duration_minutes": float(duration_seconds) / 60.0,
		"cpu_ms": {
			"p50": report.cpu_p50,
			"p95": report.cpu_p95,
			"p99": report.cpu_p99,
		},
		"gpu_ms": {
			"p50": gpu_p50,
			"p95": gpu_p95,
			"p99": gpu_p99,
		},
		"draw_calls_p95": report.draw_calls,
		"visible_triangles_p95": report.visible_triangles,
		"dropped_frames": report.dropped_frames,
		"notes": notes,
	}


## Escribe el reporte a un archivo JSON.
## Valida contra el schema antes de escribir; si falla, devuelve ERR_BUG.
func write_report(path: String) -> Error:
	var report := generate_report()

	# Validación básica del reporte.
	var validation_err: Variant = _validate_report(report)
	if validation_err != null:
		push_error("BenchmarkRunner: reporte no válido: %s" % validation_err)
		return ERR_BUG

	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()

	file.store_string(JSON.stringify(report, "  "))
	file.close()
	return OK


## Validación mínima del reporte.
## Verifica campos obligatorios y tipos básicos.
## Devuelve null si pasa, o el mensaje de error.
func _validate_report(data: Dictionary) -> Variant:
	# Campos requeridos.
	var required: Array[String] = [
		"scene", "device", "refresh_rate_hz", "duration_minutes",
		"cpu_ms", "gpu_ms", "draw_calls_p95", "visible_triangles_p95",
		"dropped_frames"
	]
	for req: String in required:
		if not data.has(req):
			return "campo requerido faltante: %s" % req

	# scene debe ser un nombre válido.
	var valid_scenes: Array[String] = [
		"benchmark_empty", "benchmark_ocean", "benchmark_forest",
		"benchmark_village", "benchmark_combat", "benchmark_streaming",
		"benchmark_worst_case"
	]
	if not valid_scenes.has(data.scene):
		return "scene '%s' no está en la lista válida" % data.scene

	# refresh_rate_hz debe ser entero.
	if typeof(data.refresh_rate_hz) != TYPE_INT:
		return "refresh_rate_hz no es entero"

	# cpu_ms debe tener p50, p95, p99 numéricos.
	var cpu: Dictionary = data.get("cpu_ms", {})
	for key: String in ["p50", "p95", "p99"]:
		if not cpu.has(key):
			return "cpu_ms.%s faltante" % key
		if typeof(cpu[key]) != TYPE_FLOAT:
			return "cpu_ms.%s no es número" % key

	# gpu_ms puede tener nulls.
	var gpu: Dictionary = data.get("gpu_ms", {})
	for key: String in ["p50", "p95", "p99"]:
		if not gpu.has(key):
			return "gpu_ms.%s faltante" % key
		var val: Variant = gpu[key]
		if val != null and typeof(val) != TYPE_FLOAT:
			return "gpu_ms.%s no es número ni null" % key

	# draw_calls_p95 puede ser null o entero.
	var dc: Variant = data.get("draw_calls_p95")
	if dc != null and typeof(dc) != TYPE_INT:
		return "draw_calls_p95 no es entero ni null"

	# visible_triangles_p95 puede ser null o entero.
	var vt: Variant = data.get("visible_triangles_p95")
	if vt != null and typeof(vt) != TYPE_INT:
		return "visible_triangles_p95 no es entero ni null"

	# dropped_frames debe ser entero.
	if typeof(data.dropped_frames) != TYPE_INT:
		return "dropped_frames no es entero"

	return null
