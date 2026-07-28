## Tests de `core/mods/semver.gd`.
##
## Ejecutar todo:
##     godot --headless --path . --script tests/run_all.gd
## Sólo estos:
##     godot --headless --path . --script tests/run_all.gd -- semver
extends "res://tests/framework/test_case.gd"

const Semver := preload("res://core/mods/semver.gd")


func run() -> void:
	_test_parse()
	_test_compare()
	_test_satisfies_manifest_ranges()
	_test_satisfies_operators()
	_test_prerelease_gate()
	_test_selection()
	_test_invalid_input()


# ---------------------------------------------------------------------------

func _test_parse() -> void:
	for text in ["0.1.0", "1.2.3", "10.20.30", "1.0.0-beta.1", "1.0.0+build.5", "1.0.0-rc.1+exp", "v1.2.3"]:
		check(Semver.is_valid(text), true, "válida: %s" % text)

	for text in ["", "1", "1.2", "1.2.3.4", "01.2.3", "1.02.3", "1.2.x", "a.b.c", "1.2.3-", "1.2.3-01", "1.2.3+", "-1.2.3"]:
		check(Semver.is_valid(text), false, "inválida: %s" % text)

	var parsed := Semver.parse("1.2.3-alpha.7+meta")
	check(parsed.major, 1, "parse major")
	check(parsed.minor, 2, "parse minor")
	check(parsed.patch, 3, "parse patch")
	check(parsed.pre, ["alpha", 7], "parse prerelease tipado")
	check(parsed.build, "meta", "parse build")
	check(Semver.format_version(parsed), "1.2.3-alpha.7+meta", "format_version ida y vuelta")


func _test_compare() -> void:
	check(Semver.compare("1.0.0", "1.0.1"), -1, "patch menor")
	check(Semver.compare("1.0.0", "1.0.0"), 0, "iguales")
	check(Semver.compare("2.0.0", "1.9.9"), 1, "major mayor")
	check(Semver.compare("1.10.0", "1.9.0"), 1, "minor numérico, no lexicográfico")
	# Prerelease es menor que la versión final.
	check(Semver.compare("1.0.0-alpha", "1.0.0"), -1, "prerelease < release")
	check(Semver.compare("1.0.0-alpha", "1.0.0-alpha.1"), -1, "menos identificadores primero")
	check(Semver.compare("1.0.0-alpha.1", "1.0.0-alpha.beta"), -1, "numérico < alfanumérico")
	check(Semver.compare("1.0.0-beta.2", "1.0.0-beta.11"), -1, "prerelease numérico comparado como número")
	check(Semver.compare("1.0.0-rc.1", "1.0.0"), -1, "rc < final")
	# Los metadatos de build no participan del orden.
	check(Semver.compare("1.0.0+aaa", "1.0.0+zzz"), 0, "build ignorado")


func _test_satisfies_manifest_ranges() -> void:
	# Rangos que ya aparecen en examples/sample_mod/manifest.json.
	check(Semver.satisfies("1.0.0", "^1.0"), true, "^1.0 acepta 1.0.0")
	check(Semver.satisfies("1.4.2", "^1.0"), true, "^1.0 acepta 1.4.2")
	check(Semver.satisfies("2.0.0", "^1.0"), false, "^1.0 rechaza 2.0.0")
	check(Semver.satisfies("0.9.9", "^1.0"), false, "^1.0 rechaza 0.9.9")

	check(Semver.satisfies("0.1.0", ">=0.1.0 <1.0.0"), true, "borde inferior inclusivo")
	check(Semver.satisfies("0.9.9", ">=0.1.0 <1.0.0"), true, "dentro del rango")
	check(Semver.satisfies("1.0.0", ">=0.1.0 <1.0.0"), false, "borde superior exclusivo")
	check(Semver.satisfies("0.0.9", ">=0.1.0 <1.0.0"), false, "debajo del rango")

	# Caret con major 0: cada minor es potencialmente incompatible.
	check(Semver.satisfies("0.1.5", "^0.1.0"), true, "^0.1.0 acepta 0.1.5")
	check(Semver.satisfies("0.2.0", "^0.1.0"), false, "^0.1.0 rechaza 0.2.0")
	check(Semver.satisfies("0.0.3", "^0.0.3"), true, "^0.0.3 acepta 0.0.3")
	check(Semver.satisfies("0.0.4", "^0.0.3"), false, "^0.0.3 rechaza 0.0.4")
	check(Semver.satisfies("0.5.0", "^0"), true, "^0 acepta 0.5.0")
	check(Semver.satisfies("1.0.0", "^0"), false, "^0 rechaza 1.0.0")

	check(Semver.satisfies("1.2.9", "~1.2.3"), true, "~1.2.3 acepta 1.2.9")
	check(Semver.satisfies("1.2.2", "~1.2.3"), false, "~1.2.3 rechaza 1.2.2")
	check(Semver.satisfies("1.3.0", "~1.2.3"), false, "~1.2.3 rechaza 1.3.0")
	check(Semver.satisfies("1.2.9", "~1.2"), true, "~1.2 acepta 1.2.9")
	check(Semver.satisfies("1.9.9", "~1"), true, "~1 acepta 1.9.9")
	check(Semver.satisfies("2.0.0", "~1"), false, "~1 rechaza 2.0.0")

	check(Semver.satisfies("1.9.9", "1.x"), true, "1.x acepta 1.9.9")
	check(Semver.satisfies("2.0.0", "1.x"), false, "1.x rechaza 2.0.0")
	check(Semver.satisfies("1.2.9", "1.2"), true, "parcial 1.2 acepta 1.2.9")
	check(Semver.satisfies("1.3.0", "1.2"), false, "parcial 1.2 rechaza 1.3.0")
	check(Semver.satisfies("3.4.5", "*"), true, "* acepta todo")

	check(Semver.satisfies("1.2.3", "1.2.3"), true, "exacta acepta")
	check(Semver.satisfies("1.2.4", "1.2.3"), false, "exacta rechaza")

	# Los dos rangos que ya usa examples/sample_mod/manifest.json.
	check(Semver.satisfies("0.3.0", ">=0.1.0 <1.0.0"), true, "game_version del sample_mod")
	check(Semver.satisfies("1.0.0", "^1.0"), true, "mod_api del sample_mod")


