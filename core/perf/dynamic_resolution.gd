## DynamicResolution — ajuste dinámico de render scale con histéresis.
#
# Evita oscilaciones rápidas ("sawtooth") limitando la frecuencia de cambio
# y aplicando umbrales distintos para subir y bajar la resolución.
#
# Uso típico:
#
#     var dr := DynamicResolution.new(min_scale=0.5, max_scale=1.0)
#     dr.feed(frame_time_ms)
#     var new_scale := dr.current_scale

class_name DynamicResolution
extends RefCounted

## Escala mínima permitida.
var min_scale: float

## Escala máxima permitida.
var max_scale: float

## Escala actual.
var current_scale: float

## Umbral para bajar la resolución (ms). Se baja si frame time > este valor.
var threshold_down: float

## Umbral para subir la resolución (ms). Se sube si frame time < este valor
## (histéresis: más bajo que threshold_down para evitar oscilación).
var threshold_up: float

## Paso de cambio por ajuste.
var step: float

## Intervalo mínimo entre ajustes (segundos).
var cooldown_seconds: float

## Máximo de ajustes permitidos por ventana.
var max_adjusts_per_window: int

## Ventana para contar ajustes (segundos).
var _adjust_window: float

## Tiempo del último ajuste (en segundos).
var _last_adjust_time: float = -1.0

## Contador de ajustes en la ventana actual.
var _adjust_count: int = 0

## Inicio de la ventana actual.
var _adjust_window_start: float = -1.0


func _init(
	min_scale: float = 0.5,
	max_scale: float = 1.0,
	threshold_down: float = 7.0,
	threshold_up: float = 5.0,
	step: float = 0.05,
	cooldown_seconds: float = 1.0,
	adjust_window: float = 10.0,
	max_adjusts: int = 3
) -> void:
	self.min_scale = min_scale
	self.max_scale = max_scale
	self.current_scale = max_scale
	self.threshold_down = threshold_down
	self.threshold_up = threshold_up
	self.step = step
	self.cooldown_seconds = cooldown_seconds
	self._adjust_window = adjust_window
	self.max_adjusts_per_window = max_adjusts


## Alimenta una muestra de frame time y ajusta la resolución si corresponde.
## `current_time` es el tiempo en segundos del juego (para cooldowns).
## Si no se pasa, se toma de `Time.get_ticks_msec()`.
func feed(frame_time_ms: float, current_time: float = -1.0) -> void:
	# Tiempo obligatorio: si no se pasa, usar el reloj del sistema.
	var t: float
	if current_time >= 0:
		t = current_time
	else:
		t = Time.get_ticks_msec() / 1000.0

	# Cooldown: no ajustar si pasó menos de cooldown_seconds.
	if t - _last_adjust_time < cooldown_seconds:
		return

	# Resetear contador si la ventana expiró.
	if t - _adjust_window_start > _adjust_window:
		_adjust_count = 0
		_adjust_window_start = t

	# Límite de cambios por ventana.
	if _adjust_count >= max_adjusts_per_window:
		return

	# Bajar resolución si el frame time supera el umbral alto.
	if frame_time_ms > threshold_down and current_scale > min_scale:
		current_scale = max(current_scale - step, min_scale)
		_last_adjust_time = t
		_adjust_count += 1

	# Subir resolución si el frame time está por debajo del umbral bajo.
	elif frame_time_ms < threshold_up and current_scale < max_scale:
		current_scale = min(current_scale + step, max_scale)
		_last_adjust_time = t
		_adjust_count += 1


## Resetea el estado (útil para tests).
func reset() -> void:
	current_scale = max_scale
	_last_adjust_time = -1.0
	_adjust_count = 0
	_adjust_window_start = -1.0
