## Validador de contenido en GDScript, reusando `core/mods/schema_validator.gd`.
##
##     godot --headless --path . --script tools/ci/validate_schemas.gd
##
## Existe para el riesgo R6 del plan: una sola implementación de reglas,
## compartida entre el juego y la línea de comandos. Mientras conviva con
## `tools/ci/check_schemas.py`, los dos tienen que dar el mismo veredicto sobre
## el mismo corpus.
##
## Comprueba lo mismo que el script de Python:
##   1. cada archivo de `schemas/` se puede cargar como schema;
##   2. cada `.json` de `examples/` valida contra su schema por convención de nombre;
##   3. cada `templates/*.example.json` valida contra su schema;
##   4. cada caso de `tests/data/schema_cases.json` valida o falla según lo declarado.
extends SceneTree

const SchemaValidator := preload("res://core/mods/schema_validator.gd")

const SCHEMA_DIR := "res://schemas"
const EXAMPLES_DIR := "res://examples"
const TEMPLATES_DIR := "res://templates"
const CASES_FILE := "res://tests/data/schema_cases.json"

## Ejemplos cuyo nombre no sigue la convención `*.<tipo>.json`.
const EXPLICIT_EXAMPLES := {"manifest.json": "mod_manifest"}


func _initialize() -> void:
	var schema_names: Array[String] = _schema_names()
	if schema_names.is_empty():
		printerr("no se encontró ningún schema en %s" % SCHEMA_DIR)
		quit(1)
		return
	print("schemas: %d" % schema_names.size())

	var failures: int = 0

	print("\nejemplos:")
	var examples: Dictionary = _validate_dir(EXAMPLES_DIR, schema_names, false)
	failures += int(examples.failures)
	if int(examples.count) == 0:
		printerr("  no se validó ningún ejemplo")
		failures += 1

	print("\ntemplates:")
	var templates: Dictionary = _validate_dir(TEMPLATES_DIR, schema_names, true)
	failures += int(templates.failures)

	print("\ncasos dorados:")
	var cases: Dictionary = _validate_golden_cases(schema_names)
	failures += int(cases.failures)

	print("")
	if failures > 0:
		printerr("FALLÓ: %d problema(s)" % failures)
		quit(1)
		return
	print("OK: %d schemas, %d ejemplos, %d templates, %d casos" % [
		schema_names.size(), int(examples.count), int(templates.count), int(cases.count)])
	quit(0)


## Nombres de schema disponibles: `weapon`, `mod_manifest`, etc.
func _schema_names() -> Array[String]:
	var out: Array[String] = []
	var dir := DirAccess.open(SCHEMA_DIR)
	if dir == null:
		return out
	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while not entry.is_empty():
		if entry.ends_with(".schema.json"):
			out.append(entry.substr(0, entry.length() - ".schema.json".length()))
		entry = dir.get_next()
	dir.list_dir_end()
	out.sort()
	return out


## Valida los `.json` de un directorio, **recursivamente**: `examples/` tiene el
## mod de ejemplo en un subdirectorio, y recorrer sólo el primer nivel validaba
## cero archivos sin que nada lo dijera.
func _validate_dir(dir_path: String, schema_names: Array[String], only_examples: bool) -> Dictionary:
	var failures: int = 0
	var count: int = 0
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return {"failures": 0, "count": 0}

	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while not entry.is_empty():
		var full: String = dir_path.path_join(entry)
		if dir.current_is_dir():
			if not entry.begins_with("."):
				var sub: Dictionary = _validate_dir(full, schema_names, only_examples)
				failures += int(sub.failures)
				count += int(sub.count)
		elif entry.ends_with(".json") and not (only_examples and not entry.ends_with(".example.json")):
			var schema_name: String = _schema_for(entry)
			if not schema_name.is_empty():
				if not schema_names.has(schema_name):
					# Hay templates sin schema (asset_manifest): no es un error.
					print("  skip %s -> sin schema '%s'" % [entry, schema_name])
				else:
					var document: Variant = _load_json(full)
					if document == null:
						printerr("  FALLA %s -> no es JSON válido" % entry)
						failures += 1
					else:
						var errors: Array[String] = SchemaValidator.new().validate_by_name(schema_name, document)
						if errors.is_empty():
							print("  ok   %s" % entry)
							count += 1
						else:
							printerr("  FALLA %s -> %s" % [entry, errors[0]])
							failures += 1
		entry = dir.get_next()
	dir.list_dir_end()
	return {"failures": failures, "count": count}


func _validate_golden_cases(schema_names: Array[String]) -> Dictionary:
	var data: Variant = _load_json(CASES_FILE)
	if not (data is Dictionary):
		printerr("no se pudo cargar %s" % CASES_FILE)
		return {"failures": 1, "count": 0}

	var failures: int = 0
	var cases: Array = (data as Dictionary).get("cases", [])
	for case: Dictionary in cases:
		var label: String = case.get("label", "?")
		var schema_name: String = case.get("schema", "")
		if not schema_names.has(schema_name):
			printerr("  FALLA %s -> schema inexistente: %s" % [label, schema_name])
			failures += 1
			continue
		var errors: Array[String] = SchemaValidator.new().validate_by_name(schema_name, case.get("document", {}))
		var valid: bool = errors.is_empty()
		if valid == bool(case.get("valid", true)):
			print("  ok   %s" % label)
		else:
			var detail: String = "validó cuando debía fallar" if errors.is_empty() else errors[0]
			printerr("  FALLA %s -> %s" % [label, detail])
			failures += 1
	return {"failures": failures, "count": cases.size()}


## `storm_sword.weapon.json` -> `weapon`; `x.example.json` -> el segmento previo.
func _schema_for(filename: String) -> String:
	if EXPLICIT_EXAMPLES.has(filename):
		return EXPLICIT_EXAMPLES[filename]
	var parts: PackedStringArray = filename.split(".")
	if parts.size() < 3:
		return ""
	if parts[parts.size() - 2] == "example":
		return parts[parts.size() - 3]
	return parts[parts.size() - 2]


func _load_json(path: String) -> Variant:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return null
	var text: String = f.get_as_text()
	f.close()
	return JSON.parse_string(text)
