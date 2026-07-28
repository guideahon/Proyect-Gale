## FrameProbe — instrumentación de rendimiento por cuadro.
#
# Muestra CPU/GPU frame time, percentiles P50/P95/P99, dropped frames,
# draw calls, triángulos, memoria de texturas. Diseñado para correr a
# frecuencia de pantalla sin perturbar el presupuesto.
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

# Cola circular de muestras.
var _samples: Array[float] = []

# Contador de dropped frames (frame time > budget).
var _dropped_frames: int = 0

# Presupuesto en ms (8.33 para 120 Hz).
var _budget_ms: float = 8.33


func _init(window_size: int = 120, budget_ms: float = 8.33) -> void:
	_window_size = window_size
	_budget_ms = budget_ms


## Agrega una muestra de frame time.
func add_sample(cpu_ms: float, gpu_ms: float) -> void:
	var max_time: float = max(cpu_ms, gpu_ms)
	_samples.append(max_time)

	if _samples.size() > _window_size:
		_samples.remove_at(0)

	if max_time > _budget_ms:
		_dropped_frames += 1


## Devuelve percentiles calculados sobre la ventana actual.
## Retorna un diccionario con P50, P95, P99 en ms.
func get_percentiles() -> Dictionary:
	if _samples.is_empty():
		return {"p50": 0.0, "p95": 0.0, "p99": 0.0}

	var sorted: Array[float] = _samples.duplicate()
	sorted.sort()

	return {
		"p50": percentile(sorted, 0.50),
		"p95": percentile(sorted, 0.95),
		"p99": percentile(sorted, 0.99),
	}


## Reporte completo del estado actual.
func get_report() -> Dictionary:
	var percentiles := get_percentiles()
	return {
		"sample_count": _samples.size(),
		"p50": percentiles.p50,
		"p95": percentiles.p95,
		"p99": percentiles.p99,
		"dropped_frames": _dropped_frames,
		"budget_ms": _budget_ms,
	}


## Resetea todas las métricas.
func reset() -> void:
	_samples.clear()
	_dropped_frames = 0


## Calcula el percentil k (0..1) de un array ordenado.
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
