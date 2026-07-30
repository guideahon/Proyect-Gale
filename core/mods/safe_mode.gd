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

## En modo seguro se carga sólo contenido oficial. `official_verified` tiene que
## venir de la verificación de firma contra la clave anclada (docs/24 §7): el
## nombre no alcanza como prueba de procedencia, porque cualquiera puede llamar
## a su paquete `official.loquesea`. Quien llama es responsable de pasar el
## resultado de `signature_verifier` + `key_store`, no una suposición.
static func should_load_mod(mod_id: String, official_verified: bool = false) -> bool:
	if not is_active():
		return true
	if not mod_id.begins_with("official."):
		return false
	if not official_verified:
		push_warning("SafeMode: '%s' dice ser oficial pero su firma no se verificó contra la clave anclada" % mod_id)
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
