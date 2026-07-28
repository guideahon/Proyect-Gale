## Comparación de versiones y evaluación de rangos SemVer 2.0.0.
##
## Cubre el subconjunto de rangos que usan los manifiestos de mod:
## `1.2.3`, `^1.0`, `~1.2`, `1.x`, `*`, `>=0.1.0 <1.0.0`, `1.0.0 - 2.0.0`
## y alternativas separadas por `||`.
##
## No usa RegEx ni recursos externos: se ejecuta durante el arranque, antes de
## montar ningún paquete, y debe funcionar en modo seguro.
##
## Reglas heredadas de SemVer que conviene recordar:
## - una versión con prerelease es menor que la misma sin prerelease;
## - un rango no acepta prereleases salvo que el propio rango mencione una
##   prerelease con el mismo núcleo (`>=1.0.0-beta` acepta `1.0.0-beta.2`,
##   `^1.0.0` no acepta `2.0.0-beta.1`);
## - los metadatos de build (`+abc`) se validan pero nunca afectan el orden.
class_name Semver
extends RefCounted

const _OPS := [">=", "<=", ">", "<", "="]


# ---------------------------------------------------------------------------
# API pública
# ---------------------------------------------------------------------------

## Analiza una versión completa `major.minor.patch[-pre][+build]`.
## Devuelve `{ok, error, major, minor, patch, pre, build, specified}`.
static func parse(text: String) -> Dictionary:
	var result := _parse_partial(text, false)
	if not result.ok:
		return result
	if result.specified < 3:
		return _err("versión incompleta: '%s'" % text)
	return result


static func is_valid(text: String) -> bool:
	return parse(text).ok


static func is_valid_range(text: String) -> bool:
	return parse_range(text).ok


## Devuelve -1, 0 o 1. Las entradas inválidas registran un error y devuelven 0;
## validar antes con `is_valid()` si el origen no es de confianza.
static func compare(a: String, b: String) -> int:
	var va := parse(a)
	var vb := parse(b)
	if not va.ok or not vb.ok:
		push_error("Semver.compare recibió una versión inválida: '%s' / '%s'" % [a, b])
		return 0
	return _cmp_parsed(va, vb)


## Comprueba si `version` cae dentro de `range_text`.
## `include_prerelease` desactiva el filtro de prereleases; se usa sólo en
## herramientas de desarrollo, nunca al resolver dependencias de un mod.
static func satisfies(version: String, range_text: String, include_prerelease: bool = false) -> bool:
	var v := parse(version)
	if not v.ok:
		return false
	var r := parse_range(range_text)
	if not r.ok:
		return false
	for group in r.groups:
		if _group_satisfied(v, group, include_prerelease):
			return true
	return false


## Mayor versión de `versions` que satisface el rango, o "" si ninguna.
static func max_satisfying(versions: Array, range_text: String, include_prerelease: bool = false) -> String:
	var best := ""
	var best_parsed := {}
	for item in versions:
		var candidate := str(item)
		if not satisfies(candidate, range_text, include_prerelease):
			continue
		var parsed := parse(candidate)
		if best.is_empty() or _cmp_parsed(parsed, best_parsed) > 0:
			best = candidate
			best_parsed = parsed
	return best


## Ordena ascendente y descarta las entradas inválidas.
static func sort_versions(versions: Array) -> Array:
	var valid: Array = []
	for item in versions:
		var candidate := str(item)
		if is_valid(candidate):
			valid.append(candidate)
	# Inserción: las listas de versiones de un mod son cortas y el orden
	# estable evita depender de lambdas dentro de un contexto estático.
	for i in range(1, valid.size()):
		var current: String = valid[i]
		var parsed := parse(current)
		var j := i - 1
		while j >= 0 and _cmp_parsed(parse(valid[j]), parsed) > 0:
			valid[j + 1] = valid[j]
			j -= 1
		valid[j + 1] = current
	return valid


## Analiza un rango. Devuelve `{ok, error, groups}` donde cada grupo es una
## lista de comparadores `{op, version}` unidos por AND; los grupos se unen por OR.
static func parse_range(text: String) -> Dictionary:
	var raw := text.strip_edges()
	if raw.is_empty():
		raw = "*"
	var groups: Array = []
	for group_text in raw.split("||", false):
		var parsed := _parse_group(group_text)
		if not parsed.ok:
			return parsed
		groups.append(parsed.comparators)
	if groups.is_empty():
		return _err("rango vacío: '%s'" % text)
	return {"ok": true, "error": "", "groups": groups}


