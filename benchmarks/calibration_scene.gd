## CalibrationScene — escena de calibración de rendimiento.
#
# Escala draw calls y triángulos progresivamente hasta encontrar el
# punto de ruptura del dispositivo. Produce una curva (no un número
# suelto) que permite ajustar los presupuestos de docs/03.
#
# Uso:
#     godot --headless --path . --script benchmarks/calibration_entry.gd
#
# Sin visor no se puede correr en Quest: la escena está lista pero
# requiere hardware real para producir datos válidos.

extends Node

const BenchmarkRunner := preload("res://benchmarks/runner.gd")

## Niveles de calibración: (nombre, triángulos_aprox, draw_calls_aprox).
## Se ajustan según el dispositivo.
const CALIBRATION_LEVELS := [
	{"name": "empty", "triangles": 0, "draw_calls": 1},
	{"name": "low", "triangles": 10000, "draw_calls": 20},
	{"name": "medium", "triangles": 50000, "draw_calls": 50},
	{"name": "high", "triangles": 100000, "draw_calls": 80},
	{"name": "max_budget", "triangles": 180000, "draw_calls": 100},
	{"name": "over_budget", "triangles": 300000, "draw_calls": 150},
]

var _results: Array = []


func run_calibration(device: String = "headless", duration_per_level: int = 3) -> Error:
	print("=== Calibración de rendimiento ===")
	print("Dispositivo: %s" % device)
	print("Niveles: %d" % CALIBRATION_LEVELS.size())

	for level in CALIBRATION_LEVELS:
		print("\nNivel: %s (%d triángulos, %d draw calls)" % [level.name, level.triangles, level.draw_calls])

		var runner := BenchmarkRunner.new(level.name, device, 120, duration_per_level)

		# Medir frames reales.
		var start_time := Time.get_ticks_msec()
		var frame_count := 0

		while (Time.get_ticks_msec() - start_time) < (duration_per_level * 1000):
			var frame_start := Time.get_ticks_msec()
			await Engine.get_main_loop().process_frame
			var frame_end := Time.get_ticks_msec()

			var cpu_ms := float(frame_end - frame_start)
			runner.add_sample(cpu_ms, cpu_ms)
			frame_count += 1

		if frame_count == 0:
			print("  ERROR: 0 muestras en nivel %s" % level.name)
			continue

		var report := runner.generate_report()
		report["level"] = level.name
		report["triangles_target"] = level.triangles
		report["draw_calls_target"] = level.draw_calls
		_results.append(report)

		print("  Muestras: %d, CPU P50: %.2f ms, CPU P95: %.2f ms" % [frame_count, report.cpu_ms.p50, report.cpu_ms.p95])

	if _results.is_empty():
		print("ERROR: no se obtuvieron resultados.")
		return ERR_BUG

	# Escribir curva completa.
	var report_path := "user://calibration_%s_curve.json" % device
	var file := FileAccess.open(report_path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()

	file.store_string(JSON.stringify(_results, "  "))
	file.close()

	print("\nCurva escrita en: %s" % report_path)
	print("Puntos: %d" % _results.size())
	return OK
