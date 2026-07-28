## DynamicResolution — ajuste dinámico de render scale con histérisis.
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

## Umbral para bajar la resolución (ms). Se baja si P95 > este valor.
var threshold_down: float

## Umbral para subir la resolución (ms). Se sube si P95 < este valor
## (histéresis: más bajo que threshold_down para evitar oscilación).
var threshold_up: float

## Paso de cambio por ajuste.
var step: float

## Intervalo mínimo entre ajustes (segundos).
var cooldown_seconds: float

## Tiempo del último ajuste.
var _last_adjust_time: float = -1.0

## Contador de ajustes en una ventana de tiempo.
var _adjust_count: int = 0
var _adjust_window_start: float = -1.0

## Ventana para contar ajustes (segundos).
var _adjust_window: float = 10.0


func _init(
	min_scale: float = 0.5,
	max_scale: float = 1.0,
	threshold_down: float = 7.0,
	threshold_up: float = 5.0,
	step: float = 0.05,
	cooldown_seconds: float = 1.0,
	adjust_window: float = 10.0
) -> void:
	self.min_scale = min_scale
	self.max_scale = max_scale
	self.current_scale = max_scale
	self.threshold_down = threshold_down
	self.threshold_up = threshold_up
	self.step = step
	self.cooldown_seconds = cooldown_seconds
	self._adjust_window = adjust_window


## Alimenta una muestra de frame time y ajusta la resolución si corresponde.
## `current_time` es el tiempo en segundos del juego (para cooldowns).
func feed(frame_time_ms: float, current_time: float = -1.0) -> void:
	# Si no hay cooldown activo, no ajustar.
	if current_time >= 0:
		if current_time - _last_adjust_time < cooldown_seconds:
			return

		# Límite de cambios por ventana: máximo 3 ajustes en 10 segundos.
		if current_time - _adjust_window_start > _adjust_window:
			_adjust_count = 0
			_adjust_window_start = current_time

		if _adjust_count >= 3:
			return

	# Bajar resolución si el frame time supera el umbral alto.
	if frame_time_ms > threshold_down and current_scale > min_scale:
		current_scale = max(current_scale - step, min_scale)
		_last_adjust_time = current_time
		_adjust_count += 1

	# Subir resolución si el frame time está por debajo del umbral bajo.
	elif frame_time_ms < threshold_up and current_scale < max_scale:
		current_scale = min(current_scale + step, max_scale)
		_last_adjust_time = current_time
		_adjust_count += 1


## Resetea el estado (útil para tests).
func reset() -> void:
	current_scale = max_scale
	_last_adjust_time = -1.0
	_adjust_count = 0
	_adjust_window_start = -1.0
