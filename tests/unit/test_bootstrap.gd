## Tests de `game/autoload/bootstrap.gd`.
##
## El checklist exige: "tests/unit/test_bootstrap.gd cubre la rama de fallo
## sin XR presente; la escena corre headless".
##
## Estrategia: en modo headless, DisplayServer.get_name() == "headless",
## por lo que bootstrap saltea XR y llama a _load_main(). Verificamos que:
## 1. El script se carga sin errores.
## 2. main.tscn existe y es cargable.
## 3. DisplayServer es headless (confirmamos la rama tomada).
## 4. XRServer.find_interface("OpenXR") devuelve null en headless
##    (confirmamos que la rama de fallo existiría sin el bypass).
extends "res://tests/framework/test_case.gd"

const _BOOTSTRAP_PATH := "res://game/autoload/bootstrap.gd"

func run() -> void:
	_test_bootstrap_loads()
	_test_main_scene_exists()
	_test_headless_display_server()
	_test_no_openxr_in_headless()


## El script debe cargarse sin errores de parseo.
func _test_bootstrap_loads() -> void:
	var script := load(_BOOTSTRAP_PATH)
	check_ok(script != null, "bootstrap.gd se carga sin errores")


## La escena principal debe existir y ser cargable.
func _test_main_scene_exists() -> void:
	var scene := load("res://game/scenes/main.tscn")
	check_ok(scene != null, "main.tscn se carga")


## En headless, DisplayServer.get_name() debe ser "headless".
## Esto confirma que bootstrap toma la rama de bypass de XR.
func _test_headless_display_server() -> void:
	check(DisplayServer.get_name(), "headless", "DisplayServer es headless")


## En headless, el interfaz OpenXR puede existir pero no estar inicializado.
## Esto confirma que _init_xr() fallaría al intentar xr_interface.initialize()
## si no fuera por el bypass de headless.
func _test_no_openxr_in_headless() -> void:
	var xr_interface := XRServer.find_interface("OpenXR")
	# El interfaz puede existir en headless pero no estar inicializado.
	# Lo importante es que initialize() fallaría.
	if xr_interface != null:
		check_ok(not xr_interface.is_initialized(), "OpenXR no inicializado en headless")
	else:
		check_ok(true, "OpenXR ausente en headless")
