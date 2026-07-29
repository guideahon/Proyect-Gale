## ManifestParser — lee y valida manifest.json de un mod.
#
# Lee el archivo, lo parsea y valida contra mod_manifest.schema.json
# usando SchemaValidator. No monta contenido ni registra nada.
#
# Devuelve un Dictionary con los campos del manifiesto o lanza un
# ModError si el archivo es inválido.

extends RefCounted

const _SCHEMA_NAME := "mod_manifest"

## Estructura de error para manifiestos inválidos.
class ManifestError:
	var mod_id: String = ""
	var reason: String = ""
	var details: Array[String] = []

	func _init(p_reason: String, p_details: Array[String] = []) -> void:
		reason = p_reason
		details = p_details

	func __repr__() -> String:
		var msg: String = "ManifestError: %s" % reason
		if not details.is_empty():
			msg += " (%s)" % details[0]
		return msg

## Lee y valida un manifest.json desde una ruta.
## Devuelve el Dictionary parseado o una ManifestError.
static func parse(path: String) -> Variant:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ManifestError.new("no se pudo abrir manifest.json", [
			"ruta: %s" % path])
	var raw: String = file.get_as_text()
	file.close()

	var json := JSON.new()
	var err := json.parse(raw)
	if err != OK:
		return ManifestError.new("JSON inválido", [
			"línea %d: %s" % [json.get_error_line(), json.get_error_message()]])
	if typeof(json.data) != 27:  # TYPE_DICTIONARY
		return ManifestError.new("el manifiesto no es un objeto JSON")

	var validator := preload("res://core/mods/schema_validator.gd").new()
	var errors := validator.validate_by_name(_SCHEMA_NAME, json.data)
	if not errors.is_empty():
		var mod_id: String = json.data.get("id", "(sin id)")
		var me := ManifestError.new("manifiesto no válido según schema", errors)
		me.mod_id = mod_id
		return me

	return json.data

## Extrae el ID del manifiesto sin validar completamente.
## Útil para mensajes de error tempranos.
static func get_id(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return "(inaccesible)"
	var raw: String = file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(raw) != OK:
		return "(JSON inválido)"
	if typeof(json.data) != 27:
		return "(no es objeto)"
	return json.data.get("id", "(sin id)")
