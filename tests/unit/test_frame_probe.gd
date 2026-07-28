## Tests de `core/perf/frame_probe.gd`.
##
## Calcula percentiles sobre series sintéticas de valor conocido.
extends "res://tests/framework/test_case.gd"

const FrameProbe := preload("res://core/perf/frame_probe.gd")

func run() -> void:
	_test_percentile_basic()
	_test_percentile_edge_cases()
	_test_probe_add_sample()
	_test_probe_window_limit()
	_test_probe_dropped_frames()
	_test_probe_report()
	_test_probe_reset()


func _test_percentile_basic() -> void:
	# Serie de 10 valores: 1..10.
	var series: Array[float] = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]

	# P50 de 10 valores = valor en posición 4.5 = 5.5
	check(FrameProbe.percentile(series, 0.50), 5.5, "P50 de 1..10")

	# P95 = posición 8.55 → interpolación entre 9 y 10 ≈ 9.55
	check_approx(FrameProbe.percentile(series, 0.95), 9.55, 0.01, "P95 de 1..10")

	# P99 = posición 9.01 → interpolación ≈ 9.91
	check_approx(FrameProbe.percentile(series, 0.99), 9.91, 0.01, "P99 de 1..10")


func _test_percentile_edge_cases() -> void:
	# Array vacío.
	check(FrameProbe.percentile([], 0.50), 0.0, "percentil de array vacío")

	# Un solo elemento.
	var single: Array[float] = [42.0]
	check(FrameProbe.percentile(single, 0.50), 42.0, "percentil de un elemento")
	check(FrameProbe.percentile(single, 0.99), 42.0, "P99 de un elemento")

	# Dos elementos.
	var two: Array[float] = [10.0, 20.0]
	check(FrameProbe.percentile(two, 0.0), 10.0, "P0 de dos elementos")
	check(FrameProbe.percentile(two, 1.0), 20.0, "P100 de dos elementos")
	check(FrameProbe.percentile(two, 0.5), 15.0, "P50 de dos elementos")


func _test_probe_add_sample() -> void:
	var probe := FrameProbe.new(10)
	probe.add_sample(5.0, 3.0)
	probe.add_sample(4.0, 6.0)

	var report := probe.get_report()
	check(report.sample_count, 2, "dos muestras registradas")
	# max(5,3)=5, max(4,6)=6 → P50 = 5.5
	check(report.p50, 5.5, "P50 correcto")


func _test_probe_window_limit() -> void:
	var probe := FrameProbe.new(3)

	# Agrego 5 muestras con ventana de 3: solo quedan las últimas 3.
	probe.add_sample(1.0, 1.0)
	probe.add_sample(2.0, 2.0)
	probe.add_sample(3.0, 3.0)
	probe.add_sample(4.0, 4.0)
	probe.add_sample(5.0, 5.0)

	var report := probe.get_report()
	check(report.sample_count, 3, "ventana limitada a 3")
	# Últimas 3: 3, 4, 5 → P50 = 4.0
	check(report.p50, 4.0, "P50 de las últimas 3 muestras")


func _test_probe_dropped_frames() -> void:
	var probe := FrameProbe.new(10, 8.0)

	probe.add_sample(5.0, 6.0)   # max=6 < 8 → ok
	probe.add_sample(7.0, 9.0)   # max=9 > 8 → dropped
	probe.add_sample(8.5, 7.5)   # max=8.5 > 8 → dropped
	probe.add_sample(4.0, 3.0)   # max=4 < 8 → ok

	var report := probe.get_report()
	check(report.dropped_frames, 2, "dos dropped frames")


func _test_probe_report() -> void:
	var probe := FrameProbe.new()
	var report := probe.get_report()

	check_ok(report.has("sample_count"), "reporte tiene sample_count")
	check_ok(report.has("p50"), "reporte tiene p50")
	check_ok(report.has("p95"), "reporte tiene p95")
	check_ok(report.has("p99"), "reporte tiene p99")
	check_ok(report.has("dropped_frames"), "reporte tiene dropped_frames")
	check_ok(report.has("budget_ms"), "reporte tiene budget_ms")


func _test_probe_reset() -> void:
	var probe := FrameProbe.new(10, 8.0)
	probe.add_sample(9.0, 9.0)  # dropped
	probe.add_sample(5.0, 5.0)

	probe.reset()
	var report := probe.get_report()
	check(report.sample_count, 0, "reset limpia muestras")
	check(report.dropped_frames, 0, "reset limpia dropped")
