## KeyStore — TOFU (trust on first use) sobre user://mod_config.json.
##
## docs/24 seccion 6:
## - Primera instalacion: fija autor/clave en mod_config.json
## - key_id distinto para mismo mod: advertencia
## - official.* firmado por otra clave: rechazo sin excepcion

extends RefCounted

const _CONFIG_PATH := "user://mod_config.json"

## Estado de confianza de una clave.
enum TrustState {
	OK,              # clave conocida y coincide
	NEW,             # clave nueva (primera vez)
	KEY_CHANGED,     # key_id distinto para el mismo mod
	OFFICIAL_MISMATCH, # official.* firmado por clave no oficial
}

## Verifica la confianza de una clave para un mod.
## mod_id: id del mod (ej. "example.storm_island")
## key_id: key_id de la firma
## signer: nombre del firmante declarado
## public_key: clave publica en PEM
static func verify_trust(mod_id: String, key_id: String, signer: String, public_key: String) -> Dictionary:
	var config: Dictionary = _load_config()
	var mod_key: String = _mod_key(mod_id)
	var stored: Dictionary = config.get(mod_key, {})

	if stored.is_empty():
		# Primera vez: registrar.
		stored = {
			"key_id": key_id,
			"signer": signer,
			"public_key": public_key,
		}
		config[mod_key] = stored
		_save_config(config)
		return {"state": TrustState.NEW, "stored_signer": signer, "key_id": key_id}

	# Clave conocida: verificar coincidencia.
	var stored_key_id: String = stored.get("key_id", "")
	if stored_key_id == key_id:
		return {"state": TrustState.OK, "stored_signer": stored.get("signer", ""), "key_id": key_id}

	# key_id distinto: verificar si es official.
	if mod_id.begins_with("official."):
		return {"state": TrustState.OFFICIAL_MISMATCH, "stored_signer": stored.get("signer", ""), "key_id": key_id}

	return {"state": TrustState.KEY_CHANGED, "stored_signer": stored.get("signer", ""), "key_id": key_id}

## Carga la configuracion de claves.
static func _load_config() -> Dictionary:
	var f := FileAccess.open(_CONFIG_PATH, FileAccess.READ)
	if f == null:
		return {}
	var data: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if data is Dictionary:
		return data
	return {}

## Guarda la configuracion de claves.
static func _save_config(config: Dictionary) -> void:
	var f := FileAccess.open(_CONFIG_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(config, "\t"))
		f.close()

## Genera un key_id a partir de una clave publica en PEM.
## Primeros 16 hex de SHA-256 sobre la clave en DER.
static func compute_key_id(public_key_pem: String) -> String:
	var key := CryptoKey.new()
	var err: Error = key.load_from_string(public_key_pem)
	if err != OK:
		return ""
	var der: PackedByteArray = key.get_key_data()
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(der)
	return ctx.finish().hex_encode().substr(0, 16)

## Genera la clave del mod en el config.
static func _mod_key(mod_id: String) -> String:
	return "mod:" + mod_id

## Clave oficial embebida (para official.*).
## En produccion se reemplaza con la clave real del proyecto.
static func get_official_public_key() -> String:
	return ProjectSettings.get_setting("gale/official_public_key", "")
