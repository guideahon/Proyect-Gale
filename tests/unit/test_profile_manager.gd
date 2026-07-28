## Tests de `core/perf/profile_manager.gd`.
##
## Verifica que los cinco perfiles existen, que ninguno declara valores
## fuera de los rangos de docs/03, y que cambiar de perfil es idempotente.
extends "res://tests/framework/test_case.gd"

const ProfileManager := preload("res://core/perf/profile_manager.gd")

func run() -> void:
	_test_five_profiles_exist()
	_test_quest2_120_strict_ranges()
	_test_quest1_72_ranges()
	_test_quest2_90_ranges()
	_test_quest3_120_ranges()
	_test_pcvr_ranges()
	_test_unknown_profile_fails()
	_test_switch_profile_idempotent()
	_test_active_profile_state()


func _test_five_profiles_exist() -> void:
	var manager := ProfileManager.new()
	var profiles: Array = manager.get_available_profiles()
	check(profiles.size(), 5, "5 perfiles disponibles")
	check_ok(profiles.has("quest1_72"), "perfil quest1_72")
	check_ok(profiles.has("quest2_120_strict"), "perfil quest2_120_strict")
	check_ok(profiles.has("quest2_90"), "perfil quest2_90")
	check_ok(profiles.has("quest3_120"), "perfil quest3_120")
	check_ok(profiles.has("pcvr"), "perfil pcvr")


func _test_quest2_120_strict_ranges() -> void:
	var manager := ProfileManager.new()
	manager.set_profile("quest2_120_strict")
	var data := manager.get_current_data()

	# docs/03: CPU/GPU P95 <= 6.5ms, P99 <= 8.0ms, 120Hz.
	check(data.refresh_rate_hz, 120, "120 Hz")
	check(data.cpu_p95_ms, 6.5, "CPU P95 <= 6.5")
	check(data.gpu_p95_ms, 6.5, "GPU P95 <= 6.5")
	check(data.cpu_p99_ms, 8.0, "CPU P99 <= 8.0")
	check(data.gpu_p99_ms, 8.0, "GPU P99 <= 8.0")
	check_ok(data.draw_calls_min >= 50, "draw_calls_min >= 50")
	check_ok(data.draw_calls_max <= 80, "draw_calls_max <= 80")
	check_ok(data.msaa >= 1 and data.msaa <= 4, "MSAA en rango")
	check_ok(data.max_enemies <= 5, "max_enemies <= 5")


func _test_quest1_72_ranges() -> void:
	var manager := ProfileManager.new()
	manager.set_profile("quest1_72")
	var data := manager.get_current_data()

	check(data.refresh_rate_hz, 72, "72 Hz")
	check_ok(data.cpu_p95_ms <= 11.5, "CPU P95 <= 11.5")
	check_ok(data.gpu_p95_ms <= 11.5, "GPU P95 <= 11.5")
	check_ok(data.cpu_p99_ms <= 13.0, "CPU P99 <= 13.0")
	check_ok(data.gpu_p99_ms <= 13.0, "GPU P99 <= 13.0")


func _test_quest2_90_ranges() -> void:
	var manager := ProfileManager.new()
	manager.set_profile("quest2_90")
	var data := manager.get_current_data()

	check(data.refresh_rate_hz, 90, "90 Hz")
	check_ok(data.cpu_p95_ms <= 10.0, "CPU P95 dentro de rango")
	check_ok(data.gpu_p95_ms <= 10.0, "GPU P95 dentro de rango")


func _test_quest3_120_ranges() -> void:
	var manager := ProfileManager.new()
	manager.set_profile("quest3_120")
	var data := manager.get_current_data()

	check(data.refresh_rate_hz, 120, "120 Hz")
	check_ok(data.cpu_p95_ms <= 8.0, "CPU P95 dentro de rango")
	check_ok(data.gpu_p95_ms <= 8.0, "GPU P95 dentro de rango")


func _test_pcvr_ranges() -> void:
	var manager := ProfileManager.new()
	manager.set_profile("pcvr")
	var data := manager.get_current_data()

	check(data.refresh_rate_hz, 120, "120 Hz")
	check_ok(data.cpu_p95_ms <= 10.0, "CPU P95 dentro de rango")
	check_ok(data.gpu_p95_ms <= 10.0, "GPU P95 dentro de rango")
	check_ok(data.msaa <= 4, "MSAA <= 4")


func _test_unknown_profile_fails() -> void:
	var manager := ProfileManager.new()
	var err := manager.set_profile("perfil_inventado")
	check(err, ERR_INVALID_DATA, "perfil desconocido devuelve error")


func _test_switch_profile_idempotent() -> void:
	var manager := ProfileManager.new()
	manager.set_profile("quest2_120_strict")
	check(manager.get_current_profile(), "quest2_120_strict", "perfil activo")

	manager.set_profile("quest1_72")
	check(manager.get_current_profile(), "quest1_72", "cambio de perfil")

	manager.set_profile("quest1_72")
	check(manager.get_current_profile(), "quest1_72", "idempotente")


func _test_active_profile_state() -> void:
	var manager := ProfileManager.new()
	check_ok(not manager.has_active_profile(), "sin perfil activo al inicio")

	manager.set_profile("quest2_120_strict")
	check_ok(manager.has_active_profile(), "con perfil activo tras set")