## Representación textual de una versión ya analizada. Útil en mensajes de error.
static func format_version(v: Dictionary) -> String:
	var out := "%d.%d.%d" % [v.major, v.minor, v.patch]
	if not v.pre.is_empty():
		var parts: Array = []
		for identifier in v.pre:
			parts.append(str(identifier))
		out += "-" + ".".join(parts)
	if v.has("build") and not String(v.build).is_empty():
		out += "+" + String(v.build)
	return out


# ---------------------------------------------------------------------------
# Análisis de versiones
# ---------------------------------------------------------------------------

static func _parse_partial(text: String, allow_wildcard: bool) -> Dictionary:
	var s := text.strip_edges()
	if s.begins_with("v") or s.begins_with("V"):
		s = s.substr(1)
	if s.is_empty():
		return _err("versión vacía")

	var build := ""
	var plus := s.find("+")
	if plus != -1:
		build = s.substr(plus + 1)
		s = s.substr(0, plus)
		if not _valid_dot_identifiers(build, false):
			return _err("metadatos de build inválidos: '%s'" % text)

	var pre: Array = []
	var dash := s.find("-")
	if dash != -1:
		var pre_text := s.substr(dash + 1)
		s = s.substr(0, dash)
		if not _valid_dot_identifiers(pre_text, true):
			return _err("prerelease inválido: '%s'" % text)
		pre = _split_prerelease(pre_text)

	var parts := s.split(".", true)
	if parts.size() > 3:
		return _err("demasiados componentes: '%s'" % text)

	var nums := [0, 0, 0]
	var specified := 0
	var wildcard_seen := false
	for i in parts.size():
		var part: String = parts[i]
		if part == "x" or part == "X" or part == "*":
			if not allow_wildcard:
				return _err("comodín no permitido: '%s'" % text)
			wildcard_seen = true
			continue
		if wildcard_seen:
			return _err("componente numérico después de comodín: '%s'" % text)
		if not _is_number(part):
			return _err("componente no numérico: '%s'" % text)
		nums[i] = part.to_int()
		specified += 1

	if specified == 0 and not wildcard_seen:
		return _err("versión vacía: '%s'" % text)
	if not pre.is_empty() and specified < 3:
		return _err("prerelease requiere versión completa: '%s'" % text)

	return {
		"ok": true,
		"error": "",
		"major": nums[0],
		"minor": nums[1],
		"patch": nums[2],
		"pre": pre,
		"build": build,
		"specified": specified,
	}


static func _is_number(s: String) -> bool:
	if not _all_digits(s):
		return false
	# SemVer prohíbe ceros a la izquierda: 01.0.0 es inválido, no 1.0.0.
	return s.length() == 1 or s[0] != "0"


static func _all_digits(s: String) -> bool:
	if s.is_empty():
		return false
	for i in s.length():
		var c: String = s[i]
		if c < "0" or c > "9":
			return false
	return true


static func _valid_dot_identifiers(text: String, numeric_rules: bool) -> bool:
	if text.is_empty():
		return false
	for identifier in text.split(".", true):
		var ident: String = identifier
		if ident.is_empty():
			return false
		for i in ident.length():
			var c: String = ident[i]
			var is_alnum := (c >= "0" and c <= "9") or (c >= "a" and c <= "z") or (c >= "A" and c <= "Z")
			if not is_alnum and c != "-":
				return false
		if numeric_rules and _all_digits(ident) and ident.length() > 1 and ident[0] == "0":
			return false
	return true


static func _split_prerelease(text: String) -> Array:
	var out: Array = []
	for identifier in text.split(".", true):
		var ident: String = identifier
		if _all_digits(ident):
			out.append(ident.to_int())
		else:
			out.append(ident)
	return out


# ---------------------------------------------------------------------------
# Comparación
# ---------------------------------------------------------------------------

static func _cmp_parsed(a: Dictionary, b: Dictionary) -> int:
	var c := _cmp_int(a.major, b.major)
	if c != 0:
		return c
	c = _cmp_int(a.minor, b.minor)
	if c != 0:
		return c
	c = _cmp_int(a.patch, b.patch)
	if c != 0:
		return c
	return _cmp_pre(a.pre, b.pre)