func _test_satisfies_operators() -> void:
	check(Semver.satisfies("1.5.0", ">= 1.0.0 <2.0.0"), true, "operador con espacio")
	check(Semver.satisfies("0.5.0", ">=0.1.0,<1.0.0"), true, "coma como separador")
	check(Semver.satisfies("1.3.0", ">1.2"), true, "> parcial sube al siguiente minor")
	check(Semver.satisfies("1.2.9", ">1.2"), false, "> parcial excluye el minor nombrado")
	check(Semver.satisfies("1.2.9", "<=1.2"), true, "<= parcial incluye el minor completo")
	check(Semver.satisfies("1.3.0", "<=1.2"), false, "<= parcial excluye el siguiente minor")
	check(Semver.satisfies("1.5.0", "1.0.0 - 2.0.0"), true, "rango con guion")
	check(Semver.satisfies("2.0.0", "1.0.0 - 2.0.0"), true, "guion inclusivo arriba")
	check(Semver.satisfies("2.0.1", "1.0.0 - 2.0.0"), false, "guion excluye por encima")
	check(Semver.satisfies("2.3.9", "1.2 - 2.3"), true, "guion con extremo parcial")
	check(Semver.satisfies("2.4.0", "1.2 - 2.3"), false, "guion parcial corta en el minor siguiente")
	check(Semver.satisfies("2.1.0", "^1.0 || ^2.0"), true, "alternativa OR")
	check(Semver.satisfies("3.0.0", "^1.0 || ^2.0"), false, "OR sin coincidencia")


func _test_prerelease_gate() -> void:
	# Una prerelease no entra en un rango que no la nombra: 2.0.0-beta.1 no es
	# una 1.x aceptable ni satisface ^1.0 por ser "menor" que 2.0.0.
	check(Semver.satisfies("2.0.0-beta.1", "^1.0"), false, "prerelease de otro major fuera")
	check(Semver.satisfies("1.2.0-beta", "^1.0"), false, "prerelease no nombrada fuera")
	check(Semver.satisfies("1.0.0-beta.2", ">=1.0.0-beta"), true, "prerelease nombrada dentro")
	check(Semver.satisfies("1.0.0-alpha", ">=1.0.0-beta"), false, "prerelease anterior fuera")
	check(Semver.satisfies("1.2.0-beta", "^1.0", true), true, "include_prerelease abre la puerta")
	check(Semver.satisfies("1.0.0", ">=1.0.0-beta"), true, "release final dentro")


func _test_selection() -> void:
	var versions := ["1.0.0", "1.2.0", "1.10.0", "2.0.0", "1.0.0-rc.1"]
	check(Semver.max_satisfying(versions, "^1.0"), "1.10.0", "max_satisfying elige la mayor")
	check(Semver.max_satisfying(versions, "^3.0"), "", "max_satisfying sin candidatos")
	check(
		Semver.sort_versions(["1.10.0", "1.2.0", "1.0.0-rc.1", "1.0.0"]),
		["1.0.0-rc.1", "1.0.0", "1.2.0", "1.10.0"],
		"sort_versions ordena con prereleases"
	)
	check(Semver.sort_versions(["1.0.0", "basura"]), ["1.0.0"], "sort_versions descarta inválidas")


func _test_invalid_input() -> void:
	check(Semver.satisfies("basura", "^1.0"), false, "versión inválida no satisface")
	check(Semver.satisfies("1.0.0", "basura"), false, "rango inválido no satisface")
	check(Semver.is_valid_range("^1.0 || >=2.0.0 <3.0.0"), true, "rango compuesto válido")
	check(Semver.is_valid_range("^"), false, "operador sin versión")
	check(Semver.is_valid_range(">=1.0.0 - 2.0.0 -"), false, "guion suelto")
	check(Semver.parse_range("").ok, true, "rango vacío equivale a *")
	check(Semver.satisfies("9.9.9", ""), true, "rango vacío acepta todo")
