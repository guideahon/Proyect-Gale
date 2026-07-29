## SchemaValidator — validador JSON Schema Draft 2020-12 en GDScript.
#
# Subconjunto suficiente para los schemas del proyecto Gale:
# type, required, enum, const, pattern, minimum/maximum,
# exclusiveMinimum/exclusiveMaximum, minItems/maxItems, uniqueItems,
# additionalProperties, $defs/$ref internos, oneOf/anyOf/allOf, not, if/then/else.
#
# Lee schemas desde disco (schemas/*.schema.json) y valida documentos
# contra ellos. Reemplaza la validación ad-hoc de benchmarks/runner.gd.

extends RefCounted

var _schema: Dictionary
var _defs: Dictionary = {}
var _errors: Array[String] = []

static func load_schema(path: String) -> Variant:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return FileAccess.get_open_error()
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err != OK:
		return ERR_PARSE_ERROR
	if typeof(json.data) != 27:
		return ERR_PARSE_ERROR
	return json.data

func validate(document: Variant) -> Array[String]:
	_errors.clear()
	_validate_value(document, _schema)
	return _errors.duplicate()

func validate_by_name(name: String, document: Variant) -> Array[String]:
	var schema_path := "res://schemas/%s.schema.json" % name
	var schema: Variant = load_schema(schema_path)
	if schema == null or typeof(schema) != 27:
		return ["no se pudo cargar schema: %s" % schema_path]
	_schema = schema
	_defs = schema.get("$defs", {})
	return validate(document)

func run_golden_cases() -> Dictionary:
	var cases_path := "res://tests/data/schema_cases.json"
	var file := FileAccess.open(cases_path, FileAccess.READ)
	if file == null:
		return {"total": 0, "passed": 0, "failed": 0}
	var json := JSON.new()
	json.parse(file.get_as_text())
	file.close()
	var cases: Array = json.data.cases
	var total: int = cases.size()
	var passed: int = 0
	var failed: int = 0
	for case: Dictionary in cases:
		var schema_name: String = case.schema
		var document: Variant = case.document
		var should_pass: bool = case.valid
		var label: String = case.label
		var errors: Array[String] = validate_by_name(schema_name, document)
		var is_valid: bool = errors.is_empty()
		if is_valid == should_pass:
			passed += 1
		else:
			failed += 1
			var detail: String = errors[0] if not errors.is_empty() else "validó cuando debía fallar"
			print("  FALLA %s -> %s" % [label, detail])
	return {"total": total, "passed": passed, "failed": failed}

func _validate_value(value: Variant, schema: Dictionary) -> void:
	if schema.is_empty():
		return
	if schema.has("type"):
		_validate_type(value, schema.type)
	if schema.has("enum"):
		_validate_enum(value, schema.enum)
	if schema.has("const"):
		_validate_const(value, schema.const)
	if typeof(value) == 2 or typeof(value) == 3:
		_validate_number(value, schema)
	if typeof(value) == 4:
		_validate_string(value, schema)
	if typeof(value) == 28:
		_validate_array(value, schema)
	if typeof(value) == 27:
		_validate_object(value, schema)
	if schema.has("oneOf"):
		_validate_oneOf(value, schema.oneOf)
	if schema.has("anyOf"):
		_validate_anyOf(value, schema.anyOf)
	if schema.has("allOf"):
		_validate_allOf(value, schema.allOf)
	if schema.has("not"):
		_validate_not(value, schema.not)
	if schema.has("if"):
		_validate_if_then_else(value, schema)
	if schema.has("$ref"):
		var ref_schema: Variant = _resolve_ref(schema["$ref"])
		if ref_schema != null and typeof(ref_schema) == 27:
			_validate_value(value, ref_schema)

func _validate_type(value: Variant, expected_type: String) -> void:
	var actual_type: String = _gd_type_to_json_type(typeof(value))
	# JSON Schema: 'number' incluye integer y float.
	if expected_type == "number" and actual_type == "integer":
		return
	if expected_type == "integer" and actual_type == "number":
		var num: float = float(value)
		if num == float(int(num)):
			return
	if actual_type != expected_type:
		_errors.append("type mismatch: expected '%s', got '%s'" % [expected_type, actual_type])

func _gd_type_to_json_type(gd_type: int) -> String:
	match gd_type:
		2: return "integer"
		3: return "number"
		4: return "string"
		1: return "boolean"
		28: return "array"
		27: return "object"
		0: return "null"
		_: return "unknown"

func _validate_enum(value: Variant, enum_values: Array) -> void:
	if not enum_values.has(value):
		_errors.append("value not in enum: %s" % str(value))

func _validate_const(value: Variant, expected: Variant) -> void:
	if value != expected:
		_errors.append("const mismatch: expected %s, got %s" % [str(expected), str(value)])

