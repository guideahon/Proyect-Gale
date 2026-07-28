## Entrypoint para calibración de rendimiento.
#
# Uso:
#     godot --headless --path . --script benchmarks/calibration_entry.gd
#
# Recorre niveles de complejidad creciente y produce una curva JSON.
# Sin visor, los datos son referenciales (headless no mide GPU real).

extends SceneTree

func _initialize() -> void:
	var scene_path := "res://benchmarks/calibration_scene.tscn"
	var scene := load(scene_path)

	if scene == null:
		print("ERROR: no se pudo cargar calibration_scene.tscn")
		quit(1)

	var calibration: Node = scene.instantiate()
	root.add_child(calibration)

	var err: Error = await calibration.run_calibration("headless", 2)
	if err != OK:
		print("ERROR: calibración falló (error %d)" % err)
		quit(1)

	print("Calibración completada.")
	quit(0)
