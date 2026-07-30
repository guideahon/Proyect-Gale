## Tests de mod_error.gd y safe_mode.gd.
extends "res://tests/framework/test_case.gd"

func run() -> void:
	_test_report_and_get()
	_test_severity_levels()
	_test_clear()
	_test_safe_mode_inactive()
	_test_safe_mode_activates_after_3_failures()
	_test_safe_mode_blocks_non_official()
	_test_safe_mode_allows_official()
	_test_safe_mode_resets_on_success()

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

func _test_safe_mode_inactive() -> void:
	var sm: Script = load("res://core/mods/safe_mode.gd")
	sm.record_success()
	check_ok(not sm.is_active(), "modo seguro inactivo al inicio")
	check_ok(sm.should_load_mod("test.any_mod"), "carga cualquier mod")

func _test_safe_mode_activates_after_3_failures() -> void:
	var sm: Script = load("res://core/mods/safe_mode.gd")
	sm.record_success()
	sm.record_failure()
	check_ok(not sm.is_active(), "1 fallo: no activo")
	sm.record_failure()
	check_ok(not sm.is_active(), "2 fallos: no activo")
	sm.record_failure()
	check_ok(sm.is_active(), "3 fallos: modo seguro activo")
	sm.record_success()

func _test_safe_mode_blocks_non_official() -> void:
	var sm: Script = load("res://core/mods/safe_mode.gd")
	sm.record_success()
	sm.record_failure()
	sm.record_failure()
	sm.record_failure()
	check_ok(sm.is_active(), "modo seguro activo")
	check_ok(not sm.should_load_mod("test.third_party"), "bloquea mod no oficial")
	sm.record_success()

func _test_safe_mode_allows_official() -> void:
	var sm: Script = load("res://core/mods/safe_mode.gd")
	sm.record_success()
	sm.record_failure()
	sm.record_failure()
	sm.record_failure()
	check_ok(sm.should_load_mod("official.base"), "permite mod oficial en modo seguro")
	sm.record_success()

func _test_safe_mode_resets_on_success() -> void:
	var sm: Script = load("res://core/mods/safe_mode.gd")
	sm.record_success()
	sm.record_failure()
	sm.record_failure()
	sm.record_failure()
	check_ok(sm.is_active(), "modo seguro activo")
	sm.record_success()
	check_ok(not sm.is_active(), "reset tras exito")