static func _cmp_pre(a: Array, b: Array) -> int:
	if a.is_empty() and b.is_empty():
		return 0
	# Sin prerelease es mayor: 1.0.0 > 1.0.0-rc.1.
	if a.is_empty():
		return 1
	if b.is_empty():
		return -1
	var shared := mini(a.size(), b.size())
	for i in shared:
		var x = a[i]
		var y = b[i]
		var x_num := typeof(x) == TYPE_INT
		var y_num := typeof(y) == TYPE_INT
		if x_num and y_num:
			var c := _cmp_int(int(x), int(y))
			if c != 0:
				return c
		elif x_num:
			return -1
		elif y_num:
			return 1
		else:
			var xs := String(x)
			var ys := String(y)
			if xs < ys:
				return -1
			if xs > ys:
				return 1
	return _cmp_int(a.size(), b.size())


static func _cmp_int(a: int, b: int) -> int:
	if a < b:
		return -1
	if a > b:
		return 1
	return 0


# ---------------------------------------------------------------------------
# Análisis de rangos
# ---------------------------------------------------------------------------

static func _parse_group(text: String) -> Dictionary:
	var normalized := text.replace(",", " ").strip_edges()
	if normalized.is_empty():
		return _ok_comparators([_comp(">=", _zero())])

	var tokens := _tokenize(normalized)
	var comparators: Array = []
	var i := 0
	while i < tokens.size():
		var token: String = tokens[i]
		if token == "-":
			return _err("rango con guion mal formado: '%s'" % text)
		if i + 2 < tokens.size() and tokens[i + 1] == "-":
			var hyphen := _hyphen_range(token, tokens[i + 2])
			if not hyphen.ok:
				return hyphen
			comparators.append_array(hyphen.comparators)
			i += 3
			continue
		var expanded := _expand_token(token)
		if not expanded.ok:
			return expanded
		comparators.append_array(expanded.comparators)
		i += 1

	if comparators.is_empty():
		return _err("rango vacío: '%s'" % text)
	return _ok_comparators(comparators)


static func _tokenize(text: String) -> Array:
	var tokens: Array = []
	var pending := ""
	for item in text.split(" ", false):
		var t: String = String(item).strip_edges()
		if t.is_empty():
			continue
		# Admite `>= 1.0.0` además de `>=1.0.0`.
		if not pending.is_empty():
			tokens.append(pending + t)
			pending = ""
			continue
		if t == ">=" or t == "<=" or t == ">" or t == "<" or t == "=" or t == "^" or t == "~":
			pending = t
			continue
		tokens.append(t)
	if not pending.is_empty():
		# Operador sin versión: se deja pasar para que el análisis dé el error exacto.
		tokens.append(pending)
	return tokens


static func _expand_token(token: String) -> Dictionary:
	var t := token.strip_edges()
	if t.is_empty():
		return _err("comparador vacío")
	if t == "*" or t == "x" or t == "X":
		return _ok_comparators([_comp(">=", _zero())])
	if t.begins_with("^"):
		return _caret(t.substr(1))
	if t.begins_with("~"):
		var rest := t.substr(1)
		if rest.begins_with(">"):
			rest = rest.substr(1)  # alias tolerado `~>1.2`
		return _tilde(rest)
	for op in _OPS:
		var operator: String = op
		if t.begins_with(operator):
			return _op_range(operator, t.substr(operator.length()))
	return _plain(t)


static func _caret(rest: String) -> Dictionary:
	var v := _parse_partial(rest, true)
	if not v.ok:
		return v
	if v.specified == 0:
		return _ok_comparators([_comp(">=", _zero())])
	var upper: Dictionary
	if v.major > 0:
		upper = _make(v.major + 1, 0, 0)
	elif v.specified == 1:
		upper = _make(1, 0, 0)
	elif v.specified == 2:
		upper = _make(0, v.minor + 1, 0)
	elif v.minor > 0:
		upper = _make(0, v.minor + 1, 0)
	else:
		upper = _make(0, 0, v.patch + 1)
	return _ok_comparators([_comp(">=", _floor_version(v)), _comp("<", upper)])


