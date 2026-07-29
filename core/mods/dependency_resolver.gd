## DependencyResolver — orden topológico de mods con semver.
extends RefCounted

class ResolveResult:
	var success: bool = true
	var order: Array[String] = []
	var error: String = ""
	var missing: Array[String] = []

	func fail(p_error: String) -> void:
		success = false
		error = p_error

static func resolve(manifests: Array) -> ResolveResult:
	var result := ResolveResult.new()

	# Indexar por ID.
	var by_id: Dictionary = {}
	for manifest: Dictionary in manifests:
		var mid: String = manifest.get("id", "")
		if mid.is_empty():
			result.fail("un manifiesto no tiene id")
			return result
		if by_id.has(mid):
			result.fail("colision de IDs: %s" % mid)
			return result
		by_id[mid] = manifest

	# Verificar conflictos.
	for manifest: Dictionary in manifests:
		var mid: String = manifest.id
		var conflicts: Array = manifest.get("conflicts", [])
		for conflict_id: String in conflicts:
			if by_id.has(conflict_id):
				result.fail("conflicto: %s conflictua con %s" % [mid, conflict_id])
				return result

	# Verificar dependencias hard presentes y semver.
	var semver_script: Script = preload("res://core/mods/semver.gd")
	for manifest: Dictionary in manifests:
		var mid: String = manifest.id
		var deps: Array = manifest.get("dependencies", [])
		for dep: Dictionary in deps:
			var dep_id: String = dep.get("id", "")
			if not by_id.has(dep_id):
				result.missing.append(dep_id)
			else:
				var dep_version: String = dep.get("version", "*")
				var target_manifest: Dictionary = by_id[dep_id]
				var target_ver: String = target_manifest.get("version", "0.0.0")
				var semver: Object = semver_script.new()
				if not semver.satisfies(target_ver, dep_version):
					result.fail("version incompat: %s necesita %s %s pero tiene %s" % [
						mid, dep_id, dep_version, target_ver])
					return result

	if not result.missing.is_empty():
		result.fail("dependencias faltantes: %s" % ", ".join(result.missing))
		return result

	# Construir grafo: graph[id] = lista de prerequisitos de id.
	var graph: Dictionary = {}
	for mid in by_id.keys():
		graph[mid] = [] as Array[String]

	for manifest: Dictionary in manifests:
		var mid: String = manifest.id
		var deps: Array = manifest.get("dependencies", [])
		for dep: Dictionary in deps:
			graph[mid].append(dep.id)
		var load_after: Array = manifest.get("load_after", [])
		for la: String in load_after:
			if by_id.has(la) and not graph[mid].has(la):
				graph[mid].append(la)

	# Kahn's algorithm con orden alfabetico para estabilidad.
	var in_degree: Dictionary = {}
	for mid in by_id.keys():
		in_degree[mid] = 0

	for mid in by_id.keys():
		for prereq in graph[mid]:
			in_degree[mid] = in_degree[mid] + 1

	var queue: Array[String] = []
	for mid in by_id.keys():
		if in_degree[mid] == 0:
			queue.append(mid)
	queue.sort()

	var order: Array[String] = []
	while not queue.is_empty():
		var current: String = queue.front()
		queue.remove_at(0)
		order.append(current)
		for mid in by_id.keys():
			if graph[mid].has(current):
				in_degree[mid] -= 1
				if in_degree[mid] == 0:
					var inserted: bool = false
					for i in range(queue.size()):
						if mid < queue[i]:
							queue.insert(i, mid)
							inserted = true
							break
					if not inserted:
						queue.append(mid)

	if order.size() != by_id.size():
		result.fail("ciclo detectado en dependencias")
		return result

	result.order = order
	return result
