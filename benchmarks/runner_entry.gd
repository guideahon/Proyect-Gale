## Entrypoint ejecutable para benchmarks.
#
# Uso:
#     godot --headless --path . --script benchmarks/runner_entry.gd -- benchmark_forest 10
#
# Carga la escena de benchmark, mide frame time real durante
# duration_seconds, y escribe el reporte JSON.
#
# GPU no es medible en headless: el reporte publica null para gpu_ms
# y documenta la limitación en notes.
#
# Si no logra acumular muestras, falla con exit code 1.
# No genera datos sintéticos: sin medición real, no hay reporte.

extends SceneTree

const BenchmarkRunner := preload("res://benchmarks/runner.gd")

func _initialize() -> void:
	# Parametrizable por línea de comandos: -- escena duración
	var scene_name: String = "benchmark_empty"
	var duration_seconds: int = 5

	var args: PackedStringArray = OS.get_cmdline_args()
	# Saltar flags del motor y el nombre del script.
	var i: int = 0
	while i < args.size():
		if args[i] == "--script":
			i += 2  # saltar --script y el nombre del archivo
			break
		if args[i].ends_with(".gd"):
			i += 1  # saltar el nombre del script
			break
		i += 1
	if i < args.size():
		scene_name = args[i]
	if i + 1 < args.size():
		duration_seconds = int(args[i + 1])

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
		quit(1)

	# Medir frames reales con microsegundos para resolución suficiente.
	print("Midiendo %d segundos..." % duration_seconds)
	var start_time := Time.get_ticks_usec()
	var frame_count := 0

	while (Time.get_ticks_usec() - start_time) < (duration_seconds * 1_000_000):
		var frame_start := Time.get_ticks_usec()
		await Engine.get_main_loop().process_frame
		var frame_end := Time.get_ticks_usec()

		var cpu_ms := float(frame_end - frame_start) / 1000.0
		# GPU no medible en headless: null, no proxy.
		runner.add_sample(cpu_ms, -1.0)
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
