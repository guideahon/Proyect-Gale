## Tests de `mod_error.gd`.
##
## Las pruebas de modo seguro viven en `test_safe_mode.gd`: un archivo por
## módulo, así un cambio en safe_mode no falla en un test que dice ser de otra
## cosa.
extends "res://tests/framework/test_case.gd"

func run() -> void:
	_test_report_and_get()
	_test_severity_levels()
	_test_clear()

func _test_report_and_get() -> void:
	var me: Script = load("res://core/mods/mod_error.gd")
	me.clear()
	me.report("test.bad_mod", me.Severity.ERROR, "missing dependency")
	var errors: Array = me.get_errors()
	check_ok(errors.size() > 0, "error registrado")
	var err: Object = errors[0]
	check(err.mod_id, "test.bad_mod", "mod causante")
	check(err.message, "missing dependency", "motivo")

func _test_severity_levels() -> void:
	var me: Script = load("res://core/mods/mod_error.gd")
	me.clear()
	me.report("test.mod", me.Severity.WARNING, "warn")
	me.report("test.mod", me.Severity.ERROR, "err")
	me.report("test.mod", me.Severity.CRITICAL, "crit")
	check(me.count(), 3, "tres errores registrados")

func _test_clear() -> void:
	var me: Script = load("res://core/mods/mod_error.gd")
	me.clear()
	me.report("test.mod", me.Severity.ERROR, "err")
	me.clear()
	check(me.count(), 0, "limpiado")
