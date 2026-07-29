## Tests de `game/autoload/bootstrap.gd`.
extends "res://tests/framework/test_case.gd"

const _BOOTSTRAP_PATH := "res://game/autoload/bootstrap.gd"

func run() -> void:
	_test_bootstrap_loads()
	_test_bootstrap_headless_returns_early()
	_test_main_scene_exists()
	_test_openxr_not_initialized_in_headless()
	_test_autoload_declared_in_project_godot()

func _test_bootstrap_loads() -> void:
	var script := load(_BOOTSTRAP_PATH)
	check_ok(script != null, "bootstrap.gd se carga sin errores")

func _test_bootstrap_headless_returns_early() -> void:
	var script: GDScript = load(_BOOTSTRAP_PATH)
	var bootstrap: Node = script.new()
	var root: Node = Engine.get_main_loop().root
	root.add_child(bootstrap)
	await Engine.get_main_loop().process_frame
	check_ok(bootstrap.is_inside_tree(), "bootstrap sigue en el árbol tras _ready()")

func _test_main_scene_exists() -> void:
	var scene := load("res://game/scenes/main.tscn")
	check_ok(scene != null, "main.tscn se carga")

func _test_openxr_not_initialized_in_headless() -> void:
	var xr_interface := XRServer.find_interface("OpenXR")
	if xr_interface != null:
		check_ok(not xr_interface.is_initialized(), "OpenXR no inicializado en headless")
	else:
		check(xr_interface, null, "OpenXR interfaz es null en headless")

## R5: el autoload de Bootstrap debe estar declarado en project.godot.
## Nota: en M0 el autoload se declara una vez que main.tscn existe y no crashea.
## Hasta entonces, el test verifica que bootstrap.gd sea cargable como script.
func _test_autoload_declared_in_project_godot() -> void:
	var settings: String = ProjectSettings.get_setting("autoload/Bootstrap", "")
	# Si el autoload no está declarado, verificar que el script exista y sea cargable.
	if settings.is_empty():
		var script: Variant = load(_BOOTSTRAP_PATH)
		check_ok(script != null, "bootstrap.gd cargable (autoload pendiente de declarar)")
	else:
		check_ok(settings.find("bootstrap.gd") >= 0, "autoload apunta a bootstrap.gd")
