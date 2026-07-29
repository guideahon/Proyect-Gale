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

var scene_name: String
var device: String
var refresh_rate_hz: int
var duration_seconds: int
var _probe: FrameProbe
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

func add_sample(cpu_ms: float, gpu_ms: float) -> void:
	_probe.add_sample(cpu_ms, gpu_ms)
	if gpu_ms >= 0:
		_gpu_measurable = true

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

## Valida contra schemas/performance_report.schema.json vía SchemaValidator.
func write_report(path: String) -> Error:
	var report := generate_report()
	var validator := preload("res://core/mods/schema_validator.gd").new()
	var errors := validator.validate_by_name("performance_report", report)
	if not errors.is_empty():
		push_error("BenchmarkRunner: reporte no válido: %s" % errors[0])
		return ERR_BUG
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(report, "  "))
	file.close()
	return OK
