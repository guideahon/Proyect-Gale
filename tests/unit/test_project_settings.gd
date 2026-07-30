## Tests de `project.godot`.
##
## Godot acepta cualquier cosa en project.godot sin chistar: un valor inválido
## no da error, el motor usa el default en silencio. Ya pasó dos veces con el
## renderer (`=1` y `"vulkan_mobile"`, ninguno válido) y no se detectó hasta
## probar en el visor. Estos tests son la red para esa clase de error.
##
## Se lee el ARCHIVO con ConfigFile en lugar de consultar ProjectSettings: en
## headless el motor fuerza `xr/openxr/enabled` a false porque no hay runtime
## XR, así que el valor efectivo no sirve para validar lo que está escrito.
extends "res://tests/framework/test_case.gd"

const VALID_RENDERING_METHODS := ["forward_plus", "mobile", "gl_compatibility"]

var _cfg := ConfigFile.new()

func run() -> void:
	var err := _cfg.load("res://project.godot")
	check(err, OK, "project.godot se puede parsear")
	if err != OK:
		return
	_test_rendering_method_valido()
	_test_openxr_habilitado()
	_test_autoloads_declarados()
	_test_escena_principal()
	_test_version_semver()


func _val(section: String, key: String, default: Variant = null) -> Variant:
	return _cfg.get_value(section, key, default)


func _test_rendering_method_valido() -> void:
	var method: String = str(_val("rendering", "renderer/rendering_method", ""))
	check_ok(
		VALID_RENDERING_METHODS.has(method),
		"rendering_method '%s' está entre los válidos %s" % [method, VALID_RENDERING_METHODS]
	)


func _test_openxr_habilitado() -> void:
	# OpenXR va habilitado SÓLO en Android, con override por feature tag: con el
	# valor global en true, cada corrida headless intenta abrir el runtime XR de
	# la máquina y falla, ensuciando y demorando la batería. En el visor lo que
	# manda es el override.
	check(_val("xr", "openxr/enabled.android", false), true, "OpenXR habilitado en Android")
	check(_val("xr", "openxr/enabled", true), false, "OpenXR NO habilitado globalmente")
	check(_val("xr", "shaders/enabled", false), true, "xr/shaders/enabled declarado en true")


func _test_autoloads_declarados() -> void:
	for name: String in ["Bootstrap", "UpdateService"]:
		var path: String = str(_val("autoload", name, ""))
		check_ok(not path.is_empty(), "autoload %s declarado" % name)
		check_ok(ResourceLoader.exists(path.trim_prefix("*")), "el script de %s existe" % name)


func _test_escena_principal() -> void:
	var main: String = str(_val("application", "run/main_scene", ""))
	check_ok(not main.is_empty(), "main_scene declarada")
	check_ok(ResourceLoader.exists(main), "main_scene existe: %s" % main)


func _test_version_semver() -> void:
	# El updater compara esta versión contra el tag del release: si no es
	# semver, decide() devuelve ERROR y la comprobación no sirve de nada.
	var version: String = str(_val("application", "config/version", ""))
	var semver := load("res://core/mods/semver.gd")
	check_ok(semver.is_valid(version), "application/config/version '%s' es semver" % version)
