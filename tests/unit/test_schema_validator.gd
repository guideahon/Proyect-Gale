## Tests de `core/mods/schema_validator.gd`.
##
## Ejecuta los MISMOS tests/data/schema_cases.json que usa
## tools/ci/check_schemas.py y verifica idéntico veredicto en los 33 casos.
extends "res://tests/framework/test_case.gd"

const _SV := preload("res://core/mods/schema_validator.gd")

func run() -> void:
	_test_golden_cases_all_pass()
	_test_validate_by_name_invalid_schema()
	_test_type_validation()
	_test_required_properties()
	_test_enum_validation()
	_test_number_constraints()
	_test_string_pattern()
	_test_array_constraints()
	_test_additional_properties()
	_test_oneOf()

## Los 33 casos dorados deben dar idéntico veredicto al validador Python.
## Si diverge uno solo, el test falla con el label del caso.
func _test_golden_cases_all_pass() -> void:
	var result := _run_golden_cases()
	check(result.failed, 0, "%d/%d casos dorados correctos; falla: %s" % [
		result.passed, result.total, result.first_failure])

func _run_golden_cases() -> Dictionary:
	var cases_path := "res://tests/data/schema_cases.json"
	var file := FileAccess.open(cases_path, FileAccess.READ)
	if file == null:
		return {"total": 0, "passed": 0, "failed": 0, "first_failure": "no se pudo abrir"}
	var json := JSON.new()
	json.parse(file.get_as_text())
	file.close()
	var cases: Array = json.data.cases
	var total: int = cases.size()
	var passed: int = 0
	var failed: int = 0
	var first_failure: String = ""
	for case: Dictionary in cases:
		var schema_name: String = case.schema
		var document: Variant = case.document
		var should_pass: bool = case.valid
		var label: String = case.label
		var validator := _SV.new()
		var errors: Array[String] = validator.validate_by_name(schema_name, document)
		var is_valid: bool = errors.is_empty()
		if is_valid == should_pass:
			passed += 1
		else:
			failed += 1
			if first_failure.is_empty():
				var detail: String = errors[0] if not errors.is_empty() else "validó cuando debía fallar"
				first_failure = "%s (%s)" % [label, detail]
	return {"total": total, "passed": passed, "failed": failed, "first_failure": first_failure}

func _test_validate_by_name_invalid_schema() -> void:
	var validator := _SV.new()
	var errors := validator.validate_by_name("schema_inexistente", {})
	check_ok(errors.size() > 0, "schema inexistente devuelve error")

func _test_type_validation() -> void:
	var validator := _SV.new()
	validator._schema = {"type": "string"}
	var errors := validator.validate("hola")
	check_ok(errors.is_empty(), "string pasa type string")
	errors = validator.validate(42)
	check_ok(errors.size() > 0, "integer falla type string")

func _test_required_properties() -> void:
	var validator := _SV.new()
	var schema := {
		"type": "object",
		"required": ["id", "name"],
		"properties": {
			"id": {"type": "string"},
			"name": {"type": "string"}
		}
	}
	validator._schema = schema
	var errors := validator.validate({"id": "a", "name": "b"})
	check_ok(errors.is_empty(), "objeto con propiedades requeridas pasa")
	errors = validator.validate({"id": "a"})
	check_ok(errors.size() > 0, "objeto sin 'name' falla required")

func _test_enum_validation() -> void:
	var validator := _SV.new()
	validator._schema = {"type": "string", "enum": ["red", "green", "blue"]}
	var errors := validator.validate("red")
	check_ok(errors.is_empty(), "valor en enum pasa")
	errors = validator.validate("yellow")
	check_ok(errors.size() > 0, "valor fuera de enum falla")

func _test_number_constraints() -> void:
	var validator := _SV.new()
	validator._schema = {"type": "number", "minimum": 0, "maximum": 100}
	var errors := validator.validate(50)
	check_ok(errors.is_empty(), "50 dentro de [0, 100]")
	errors = validator.validate(-1)
	check_ok(errors.size() > 0, "-1 fuera de mínimo")
	errors = validator.validate(101)
	check_ok(errors.size() > 0, "101 fuera de máximo")

func _test_string_pattern() -> void:
	var validator := _SV.new()
	validator._schema = {"type": "string", "pattern": "^[a-z]+:[a-z]+$"}
	var errors := validator.validate("ns:item")
	check_ok(errors.is_empty(), "pattern namespaced pasa")
	errors = validator.validate("sin_dos_puntos")
	check_ok(errors.size() > 0, "sin namespace falla pattern")

func _test_array_constraints() -> void:
	var validator := _SV.new()
	validator._schema = {"type": "array", "minItems": 1, "maxItems": 3, "uniqueItems": true}
	var errors := validator.validate([1, 2, 3])
	check_ok(errors.is_empty(), "array válido pasa")
	errors = validator.validate([])
	check_ok(errors.size() > 0, "array vacío falla minItems")
	errors = validator.validate([1, 1])
	check_ok(errors.size() > 0, "array duplicado falla uniqueItems")

func _test_additional_properties() -> void:
	var validator := _SV.new()
	validator._schema = {
		"type": "object",
		"properties": {"id": {"type": "string"}},
		"additionalProperties": false
	}
	var errors := validator.validate({"id": "a"})
	check_ok(errors.is_empty(), "sin propiedades adicionales pasa")
	errors = validator.validate({"id": "a", "extra": true})
	check_ok(errors.size() > 0, "propiedad adicional falla")

func _test_oneOf() -> void:
	var validator := _SV.new()
	validator._schema = {
		"oneOf": [
			{"type": "integer"},
			{"type": "string"}
		]
	}
	var errors := validator.validate(42)
	check_ok(errors.is_empty(), "integer pasa oneOf integer|string")
	errors = validator.validate("texto")
	check_ok(errors.is_empty(), "string pasa oneOf integer|string")
	errors = validator.validate(3.14)
	check_ok(errors.size() > 0, "float falla oneOf integer|string")
