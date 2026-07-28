## Tests de `core/perf/profile_manager.gd`.
##
## Verifica que los cinco perfiles existen, que ninguno declara valores
## fuera de los rangos de docs/03, y que cambiar de perfil es idempotente.
##
## Los rangos se verifican con desigualdades, no igualdad: agregar un
## perfil nuevo con un valor fuera de presupuesto hará fallar el test.
extends "res://tests/framework/test_case.gd"

const ProfileManager := preload("res://core/perf/profile_manager.gd")

## Rangos máximos permitidos por docs/03 por refresh rate.
## PCVR tiene presupuesto más relajado que Quest a 120 Hz.
const RANGES := {
	72: {"cpu_p95": 11.5, "gpu_p95": 11.5, "cpu_p99": 13.0, "gpu_p99": 13.0},
	90: {"cpu_p95": 10.0, "gpu_p95": 10.0, "cpu_p99": 11.5, "gpu_p99": 11.5},
	120: {"cpu_p95": 6.5, "gpu_p95": 6.5, "cpu_p99": 8.0, "gpu_p99": 8.0},
}

## Rangos PCVR (más relajados que Quest a 120 Hz).
const PCVR_RANGE := {"cpu_p95": 10.0, "gpu_p95": 10.0, "cpu_p99": 12.0, "gpu_p99": 12.0}

func run() -> void:
	_test_five_profiles_exist()
	_test_all_profiles_within_budget()
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


## Recorre TODOS los perfiles y verifica que ninguno exceda los rangos
## de docs/03 para su refresh rate.
func _test_all_profiles_within_budget() -> void:
	var manager := ProfileManager.new()
	var profiles: Array = manager.get_available_profiles()

	for profile_name in profiles:
		manager.set_profile(profile_name)
		var data := manager.get_current_data()
		var hz: int = data.refresh_rate_hz

		# Encontrar el rango correspondiente.
		var range: Variant = _get_range_for_hz(hz, profile_name)
		if range == null:
			fail("perfil '%s' tiene refresh_rate_hz=%d sin rango definido en docs/03" % [profile_name, hz])
			continue

		check_ok(data.cpu_p95_ms <= range.cpu_p95, "%s: cpu_p95 %.1f <= %.1f" % [profile_name, data.cpu_p95_ms, range.cpu_p95])
		check_ok(data.gpu_p95_ms <= range.gpu_p95, "%s: gpu_p95 %.1f <= %.1f" % [profile_name, data.gpu_p95_ms, range.gpu_p95])
		check_ok(data.cpu_p99_ms <= range.cpu_p99, "%s: cpu_p99 %.1f <= %.1f" % [profile_name, data.cpu_p99_ms, range.cpu_p99])
		check_ok(data.gpu_p99_ms <= range.gpu_p99, "%s: gpu_p99 %.1f <= %.1f" % [profile_name, data.gpu_p99_ms, range.gpu_p99])
		check_ok(data.msaa >= 1 and data.msaa <= 4, "%s: MSAA en [1,4]" % profile_name)
		check_ok(data.max_enemies <= 5, "%s: max_enemies <= 5" % profile_name)
		check_ok(data.max_rigid_bodies <= 20, "%s: max_rigid_bodies <= 20" % profile_name)


func _get_range_for_hz(hz: int, profile_name: String) -> Variant:
	if profile_name == "pcvr":
		return PCVR_RANGE
	if RANGES.has(hz):
		return RANGES[hz]
	return null


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
