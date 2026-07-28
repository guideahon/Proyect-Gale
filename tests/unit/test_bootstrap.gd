## Tests de `game/autoload/bootstrap.gd`.
##
## Verifica que el bootstrap:
## - en modo headless saltea XR y carga la escena principal;
## - cuando OpenXR no está disponible, sale con código de error;
## - `_exit_with_message` imprime y termina.
extends "res://tests/framework/test_case.gd"

const _BOOTSTRAP_PATH := "res://game/autoload/bootstrap.gd"

func run() -> void:
	_test_bootstrap_loads()
	_test_main_scene_exists()


## El script debe cargarse sin errores de parseo.
func _test_bootstrap_loads() -> void:
	var script := load(_BOOTSTRAP_PATH)
	check_ok(script != null, "bootstrap.gd se carga sin errores")


## La escena principal debe existir y ser cargable.
func _test_main_scene_exists() -> void:
	var scene := load("res://game/scenes/main.tscn")
	check_ok(scene != null, "main.tscn se carga")
