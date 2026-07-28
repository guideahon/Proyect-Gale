## Bootstrap — inicialización del juego.
#
# Autoload que se ejecuta primero. Intenta inicializar OpenXR; si falla,
# muestra un mensaje legible y termina sin crashear. Si tiene éxito, carga
# la escena principal.
#
# En modo headless (tests) saltea la inicialización de XR y carga la escena
# directamente.

extends Node

# Escena principal a cargar tras inicialización exitosa.
const _MAIN_SCENE := "res://game/scenes/main.tscn"


func _ready() -> void:
	# En modo headless no hay XR: ir directo a la escena principal.
	if Engine.is_editor_hint() or DisplayServer.get_name() == "headless":
		_load_main()
		return

	_init_xr()


func _init_xr() -> void:
	var xr_interface := XRServer.find_interface("OpenXR")

	if xr_interface == null:
		push_error("Bootstrap: no se encontró el interfaz OpenXR. Verificá que el addon de OpenXR esté instalado y habilitado.")
		_exit_with_message("No se encontró OpenXR. Instalá el addon de OpenXR para Godot 4.7.1.")
		return

	if not xr_interface.is_initialized():
		if not xr_interface.initialize():
			push_error("Bootstrap: OpenXR falló al inicializarse.")
			_exit_with_message("OpenXR no pudo inicializarse. Verificá que el runtime de XR esté disponible.")
			return

	_load_main()


func _load_main() -> void:
	# Verificar que la escena existe antes de intentar cargarla.
	if not ResourceLoader.exists(_MAIN_SCENE):
		push_error("Bootstrap: escena principal no encontrada: %s" % _MAIN_SCENE)
		_exit_with_message("Error: escena principal no encontrada.")
		return

	var err: Error = get_tree().change_scene_to_file(_MAIN_SCENE)
	if err != OK:
		push_error("Bootstrap: no se pudo cargar la escena principal (error %d)." % err)
		_exit_with_message("Error al cargar la escena principal.")


func _exit_with_message(message: String) -> void:
	# Imprime el mensaje y espera un breve momento antes de salir,
	# para que el usuario pueda leerlo en modo ventana.
	printerr(message)
	await get_tree().create_timer(3.0).timeout
	get_tree().quit(1)
