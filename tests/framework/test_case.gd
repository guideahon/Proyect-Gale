## Base mínima de tests.
##
## ADR-013 todavía no eligió framework y la ruta crítica no puede esperar a esa
## decisión. Esto es deliberadamente pequeño: si se adopta gdUnit4, se migra
## reemplazando esta clase, no reescribiendo los casos.
##
## Un test hereda de este archivo por ruta (no por `class_name`, para no ocupar
## el espacio global de nombres del juego) y sobrescribe `run()`:
##
##     extends "res://tests/framework/test_case.gd"
##
##     func run() -> void:
##         check(2 + 2, 4, "suma")
extends RefCounted

var passed := 0
var failed := 0
var failures: Array = []


## Punto de entrada que ejecuta el runner. Sobrescribir.
func run() -> void:
	push_error("El test no implementa run()")


## Compara valores. Los arrays y diccionarios se comparan por contenido.
func check(actual, expected, label: String) -> void:
	if _equals(actual, expected):
		passed += 1
		return
	failed += 1
	failures.append("%s\n         esperado: %s\n         obtenido: %s" % [label, str(expected), str(actual)])


## Variante para condiciones booleanas, más legible que `check(x, true, ...)`.
func check_ok(condition: bool, label: String) -> void:
	check(condition, true, label)


## Compara floats con tolerancia.
func check_approx(actual: float, expected: float, tolerance: float, label: String) -> void:
	if abs(actual - expected) <= tolerance:
		passed += 1
		return
	failed += 1
	failures.append("%s\n         esperado: %s ± %s\n         obtenido: %s" % [label, str(expected), str(tolerance), str(actual)])

## Falla siempre. Útil para marcar ramas que no deberían alcanzarse.
func fail(label: String) -> void:
	failed += 1
	failures.append(label)


func _equals(a, b) -> bool:
	var type_a := typeof(a)
	if type_a != typeof(b):
		return false
	if type_a == TYPE_ARRAY:
		if a.size() != b.size():
			return false
		for i in a.size():
			if not _equals(a[i], b[i]):
				return false
		return true
	if type_a == TYPE_DICTIONARY:
		if a.size() != b.size():
			return false
		for key in a:
			if not b.has(key):
				return false
			if not _equals(a[key], b[key]):
				return false
		return true
	return a == b
