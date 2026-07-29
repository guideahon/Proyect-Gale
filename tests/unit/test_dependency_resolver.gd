## Tests de `core/mods/dependency_resolver.gd`.
extends "res://tests/framework/test_case.gd"

func run() -> void:
	_test_simple_linear()
	_test_diamond()
	_test_cycle_detected()
	_test_missing_dependency()
	_test_conflict_detected()
	_test_load_after()
	_test_stable_order()
	_test_empty_list()
	_test_version_incompatible()

func _get_resolver() -> Object:
	var script: Script = load("res://core/mods/dependency_resolver.gd")
	return script.new()

func _make_manifest(id: String, version: String = "1.0.0", deps: Array = [], load_after: Array = [], conflicts: Array = []) -> Dictionary:
	return {
		"id": id,
		"version": version,
		"dependencies": deps,
		"load_after": load_after,
		"conflicts": conflicts
	}

func _test_simple_linear() -> void:
	var resolver: Object = _get_resolver()
	var manifests: Array = [
		_make_manifest("a.mod", "1.0.0"),
		_make_manifest("b.mod", "1.0.0", [{"id": "a.mod", "version": "^1.0"}]),
		_make_manifest("c.mod", "1.0.0", [{"id": "b.mod", "version": "^1.0"}])
	]
	var result: Object = resolver.resolve(manifests)
	check_ok(result.success, "resolucion lineal exitosa")
	var order: Array = result.order
	check(order[0], "a.mod", "a primero")
	check(order[1], "b.mod", "b segundo")
	check(order[2], "c.mod", "c tercero")

func _test_diamond() -> void:
	var resolver: Object = _get_resolver()
	var manifests: Array = [
		_make_manifest("a.mod"),
		_make_manifest("b.mod", "1.0.0", [{"id": "a.mod", "version": "*"}]),
		_make_manifest("c.mod", "1.0.0", [{"id": "a.mod", "version": "*"}]),
		_make_manifest("d.mod", "1.0.0", [
			{"id": "b.mod", "version": "*"},
			{"id": "c.mod", "version": "*"}
		])
	]
	var result: Object = resolver.resolve(manifests)
	check_ok(result.success, "diamante resuelto")
	var order: Array = result.order
	check_ok(order.find("a.mod") < order.find("b.mod"), "a antes de b")
	check_ok(order.find("a.mod") < order.find("c.mod"), "a antes de c")
	check_ok(order.find("b.mod") < order.find("d.mod"), "b antes de d")
	check_ok(order.find("c.mod") < order.find("d.mod"), "c antes de d")

func _test_cycle_detected() -> void:
	var resolver: Object = _get_resolver()
	var manifests: Array = [
		_make_manifest("a.mod", "1.0.0", [{"id": "b.mod", "version": "*"}]),
		_make_manifest("b.mod", "1.0.0", [{"id": "a.mod", "version": "*"}])
	]
	var result: Object = resolver.resolve(manifests)
	check_ok(not result.success, "ciclo detectado")
	check_ok(result.error.find("ciclo") >= 0, "mensaje menciona ciclo")

func _test_missing_dependency() -> void:
	var resolver: Object = _get_resolver()
	var manifests: Array = [
		_make_manifest("a.mod", "1.0.0", [{"id": "missing.mod", "version": "*"}])
	]
	var result: Object = resolver.resolve(manifests)
	check_ok(not result.success, "dependencia faltante detectada")
	check_ok(result.missing.has("missing.mod"), "missing.mod en lista de faltantes")

func _test_conflict_detected() -> void:
	var resolver: Object = _get_resolver()
	var manifests: Array = [
		_make_manifest("a.mod", "1.0.0", [], [], ["b.mod"]),
		_make_manifest("b.mod")
	]
	var result: Object = resolver.resolve(manifests)
	check_ok(not result.success, "conflicto detectado")
	check_ok(result.error.find("conflict") >= 0, "mensaje menciona conflicto")

func _test_load_after() -> void:
	var resolver: Object = _get_resolver()
	var manifests: Array = [
		_make_manifest("a.mod"),
		_make_manifest("b.mod", "1.0.0", [], ["a.mod"])
	]
	var result: Object = resolver.resolve(manifests)
	check_ok(result.success, "load_after resuelto")
	var order: Array = result.order
	check_ok(order.find("a.mod") < order.find("b.mod"), "a antes de b por load_after")

func _test_stable_order() -> void:
	var resolver: Object = _get_resolver()
	# Tres mods independientes: orden debe ser alfabetico.
	var manifests: Array = [
		_make_manifest("c.mod"),
		_make_manifest("a.mod"),
		_make_manifest("b.mod")
	]
	var result: Object = resolver.resolve(manifests)
	check_ok(result.success, "orden estable")
	var order: Array = result.order
	check(order[0], "a.mod", "primero a")
	check(order[1], "b.mod", "segundo b")
	check(order[2], "c.mod", "tercero c")

func _test_empty_list() -> void:
	var resolver: Object = _get_resolver()
	var result: Object = resolver.resolve([])
	check_ok(result.success, "lista vacia es valida")
	check_ok(result.order.is_empty(), "orden vacio")

func _test_version_incompatible() -> void:
	var resolver: Object = _get_resolver()
	var manifests: Array = [
		_make_manifest("a.mod", "1.0.0"),
		_make_manifest("b.mod", "1.0.0", [{"id": "a.mod", "version": "^2.0"}])
	]
	var result: Object = resolver.resolve(manifests)
	check_ok(not result.success, "version incompatible detectada")
