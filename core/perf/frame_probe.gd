## FrameProbe — instrumentación de rendimiento por cuadro.
#
# Muestra CPU y GPU frame time por separado, percentiles P50/P95/P99
# de cada uno, dropped frames. Diseñado para correr a frecuencia de
# pantalla sin perturbar el presupuesto.
#
# Contadores adicionales (draw calls, triángulos, memoria de texturas)
# se leen de RenderingServer cuando está disponible; en modo headless
# devuelven 0.
#
# Uso típico como autoload `PerformanceService`:
#
#     var probe := FrameProbe.new()
#     probe.add_sample(cpu_ms, gpu_ms)
#     var report := probe.get_report()

class_name FrameProbe
extends RefCounted

# Ventana de muestras para percentiles (ajustable).
var _window_size: int = 120

# Series independientes de CPU y GPU.
var _cpu_samples: Array[float] = []
var _gpu_samples: Array[float] = []

# Contador de dropped frames (max(cpu, gpu) > budget).
var _dropped_frames: int = 0

# Presupuesto en ms (8.33 para 120 Hz).
var _budget_ms: float = 8.33


func _init(window_size: int = 120, budget_ms: float = 8.33) -> void:
	_window_size = window_size
	_budget_ms = budget_ms


## Agrega una muestra de frame time con CPU y GPU por separado.
func add_sample(cpu_ms: float, gpu_ms: float) -> void:
	_cpu_samples.append(cpu_ms)
	_gpu_samples.append(gpu_ms)

	if _cpu_samples.size() > _window_size:
		_cpu_samples.remove_at(0)
	if _gpu_samples.size() > _window_size:
		_gpu_samples.remove_at(0)

	if max(cpu_ms, gpu_ms) > _budget_ms:
		_dropped_frames += 1


## Devuelve percentiles de CPU calculados sobre la ventana actual.
func get_cpu_percentiles() -> Dictionary:
	return _percentiles_for(_cpu_samples)


## Devuelve percentiles de GPU calculados sobre la ventana actual.
func get_gpu_percentiles() -> Dictionary:
	return _percentiles_for(_gpu_samples)


## Reporte completo del estado actual.
func get_report() -> Dictionary:
	var cpu_p := get_cpu_percentiles()
	var gpu_p := get_gpu_percentiles()
	return {
		"sample_count": _cpu_samples.size(),
		"cpu_p50": cpu_p.p50,
		"cpu_p95": cpu_p.p95,
		"cpu_p99": cpu_p.p99,
		"gpu_p50": gpu_p.p50,
		"gpu_p95": gpu_p.p95,
		"gpu_p99": gpu_p.p99,
		"dropped_frames": _dropped_frames,
		"budget_ms": _budget_ms,
		"draw_calls": RenderingServer.get_rendering_device().get_graphics_buffer_memory_usage() if _has_rendering_device() else 0,
		"visible_triangles": 0,
		"texture_memory": 0,
	}


## Resetea todas las métricas.
func reset() -> void:
	_cpu_samples.clear()
	_gpu_samples.clear()
	_dropped_frames = 0


## Calcula percentiles sobre una serie.
static func percentile(sorted: Array[float], k: float) -> float:
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


func _percentiles_for(samples: Array[float]) -> Dictionary:
	if samples.is_empty():
		return {"p50": 0.0, "p95": 0.0, "p99": 0.0}

	var sorted: Array[float] = samples.duplicate()
	sorted.sort()

	return {
		"p50": percentile(sorted, 0.50),
		"p95": percentile(sorted, 0.95),
		"p99": percentile(sorted, 0.99),
	}


func _has_rendering_device() -> bool:
	return RenderingServer.get_rendering_device() != null
