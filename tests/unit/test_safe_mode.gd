## Tests de `safe_mode.gd`.
##
## Criterio de T3.12: tres fallos consecutivos activan el modo seguro, se carga
## sólo contenido oficial verificado, y **no se borra nada** del usuario
## (docs/08: «no borrar automáticamente contenido»).
extends "res://tests/framework/test_case.gd"

const SafeMode := preload("res://core/mods/safe_mode.gd")

func run() -> void:
	_reset()
	_test_arranca_inactivo()
	_test_tres_fallos_activan()
	_test_exito_resetea()
	_test_solo_oficial_verificado()
	_test_no_borra_archivos_del_mod()
	_reset()


func _reset() -> void:
	SafeMode.record_success()


func _test_arranca_inactivo() -> void:
	_reset()
	check_ok(not SafeMode.is_active(), "sin fallos, modo seguro inactivo")
	check_ok(SafeMode.should_load_mod("autor.mod"), "con modo normal se cargan mods de terceros")


func _test_tres_fallos_activan() -> void:
	_reset()
	SafeMode.record_failure()
	check_ok(not SafeMode.is_active(), "un fallo no alcanza")
	SafeMode.record_failure()
	check_ok(not SafeMode.is_active(), "dos fallos no alcanzan")
	SafeMode.record_failure()
	check_ok(SafeMode.is_active(), "tres fallos consecutivos activan el modo seguro")


func _test_exito_resetea() -> void:
	_reset()
	SafeMode.record_failure()
	SafeMode.record_failure()
	SafeMode.record_failure()
	check_ok(SafeMode.is_active(), "activo antes del arranque exitoso")
	SafeMode.record_success()
	check_ok(not SafeMode.is_active(), "un arranque exitoso resetea el contador")


func _test_solo_oficial_verificado() -> void:
	_reset()
	for _i in 3:
		SafeMode.record_failure()
	check_ok(not SafeMode.should_load_mod("autor.mod", true), "en modo seguro no se cargan mods de terceros")
	# Cualquiera puede llamar a su paquete "official.algo": el nombre no es
	# prueba de procedencia, la firma contra la clave anclada sí (docs/24 §7).
	check_ok(not SafeMode.should_load_mod("official.hack", false), "un impostor con nombre oficial y sin firma verificada se rechaza")
	check_ok(SafeMode.should_load_mod("official.base", true), "el oficial con firma verificada se carga")


func _test_no_borra_archivos_del_mod() -> void:
	# docs/08: ante un fallo se desactiva el mod, se informa, y no se borra
	# contenido del usuario. Se comprueba que activar el modo seguro no toque un
	# archivo que simula un mod instalado.
	_reset()
	DirAccess.make_dir_recursive_absolute("user://mods")
	var mod_file := "user://mods/fake_mod.gmod"
	var f := FileAccess.open(mod_file, FileAccess.WRITE)
	f.store_string("contenido del usuario")
	f.close()

	for _i in 3:
		SafeMode.record_failure()
	check_ok(SafeMode.is_active(), "modo seguro activo")
	check_ok(FileAccess.file_exists(mod_file), "el archivo del mod sigue existiendo")

	var check_file := FileAccess.open(mod_file, FileAccess.READ)
	check(check_file.get_as_text(), "contenido del usuario", "el contenido no se alteró")
	check_file.close()
	DirAccess.remove_absolute(mod_file)
