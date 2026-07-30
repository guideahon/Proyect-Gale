## SafeMode — modo seguro tras arranques fallidos consecutivos.
## No borra mods: solo deja de montar los no-oficiales.
extends RefCounted

const CONFIG_PATH := "user://safe_mode_config.json"
const MAX_FAILURES := 3

static func record_failure() -> void:
	var count: int = _load_count()
	count += 1
	_save_count(count)
	if count >= MAX_FAILURES:
		push_warning("SafeMode: %d fallos consecutivos — modo seguro activado" % count)

static func record_success() -> void:
	_save_count(0)

static func is_active() -> bool:
	return _load_count() >= MAX_FAILURES

static func should_load_mod(mod_id: String) -> bool:
	if is_active() and not mod_id.begins_with("official."):
		return false
	return true

static func _load_count() -> int:
	if not FileAccess.file_exists(CONFIG_PATH):
		return 0
	var f := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if f == null:
		return 0
	var data: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if data is Dictionary:
		return data.get("failures", 0)
	return 0

static func _save_count(count: int) -> void:
	var f := FileAccess.open(CONFIG_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({"failures": count}))
	f.close()
