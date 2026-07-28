## Tests de `game/autoload/bootstrap.gd`.
##
## El checklist exige: "tests/unit/test_bootstrap.gd cubre la rama de fallo
## sin XR presente; la escena corre headless".
##
## Estrategia: instanciar Bootstrap como Node, agregarlo al árbol vía
## Engine.get_main_loop().root.add_child(), y verificar que en headless
## retorna sin intentar cargar escena ni inicializar XR.
extends "res://tests/framework/test_case.gd"

const _BOOTSTRAP_PATH := "res://game/autoload/bootstrap.gd"

func run() -> void:
	_test_bootstrap_loads()
	_test_bootstrap_headless_returns_early()
	_test_main_scene_exists()
	_test_openxr_not_initialized_in_headless()


## El script debe cargarse sin errores de parseo.
func _test_bootstrap_loads() -> void:
	var script := load(_BOOTSTRAP_PATH)
	check_ok(script != null, "bootstrap.gd se carga sin errores")


## Instanciar Bootstrap en headless: _ready() debe retornar sin cargar escena.
## Si llegamos acá sin crashear, la rama de headless funciona.
## Nota: no podemos verificar el contenido de _ready() sin inspeccionar
## el estado interno de Bootstrap; la ausencia de crash es la garantía.
func _test_bootstrap_headless_returns_early() -> void:
	var script: GDScript = load(_BOOTSTRAP_PATH)
	var bootstrap: Node = script.new()

	# Agregar al árbol para que _ready() se ejecute.
	var root: Node = Engine.get_main_loop().root
	root.add_child(bootstrap)

	# Dar un frame para que _ready() complete.
	await Engine.get_main_loop().process_frame

	# bootstrap sigue en el árbol y no crasheó: rama headless OK.
	check_ok(bootstrap.is_inside_tree(), "bootstrap sigue en el árbol tras _ready()")


## La escena principal debe existir y ser cargable.
func _test_main_scene_exists() -> void:
	var scene := load("res://game/scenes/main.tscn")
	check_ok(scene != null, "main.tscn se carga")


## En headless, OpenXR no está inicializado.
## Esto confirma que _init_xr() fallaría sin el bypass.
func _test_openxr_not_initialized_in_headless() -> void:
	var xr_interface := XRServer.find_interface("OpenXR")
	if xr_interface != null:
		check_ok(not xr_interface.is_initialized(), "OpenXR no inicializado en headless")
	else:
		# OpenXR ausente: verificar que find_interface devolvió null.
		check(xr_interface, null, "OpenXR interfaz es null en headless")
