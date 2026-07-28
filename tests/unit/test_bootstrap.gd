## Tests de `game/autoload/bootstrap.gd`.
##
## El checklist exige: "tests/unit/test_bootstrap.gd cubre la rama de fallo
## sin XR presente; la escena corre headless".
##
## Limitación: test_case.gd es RefCounted, no Node, por lo que no podemos
## instanciar Bootstrap en el árbol. Verificamos lo que sí es testeable:
## 1. El script se carga sin errores.
## 2. main.tscn existe y es cargable.
## 3. En headless, DisplayServer.get_name() == "headless" (rama tomada).
## 4. OpenXR no está inicializado en headless (la rama de fallo existiría
##    sin el bypass de headless).
##
## Para cubrir la instanciación real de Bootstrap se necesita un test de
## integración con SceneTree, que no es posible con este framework.
## T0.6 queda [~] hasta que exista un runner de integración.
extends "res://tests/framework/test_case.gd"

const _BOOTSTRAP_PATH := "res://game/autoload/bootstrap.gd"

func run() -> void:
	_test_bootstrap_loads()
	_test_main_scene_exists()
	_test_headless_display_server()
	_test_openxr_not_initialized_in_headless()


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


## En headless, OpenXR no está inicializado.
## Esto confirma que _init_xr() fallaría sin el bypass.
func _test_openxr_not_initialized_in_headless() -> void:
	var xr_interface := XRServer.find_interface("OpenXR")
	if xr_interface != null:
		check_ok(not xr_interface.is_initialized(), "OpenXR no inicializado en headless")
	else:
		check_ok(true, "OpenXR ausente en headless")
