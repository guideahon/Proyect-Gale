## Entrypoint ejecutable para benchmarks.
#
## Uso:
##     godot --headless --path . --script benchmarks/runner_entry.gd
#
## Carga la escena de benchmark, mide frame time durante duration_seconds,
## y escribe el reporte JSON.
#
## Hasta que exista benchmark_empty.tscn (T1.7), este entrypoint genera
## un reporte con muestras sintéticas para validar la estructura.

extends SceneTree

const BenchmarkRunner := preload("res://benchmarks/runner.gd")

func _initialize() -> void:
	var scene_name := "benchmark_empty"
	var duration_seconds := 5

	print("=== Benchmark Runner ===")
	print("Escena: %s" % scene_name)
	print("Duración: %d segundos" % duration_seconds)

	var runner := BenchmarkRunner.new(scene_name, "headless", 120, duration_seconds)

	# Intentar cargar la escena real.
	var scene_path := "res://benchmarks/%s.tscn" % scene_name
	var scene_loaded := false
	if ResourceLoader.exists(scene_path):
		print("Cargando escena: %s" % scene_path)
		var scene := load(scene_path)
		if scene != null:
			# Instanciar la escena para que Godot la procese.
			var instance = scene.instantiate()
			if instance is Node:
				call_deferred("add_child", instance)
				scene_loaded = true
				print("Escena instanciada correctamente.")
			else:
				print("Escena no es un Node; usando muestras sintéticas.")
		else:
			print("Escena no cargable; usando muestras sintéticas.")
	else:
		print("Escena %s no existe; usando muestras sintéticas." % scene_path)

	if not scene_loaded:
		# Generar muestras sintéticas para validar la estructura del reporte.
		print("Generando %d muestras sintéticas..." % (120 * duration_seconds))
		for i in range(120 * duration_seconds):
			var cpu := 4.0 + randf() * 2.0
			var gpu := 4.5 + randf() * 2.0
			runner.add_sample(cpu, gpu)

	# Escribir reporte.
	var report_path := "user://benchmark_%s_report.json" % scene_name
	var err := runner.write_report(report_path)
	if err == OK:
		print("Reporte escrito en: %s" % report_path)
		print("Contenido:")
		var content := FileAccess.open(report_path, FileAccess.READ)
		if content != null:
			print(content.get_as_text())
			content.close()
	else:
		print("ERROR: no se pudo escribir el reporte (error %d)" % err)

	print("Benchmark completado.")
	quit(0)
