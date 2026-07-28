## BenchmarkRunner — lógica de reporte de benchmarks.
#
# Clase reutilizable que acumula muestras de frame time vía FrameProbe
# y genera un reporte JSON que valida contra
# schemas/performance_report.schema.json.
#
# El entrypoint ejecutable es benchmarks/runner_entry.gd (SceneTree):
#     godot --headless --path . --script benchmarks/runner_entry.gd

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
func add_sample(cpu_ms: float, gpu_ms: float) -> void:
	_probe.add_sample(cpu_ms, gpu_ms)


## Genera el reporte JSON.
func generate_report() -> Dictionary:
	var report := _probe.get_report()

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
			"p50": report.gpu_p50,
			"p95": report.gpu_p95,
			"p99": report.gpu_p99,
		},
		"draw_calls_p95": report.draw_calls,
		"visible_triangles_p95": report.visible_triangles,
		"dropped_frames": report.dropped_frames,
		"notes": "Benchmark ejecutado en modo headless.",
	}


## Escribe el reporte a un archivo JSON.
func write_report(path: String) -> Error:
	var report := generate_report()
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()

	file.store_string(JSON.stringify(report, "  "))
	file.close()
	return OK
