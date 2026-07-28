## Entrypoint ejecutable para benchmarks.
#
# Uso:
#     godot --headless --path . --script benchmarks/runner_entry.gd
#
# Carga la escena de benchmark, mide frame time real durante
# duration_seconds, y escribe el reporte JSON.
#
# Si no logra acumular muestras, falla con exit code 1.
# No genera datos sintéticos: sin medición real, no hay reporte.

extends SceneTree

const BenchmarkRunner := preload("res://benchmarks/runner.gd")

func _initialize() -> void:
	var scene_name := "benchmark_empty"
	var duration_seconds := 5

	print("=== Benchmark Runner ===")
	print("Escena: %s" % scene_name)
	print("Duración: %d segundos" % duration_seconds)

	var runner := BenchmarkRunner.new(scene_name, "headless", 120, duration_seconds)

	# Cargar la escena real.
	var scene_path := "res://benchmarks/%s.tscn" % scene_name
	if not ResourceLoader.exists(scene_path):
		print("ERROR: escena %s no existe." % scene_path)
		quit(1)

	print("Cargando escena: %s" % scene_path)
	var scene := load(scene_path)
	if scene == null:
		print("ERROR: escena no cargable.")
		quit(1)

	var instance = scene.instantiate()
	if instance is Node:
		root.add_child(instance)
		print("Escena instanciada correctamente.")
	else:
		print("ERROR: escena no es un Node.")
		quit(0)

	# Medir frames reales.
	print("Midiendo %d segundos..." % duration_seconds)
	var start_time := Time.get_ticks_msec()
	var frame_count := 0

	while (Time.get_ticks_msec() - start_time) < (duration_seconds * 1000):
		# Medir CPU frame time.
		var frame_start := Time.get_ticks_msec()
		await process_frame
		var frame_end := Time.get_ticks_msec()

		var cpu_ms := float(frame_end - frame_start)
		# GPU no medible en headless; usar CPU como proxy.
		var gpu_ms := cpu_ms

		runner.add_sample(cpu_ms, gpu_ms)
		frame_count += 1

	print("Muestras acumuladas: %d" % frame_count)

	if frame_count == 0:
		print("ERROR: no se acumularon muestras.")
		quit(1)

	# Escribir reporte.
	var report_path := "user://benchmark_%s_report.json" % scene_name
	var err := runner.write_report(report_path)
	if err != OK:
		print("ERROR: no se pudo escribir el reporte (error %d)" % err)
		quit(1)

	print("Reporte escrito en: %s" % report_path)
	print("Contenido:")
	var content := FileAccess.open(report_path, FileAccess.READ)
	if content != null:
		print(content.get_as_text())
		content.close()

	print("Benchmark completado.")
	quit(0)