func _validate_number(value: Variant, schema: Dictionary) -> void:
	var num: float = float(value)
	if schema.has("minimum"):
		var min_val: float = float(schema.minimum)
		if schema.has("exclusiveMinimum") and schema.exclusiveMinimum:
			if num <= min_val:
				_errors.append("number %f not exclusive minimum > %f" % [num, min_val])
		else:
			if num < min_val:
				_errors.append("number %f below minimum %f" % [num, min_val])
	if schema.has("maximum"):
		var max_val: float = float(schema.maximum)
		if schema.has("exclusiveMaximum") and schema.exclusiveMaximum:
			if num >= max_val:
				_errors.append("number %f not exclusive maximum < %f" % [num, max_val])
		else:
			if num > max_val:
				_errors.append("number %f above maximum %f" % [num, max_val])

func _validate_string(value: String, schema: Dictionary) -> void:
	if schema.has("pattern"):
		var regex := RegEx.new()
		var compile_err := regex.compile(schema.pattern)
		if compile_err == OK:
			if not regex.search(value):
				_errors.append("string does not match pattern '%s'" % schema.pattern)

func _validate_array(value: Array, schema: Dictionary) -> void:
	if schema.has("minItems"):
		if value.size() < schema.minItems:
			_errors.append("array has %d items, minimum is %d" % [value.size(), schema.minItems])
	if schema.has("maxItems"):
		if value.size() > schema.maxItems:
			_errors.append("array has %d items, maximum is %d" % [value.size(), schema.maxItems])
	if schema.has("uniqueItems") and schema.uniqueItems:
		var seen: Array = []
		for item in value:
			if seen.has(item):
				_errors.append("array items are not unique")
				break
			seen.append(item)
	if schema.has("items"):
		for item in value:
			_validate_value(item, schema.items)

func _validate_object(value: Dictionary, schema: Dictionary) -> void:
	if schema.has("required"):
		for req: String in schema.required:
			if not value.has(req):
				_errors.append("required property missing: '%s'" % req)
	if schema.has("additionalProperties"):
		var allowed: bool = schema.additionalProperties
		if not allowed:
			var props: Array = schema.get("properties", {}).keys()
			for key: String in value.keys():
				if not props.has(key):
					_errors.append("additional property not allowed: '%s'" % key)
	if schema.has("properties"):
		for prop_name: String in schema.properties.keys():
			if value.has(prop_name):
				_validate_value(value[prop_name], schema.properties[prop_name])

func _validate_oneOf(value: Variant, options: Array) -> void:
	var match_count: int = 0
	for option: Variant in options:
		var saved_errors: Array[String] = _errors.duplicate()
		_errors.clear()
		_validate_value(value, option)
		if _errors.is_empty():
			match_count += 1
		_errors = saved_errors
	if match_count == 0:
		_errors.append("oneOf: value matches 0 of %d options" % options.size())
	elif match_count > 1:
		_errors.append("oneOf: value matches %d of %d options (expected 1)" % [match_count, options.size()])

func _validate_anyOf(value: Variant, options: Array) -> void:
	var matched: bool = false
	for option: Variant in options:
		var saved_errors: Array[String] = _errors.duplicate()
		_errors.clear()
		_validate_value(value, option)
		if _errors.is_empty():
			matched = true
			break
		_errors = saved_errors
	if not matched:
		_errors.append("anyOf: value matches none of %d options" % options.size())

func _validate_allOf(value: Variant, options: Array) -> void:
	for option: Variant in options:
		var saved_errors: Array[String] = _errors.duplicate()
		_errors.clear()
		_validate_value(value, option)
		_errors.append_array(saved_errors)

func _validate_not(value: Variant, not_schema: Dictionary) -> void:
	var saved_errors: Array[String] = _errors.duplicate()
	_errors.clear()
	_validate_value(value, not_schema)
	if _errors.is_empty():
		saved_errors.append("not: value should not match schema")
	_errors = saved_errors

func _validate_if_then_else(value: Variant, schema: Dictionary) -> void:
	var saved_errors: Array[String] = _errors.duplicate()
	_errors.clear()
	_validate_value(value, schema.if)
	var passed_if: bool = _errors.is_empty()
	_errors = saved_errors
	if passed_if and schema.has("then"):
		_validate_value(value, schema.then)
	elif not passed_if and schema.has("else"):
		_validate_value(value, schema.else)

func _resolve_ref(ref: String) -> Variant:
	if ref.begins_with("#/$defs/"):
		var name: String = ref.substr(len("#/$defs/"))
		if _defs.has(name):
			return _defs[name]
	elif ref.begins_with("#/definitions/"):
		var name: String = ref.substr(len("#/definitions/"))
		if _defs.has(name):
			return _defs[name]
	return null
