## Tests de `core/perf/frame_probe.gd`.
##
## Calcula percentiles sobre series sintéticas de valor conocido.
## Verifica que CPU y GPU se mantienen separados.
extends "res://tests/framework/test_case.gd"

const FrameProbe := preload("res://core/perf/frame_probe.gd")

func run() -> void:
	_test_percentile_basic()
	_test_percentile_edge_cases()
	_test_probe_separate_cpu_gpu()
	_test_probe_window_limit()
	_test_probe_dropped_frames()
	_test_probe_report_structure()
	_test_probe_reset()


func _test_percentile_basic() -> void:
	var series: Array[float] = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]

	check(FrameProbe.percentile(series, 0.50), 5.5, "P50 de 1..10")
	check_approx(FrameProbe.percentile(series, 0.95), 9.55, 0.01, "P95 de 1..10")
	check_approx(FrameProbe.percentile(series, 0.99), 9.91, 0.01, "P99 de 1..10")


func _test_percentile_edge_cases() -> void:
	check(FrameProbe.percentile([], 0.50), 0.0, "percentil de array vacío")

	var single: Array[float] = [42.0]
	check(FrameProbe.percentile(single, 0.50), 42.0, "percentil de un elemento")
	check(FrameProbe.percentile(single, 0.99), 42.0, "P99 de un elemento")

	var two: Array[float] = [10.0, 20.0]
	check(FrameProbe.percentile(two, 0.0), 10.0, "P0 de dos elementos")
	check(FrameProbe.percentile(two, 1.0), 20.0, "P100 de dos elementos")
	check(FrameProbe.percentile(two, 0.5), 15.0, "P50 de dos elementos")


func _test_probe_separate_cpu_gpu() -> void:
	var probe := FrameProbe.new(10)

	# CPU bajo, GPU alto.
	probe.add_sample(3.0, 7.0)
	probe.add_sample(4.0, 8.0)

	var cpu_p := probe.get_cpu_percentiles()
	var gpu_p := probe.get_gpu_percentiles()

	# CPU: 3, 4 → P50 = 3.5
	check_approx(cpu_p.p50, 3.5, 0.01, "CPU P50 separado")
	# GPU: 7, 8 → P50 = 7.5
	check_approx(gpu_p.p50, 7.5, 0.01, "GPU P50 separado")

	check_ok(cpu_p.p50 != gpu_p.p50, "CPU y GPU percentiles son distintos")


func _test_probe_window_limit() -> void:
	var probe := FrameProbe.new(3)

	probe.add_sample(1.0, 2.0)
	probe.add_sample(2.0, 3.0)
	probe.add_sample(3.0, 4.0)
	probe.add_sample(4.0, 5.0)
	probe.add_sample(5.0, 6.0)

	var report := probe.get_report()
	check(report.sample_count, 3, "ventana limitada a 3")
	# CPU últimas 3: 3, 4, 5 → P50 = 4.0
	check_approx(report.cpu_p50, 4.0, 0.01, "CPU P50 de últimas 3")
	# GPU últimas 3: 4, 5, 6 → P50 = 5.0
	check_approx(report.gpu_p50, 5.0, 0.01, "GPU P50 de últimas 3")


func _test_probe_dropped_frames() -> void:
	var probe := FrameProbe.new(10, 8.0)

	probe.add_sample(5.0, 6.0)   # max=6 < 8 → ok
	probe.add_sample(7.0, 9.0)   # max=9 > 8 → dropped
	probe.add_sample(8.5, 7.5)   # max=8.5 > 8 → dropped
	probe.add_sample(4.0, 3.0)   # max=4 < 8 → ok

	var report := probe.get_report()
	check(report.dropped_frames, 2, "dos dropped frames")


func _test_probe_report_structure() -> void:
	var probe := FrameProbe.new()
	var report := probe.get_report()

	check_ok(report.has("sample_count"), "reporte tiene sample_count")
	check_ok(report.has("cpu_p50"), "reporte tiene cpu_p50")
	check_ok(report.has("cpu_p95"), "reporte tiene cpu_p95")
	check_ok(report.has("cpu_p99"), "reporte tiene cpu_p99")
	check_ok(report.has("gpu_p50"), "reporte tiene gpu_p50")
	check_ok(report.has("gpu_p95"), "reporte tiene gpu_p95")
	check_ok(report.has("gpu_p99"), "reporte tiene gpu_p99")
	check_ok(report.has("dropped_frames"), "reporte tiene dropped_frames")
	check_ok(report.has("budget_ms"), "reporte tiene budget_ms")
	check_ok(report.has("draw_calls"), "reporte tiene draw_calls")
	check_ok(report.has("visible_triangles"), "reporte tiene visible_triangles")
	check_ok(report.has("texture_memory"), "reporte tiene texture_memory")


func _test_probe_reset() -> void:
	var probe := FrameProbe.new(10, 8.0)
	probe.add_sample(9.0, 9.0)
	probe.add_sample(5.0, 5.0)

	probe.reset()
	var report := probe.get_report()
	check(report.sample_count, 0, "reset limpia muestras")
	check(report.dropped_frames, 0, "reset limpia dropped")
	check_approx(report.cpu_p50, 0.0, 0.001, "reset CPU percentiles a 0")
	check_approx(report.gpu_p50, 0.0, 0.001, "reset GPU percentiles a 0")
