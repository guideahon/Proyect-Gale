## FrameProbe — instrumentación de rendimiento por cuadro.
#
# Muestra CPU y GPU frame time por separado, percentiles P50/P95/P99
# de cada uno, dropped frames. Diseñado para correr a frecuencia de
# pantalla sin perturbar el presupuesto.
#
# draw_calls, visible_triangles y texture_memory se leen de
# RenderingServer.get_rendering_info() cuando está disponible; en
# modo headless o con renderer sin soporte devuelven null (no medido).
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
## draw_calls, visible_triangles y texture_memory son null cuando no se
## pueden medir (headless, renderer sin soporte, etc.).
func get_report() -> Dictionary:
	var cpu_p := get_cpu_percentiles()
	var gpu_p := get_gpu_percentiles()
	var rendering_info := _get_rendering_info()

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
		"draw_calls": rendering_info.draw_calls,
		"visible_triangles": rendering_info.triangles,
		"texture_memory": rendering_info.texture_mem,
	}


## Resetea todas las métricas.
func reset() -> void:
	_cpu_samples.clear()
	_gpu_samples.clear()
	_dropped_frames = 0


## Intenta leer RenderingServer.get_rendering_info(). Devuelve nulls si no
## está disponible (headless, renderer sin soporte, etc.).
func _get_rendering_info() -> Dictionary:
	var draw_calls: Variant = null
	var triangles: Variant = null
	var texture_mem: Variant = null

	# get_rendering_info() requiere un índice en Godot 4.7.1.
	# En headless pueden devolver valores inválidos; verificamos.
	draw_calls = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	triangles = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
	texture_mem = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TEXTURE_MEM_USED)

	# Si todos son 0 en headless, marcar como no medido.
	if draw_calls == 0 and triangles == 0 and texture_mem == 0:
		return {"draw_calls": null, "triangles": null, "texture_mem": null}

	return {
		"draw_calls": draw_calls,
		"triangles": triangles,
		"texture_mem": texture_mem,
	}


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
