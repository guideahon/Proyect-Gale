## PackageReader — valida la estructura de un contenedor .gmod.
extends RefCounted

const _ALLOWED_EXTENSIONS := [
	".json", ".pck", ".tres", ".tscn", ".webp", ".png", ".jpg",
	".md", ".txt", ".xml", ".yaml", ".yml",
	".ogg", ".opus", ".wav",
	".glb", ".gltf", ".bin", ".import",
]

class PackageError:
	var reason: String = ""
	var offending_entry: String = ""

	func _init(p_reason: String, p_entry: String = "") -> void:
		reason = p_reason
		offending_entry = p_entry

static func validate(path: String) -> Variant:
	var zip := ZIPReader.new()
	var err: int = zip.open(path)
	if err != OK:
		return PackageError.new("no se pudo abrir el archivo", path)
	var entries: PackedStringArray = zip.get_files()
	var names_lower: Dictionary = {}
	var has_manifest: bool = false
	for entry: String in entries:
		var check: Variant = _check_entry(entry, names_lower)
		if check != null:
			zip.close()
			return check
		if entry == "manifest.json":
			has_manifest = true
	zip.close()
	if not has_manifest:
		return PackageError.new("falta manifest.json")
	return null

static func _check_entry(entry: String, names_lower: Dictionary) -> Variant:
	if entry.is_empty():
		return PackageError.new("entrada vacía", entry)
	if entry.begins_with("/") or entry.begins_with("\\"):
		return PackageError.new("ruta absoluta", entry)
	var parts: PackedStringArray = entry.split("/")
	for part: String in parts:
		if part == ".." or part == ".":
			return PackageError.new("segmento prohibido (.. o .)", entry)
		if part.begins_with("."):
			return PackageError.new("segmento oculto (empieza con .)", entry)
	var regex := RegEx.new()
	if regex.compile("^[A-Za-z0-9_./-]+$") == OK:
		if not regex.search(entry):
			return PackageError.new("caracteres inválidos en ruta", entry)
	if entry.length() > 255:
		return PackageError.new("ruta excede 255 caracteres", entry)
	var lower: String = entry.to_lower()
	if names_lower.has(lower):
		return PackageError.new("entrada duplicada (case-insensitive)", entry)
	names_lower[lower] = true
	var ext: String = _get_extension(entry)
	if not _ALLOWED_EXTENSIONS.has(ext):
		return PackageError.new("extensión no permitida: %s" % ext, entry)
	return null

static func _get_extension(filename: String) -> String:
	var dot_pos: int = filename.rfind(".")
	if dot_pos < 0:
		return ""
	return filename.substr(dot_pos).to_lower()
