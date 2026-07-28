## Tests de `core/perf/dynamic_resolution.gd`.
##
## Con una serie sintética de frame times oscilando alrededor del umbral,
## la resolución cambia como máximo N veces en 10 segundos.
extends "res://tests/framework/test_case.gd"

const DynamicResolution := preload("res://core/perf/dynamic_resolution.gd")

func run() -> void:
	_test_initial_scale()
	_test_scale_goes_down()
	_test_scale_goes_up()
	_test_clamped_to_min()
	_test_clamped_to_max()
	_test_hysteresis_no_oscillation()
	_test_cooldown_prevents_rapid_change()
	_test_adjust_limit_per_window()
	_test_max_adjusts_parameter()
	_test_feed_without_time_uses_system_clock()
	_test_reset()


func _test_initial_scale() -> void:
	var dr := DynamicResolution.new()
	check(dr.current_scale, 1.0, "escala inicial es max_scale")


func _test_scale_goes_down() -> void:
	var dr := DynamicResolution.new(0.5, 1.0, 7.0, 5.0, 0.05)

	dr.feed(8.0, 0.0)
	check_approx(dr.current_scale, 0.95, 0.001, "baja un paso")

	dr.feed(8.0, 2.0)
	check_approx(dr.current_scale, 0.9, 0.001, "baja otro paso")


func _test_scale_goes_up() -> void:
	var dr := DynamicResolution.new(0.5, 1.0, 7.0, 5.0, 0.05)

	dr.feed(8.0, 0.0)
	dr.feed(8.0, 1.0)
	dr.feed(4.0, 2.0)
	check_approx(dr.current_scale, 0.95, 0.001, "sube un paso")


func _test_clamped_to_min() -> void:
	var dr := DynamicResolution.new(0.5, 1.0, 7.0, 5.0, 0.1)

	for i in range(20):
		dr.feed(8.0, float(i) * 2.0)

	check_approx(dr.current_scale, 0.5, 0.001, "clamped a min_scale")


func _test_clamped_to_max() -> void:
	var dr := DynamicResolution.new(0.5, 1.0, 7.0, 5.0, 0.1)

	for i in range(5):
		dr.feed(8.0, float(i) * 2.0)

	for i in range(20):
		dr.feed(4.0, float(10 + i) * 2.0)

	check(dr.current_scale, 1.0, "clamped a max_scale")


func _test_hysteresis_no_oscillation() -> void:
	var dr := DynamicResolution.new(0.5, 1.0, 7.0, 5.0, 0.05)

	for i in range(20):
		var ft := 5.5 if i % 2 == 0 else 6.5
		dr.feed(ft, float(i) * 2.0)

	check(dr.current_scale, 1.0, "histéresis: no cambia en zona intermedia")


func _test_cooldown_prevents_rapid_change() -> void:
	var dr := DynamicResolution.new(0.5, 1.0, 7.0, 5.0, 0.1, 1.0)

	dr.feed(8.0, 0.0)
	var after_first := dr.current_scale

	dr.feed(8.0, 0.5)
	check(dr.current_scale, after_first, "cooldown previene cambio rápido")


func _test_adjust_limit_per_window() -> void:
	var dr := DynamicResolution.new(0.5, 1.0, 7.0, 5.0, 0.1, 0.5, 10.0, 3)

	dr.feed(8.0, 0.0)
	dr.feed(8.0, 1.0)
	dr.feed(8.0, 2.0)
	var after_three := dr.current_scale

	dr.feed(8.0, 3.0)
	check(dr.current_scale, after_three, "límite de 3 ajustes por ventana")


func _test_max_adjusts_parameter() -> void:
	# max_adjusts=1: solo un ajuste permitido.
	var dr := DynamicResolution.new(0.5, 1.0, 7.0, 5.0, 0.1, 0.5, 10.0, 1)

	dr.feed(8.0, 0.0)
	var after_first := dr.current_scale

	dr.feed(8.0, 1.0)
	check(dr.current_scale, after_first, "max_adjusts=1 bloquea segundo ajuste")


func _test_feed_without_time_uses_system_clock() -> void:
	# feed() sin current_time debe usar Time.get_ticks_msec() y no crashear.
	var dr := DynamicResolution.new(0.5, 1.0, 7.0, 5.0, 0.05)

	# Llamamos sin tiempo: no debe fallar.
	dr.feed(8.0)
	check_ok(true, "feed sin tiempo no crashea")

	# La escala debe haber bajado (no hay cooldown porque _last_adjust_time=-1).
	check_ok(dr.current_scale < 1.0, "feed sin tiempo ajusta la escala")


func _test_reset() -> void:
	var dr := DynamicResolution.new(0.5, 1.0, 7.0, 5.0, 0.1)

	dr.feed(8.0, 0.0)
	dr.reset()
	check(dr.current_scale, 1.0, "reset restaura max_scale")
