## ProfileManager — gestión de perfiles de rendimiento.
#
# Define perfiles fijos con límites de rendimiento según dispositivo y
# frecuencia de refresco. Cada perfil declara valores dentro de los
# rangos de docs/03.
#
# Uso típico como autoload `PerformanceService`:
#
#     var manager := ProfileManager.new()
#     manager.set_profile("quest2_120_strict")
#     var profile := manager.get_current_profile()

class_name ProfileManager
extends RefCounted

## Perfiles disponibles.
const PROFILES := {
	"quest1_72": {
		"device": "Quest 1",
		"refresh_rate_hz": 72,
		"cpu_p95_ms": 11.5,
		"gpu_p95_ms": 11.5,
		"cpu_p99_ms": 13.0,
		"gpu_p99_ms": 13.0,
		"draw_calls_min": 50,
		"draw_calls_max": 90,
		"render_scale_min": 0.50,
		"render_scale_max": 0.75,
		"msaa": 1,
		"max_enemies": 5,
		"max_rigid_bodies": 20,
	},
	"quest2_120_strict": {
		"device": "Quest 2",
		"refresh_rate_hz": 120,
		"cpu_p95_ms": 6.5,
		"gpu_p95_ms": 6.5,
		"cpu_p99_ms": 8.0,
		"gpu_p99_ms": 8.0,
		"draw_calls_min": 50,
		"draw_calls_max": 80,
		"render_scale_min": 0.60,
		"render_scale_max": 0.75,
		"msaa": 2,
		"max_enemies": 5,
		"max_rigid_bodies": 20,
	},
	"quest2_90": {
		"device": "Quest 2",
		"refresh_rate_hz": 90,
		"cpu_p95_ms": 9.0,
		"gpu_p95_ms": 9.0,
		"cpu_p99_ms": 10.5,
		"gpu_p99_ms": 10.5,
		"draw_calls_min": 50,
		"draw_calls_max": 80,
		"render_scale_min": 0.60,
		"render_scale_max": 0.80,
		"msaa": 2,
		"max_enemies": 5,
		"max_rigid_bodies": 20,
	},
	"quest3_120": {
		"device": "Quest 3",
		"refresh_rate_hz": 120,
		"cpu_p95_ms": 6.5,
		"gpu_p95_ms": 6.5,
		"cpu_p99_ms": 8.0,
		"gpu_p99_ms": 8.0,
		"draw_calls_min": 50,
		"draw_calls_max": 100,
		"render_scale_min": 0.65,
		"render_scale_max": 0.85,
		"msaa": 2,
		"max_enemies": 5,
		"max_rigid_bodies": 20,
	},
	"pcvr": {
		"device": "PCVR",
		"refresh_rate_hz": 120,
		"cpu_p95_ms": 8.0,
		"gpu_p95_ms": 8.0,
		"cpu_p99_ms": 10.0,
		"gpu_p99_ms": 10.0,
		"draw_calls_min": 50,
		"draw_calls_max": 150,
		"render_scale_min": 0.75,
		"render_scale_max": 1.0,
		"msaa": 4,
		"max_enemies": 5,
		"max_rigid_bodies": 20,
	},
}

## Perfil activo.
var _current_profile: String = ""

## Datos del perfil activo.
var _current_data: Dictionary = {}


## Devuelve la lista de nombres de perfil disponibles.
func get_available_profiles() -> Array[String]:
	return PROFILES.keys()


## Establece un perfil por nombre. Devuelve OK o ERR_INVALID_DATA.
func set_profile(profile_name: String) -> Error:
	if not PROFILES.has(profile_name):
		push_error("ProfileManager: perfil desconocido '%s'" % profile_name)
		return ERR_INVALID_DATA

	_current_profile = profile_name
	_current_data = PROFILES[profile_name]
	return OK


## Devuelve el nombre del perfil activo.
func get_current_profile() -> String:
	return _current_profile


## Devuelve los datos del perfil activo.
func get_current_data() -> Dictionary:
	return _current_data


## Devuelve si hay un perfil activo.
func has_active_profile() -> bool:
	return not _current_profile.is_empty()