static func _tilde(rest: String) -> Dictionary:
	var v := _parse_partial(rest, true)
	if not v.ok:
		return v
	if v.specified == 0:
		return _ok_comparators([_comp(">=", _zero())])
	var upper: Dictionary
	if v.specified == 1:
		upper = _make(v.major + 1, 0, 0)
	else:
		upper = _make(v.major, v.minor + 1, 0)
	return _ok_comparators([_comp(">=", _floor_version(v)), _comp("<", upper)])


static func _op_range(op: String, rest: String) -> Dictionary:
	var v := _parse_partial(rest, true)
	if not v.ok:
		return v
	if v.specified == 0:
		return _ok_comparators([_comp(">=", _zero())])
	var floor_version := _floor_version(v)
	if v.specified >= 3:
		return _ok_comparators([_comp(op, floor_version)])

	# Con versión parcial, el comparador se traduce al borde del rango implícito:
	# `>1.2` significa `>=1.3.0`, `<=1.2` significa `<1.3.0`.
	var upper := _partial_upper(v)
	match op:
		">=":
			return _ok_comparators([_comp(">=", floor_version)])
		"<":
			return _ok_comparators([_comp("<", floor_version)])
		">":
			return _ok_comparators([_comp(">=", upper)])
		"<=":
			return _ok_comparators([_comp("<", upper)])
		"=":
			return _ok_comparators([_comp(">=", floor_version), _comp("<", upper)])
	return _err("operador desconocido: '%s'" % op)


static func _plain(token: String) -> Dictionary:
	var v := _parse_partial(token, true)
	if not v.ok:
		return v
	if v.specified == 0:
		return _ok_comparators([_comp(">=", _zero())])
	if v.specified >= 3:
		return _ok_comparators([_comp("=", _floor_version(v))])
	return _ok_comparators([_comp(">=", _floor_version(v)), _comp("<", _partial_upper(v))])


static func _hyphen_range(low: String, high: String) -> Dictionary:
	var a := _parse_partial(low, true)
	if not a.ok:
		return a
	var b := _parse_partial(high, true)
	if not b.ok:
		return b
	var comparators: Array = [_comp(">=", _floor_version(a))]
	if b.specified >= 3:
		comparators.append(_comp("<=", _floor_version(b)))
	elif b.specified > 0:
		comparators.append(_comp("<", _partial_upper(b)))
	return _ok_comparators(comparators)


static func _partial_upper(v: Dictionary) -> Dictionary:
	if v.specified == 1:
		return _make(v.major + 1, 0, 0)
	return _make(v.major, v.minor + 1, 0)


# ---------------------------------------------------------------------------
# Evaluación
# ---------------------------------------------------------------------------

static func _group_satisfied(v: Dictionary, group: Array, include_prerelease: bool) -> bool:
	if group.is_empty():
		return false
	for comparator in group:
		if not _comparator_satisfied(v, comparator):
			return false
	if v.pre.is_empty() or include_prerelease:
		return true
	# Una prerelease sólo entra si el rango nombra una prerelease del mismo núcleo.
	for comparator in group:
		var target: Dictionary = comparator.version
		if target.pre.is_empty():
			continue
		if target.major == v.major and target.minor == v.minor and target.patch == v.patch:
			return true
	return false


static func _comparator_satisfied(v: Dictionary, comparator: Dictionary) -> bool:
	var c := _cmp_parsed(v, comparator.version)
	match comparator.op:
		">=":
			return c >= 0
		">":
			return c > 0
		"<=":
			return c <= 0
		"<":
			return c < 0
		"=":
			return c == 0
	return false


# ---------------------------------------------------------------------------
# Utilidades internas
# ---------------------------------------------------------------------------

static func _comp(op: String, version: Dictionary) -> Dictionary:
	return {"op": op, "version": version}


static func _make(major: int, minor: int, patch: int) -> Dictionary:
	return {"major": major, "minor": minor, "patch": patch, "pre": [], "build": "", "specified": 3}


static func _zero() -> Dictionary:
	return _make(0, 0, 0)


static func _floor_version(v: Dictionary) -> Dictionary:
	return {
		"major": v.major,
		"minor": v.minor,
		"patch": v.patch,
		"pre": v.pre,
		"build": "",
		"specified": 3,
	}


static func _ok_comparators(comparators: Array) -> Dictionary:
	return {"ok": true, "error": "", "comparators": comparators}


static func _err(message: String) -> Dictionary:
	return {"ok": false, "error": message}
