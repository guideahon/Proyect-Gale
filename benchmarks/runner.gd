## BenchmarkRunner — ejecuta una escena de benchmark y escribe un reporte.
#
# Recorre un camino repetible, mide CPU/GPU frame time, draw calls,
# triángulos y dropped frames. Escribe un JSON que valida contra
# schemas/performance_report.schema.json.
#
# Uso:
#     godot --headless --path . --script benchmarks/runner.gd -- benchmark_empty

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

## Presupuesto en ms.
var budget_ms: float

## Series de muestras.
var _cpu_samples: Array[float] = []
var _gpu_samples: Array[float] = []

## Contador de dropped frames.
var _dropped_frames: int = 0

## Muestra actual.
var _current_sample: int = 0

## Muestras totales.
var _total_samples: int = 0


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
	self.budget_ms = 1000.0 / refresh_rate_hz
	self._total_samples = refresh_rate_hz * duration_seconds


## Agrega una muestra de frame time.
func add_sample(cpu_ms: float, gpu_ms: float) -> void:
	_cpu_samples.append(cpu_ms)
	_gpu_samples.append(gpu_ms)

	if max(cpu_ms, gpu_ms) > budget_ms:
		_dropped_frames += 1

	_current_sample += 1


## Genera el reporte JSON.
func generate_report() -> Dictionary:
	var cpu_p := _percentiles(_cpu_samples)
	var gpu_p := _percentiles(_gpu_samples)

	return {
		"scene": scene_name,
		"device": device,
		"refresh_rate_hz": refresh_rate_hz,
		"duration_minutes": float(duration_seconds) / 60.0,
		"cpu_ms": {
			"p50": cpu_p.p50,
			"p95": cpu_p.p95,
			"p99": cpu_p.p99,
		},
		"gpu_ms": {
			"p50": gpu_p.p50,
			"p95": gpu_p.p95,
			"p99": gpu_p.p99,
		},
		"draw_calls_p95": 0,
		"visible_triangles_p95": 0,
		"dropped_frames": _dropped_frames,
		"notes": "Benchmark ejecutado en modo headless; draw_calls y triangles no disponibles sin RenderingServer.",
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


static func _percentiles(samples: Array[float]) -> Dictionary:
	if samples.is_empty():
		return {"p50": 0.0, "p95": 0.0, "p99": 0.0}

	var sorted: Array[float] = samples.duplicate()
	sorted.sort()

	return {
		"p50": _percentile(sorted, 0.50),
		"p95": _percentile(sorted, 0.95),
		"p99": _percentile(sorted, 0.99),
	}


static func _percentile(sorted: Array[float], k: float) -> float:
	if sorted.is_empty():
		return 0.0
	if sorted.size() == 1:
		return sorted[0]

	var rank := k * (sorted.size() - 1)
	var lower := int(rank)
	var upper := lower + 1
	var frac := rank - lower

	if upper >= sorted.size():
		return sorted[lower]

	return sorted[lower] + frac * (sorted[upper] - sorted[lower])
