## ModError — errores estructurados con mod causante y motivo.
extends RefCounted

enum Severity { WARNING, ERROR, CRITICAL }

class ModError:
	var mod_id: String = ""
	var severity: int = Severity.ERROR
	var message: String = ""
	var timestamp: float = 0.0

	func _init(p_mod: String, p_severity: int, p_msg: String) -> void:
		mod_id = p_mod
		severity = p_severity
		message = p_msg
		timestamp = Time.get_ticks_msec() / 1000.0

static var _errors: Array = []

static func report(mod_id: String, severity: int, message: String) -> void:
	var err := ModError.new(mod_id, severity, message)
	_errors.append(err)
	match severity:
		Severity.WARNING:
			push_warning("ModError: [%s] %s" % [mod_id, message])
		Severity.ERROR:
			push_error("ModError: [%s] %s" % [mod_id, message])
		Severity.CRITICAL:
			push_error("ModError CRITICAL: [%s] %s" % [mod_id, message])

static func get_errors() -> Array:
	return _errors

static func clear() -> void:
	_errors.clear()

static func count() -> int:
	return _errors.size()
