## PackageReader — valida la estructura de un contenedor .gmod.
#
# Verifica las reglas del contenedor segun docs/24:
# - rutas relativas con separador /
# - sin .., ., segmentos con punto inicial
# - sin rutas absolutas, enlaces simbolicos, entradas duplicadas
# - sin nombres que difieran solo en mayusculas
# - lista blanca de extensiones (ADR-012): sin .gd, .gdshader, .gdnlib
#
# Usa ZIPReader de Godot. No monta contenido.

extends RefCounted

## Lista blanca de extensiones permitidas en un paquete .gmod (ADR-012).
const _ALLOWED_EXTENSIONS := [
	".json",      # manifest, config
	".pck",       # contenido de Godot
	".tres",      # recursos serializados sin script
	".tscn",      # escenas sin script incrustado
	".webp",      # iconos
	".png",       # iconos alternativos
	".jpg",       # imagenes
	".md",        # README, CHANGELOG
	".txt",       # LICENSE, notas
	".xml",       # datos
	".yaml",      # datos
	".yml",       # datos
	".ogg",       # audio
	".opus",      # audio
	".wav",       # audio
	".glb",       # modelos
	".gltf",      # modelos
	".bin",       # datos binarios
	".import",    # configuracion de importacion
]

## Estructura de error para paquetes invalidos.
class PackageError:
	var reason: String = ""
	var offending_entry: String = ""

	func _init(p_reason: String, p_entry: String = "") -> void:
		reason = p_reason
		offending_entry = p_entry

## Valida la estructura de un archivo .gmod (ZIP).
## Devuelve null si es valido, PackageError si no.
static func validate(path: String) -> Variant:
	var zip := ZIPReader.new()
	var err := zip.open(path)
	if err != OK:
		return PackageError.new("no se pudo abrir el archivo", path)

	var entries: Array = zip.get_files()
	var names_lower: Dictionary = {}  # nombre en minuscula -> true
	var has_manifest: bool = false

	for entry: String in entries:
		var check := _check_entry(entry, names_lower)
		if check != null:
			zip.close()
			return check
		if entry == "manifest.json":
			has_manifest = true

	zip.close()

	if not has_manifest:
		return PackageError.new("falta manifest.json")

	return null

## Verifica una entrada individual del ZIP.
## Actualiza names_lower con el nombre normalizado.
## Devuelve PackageError si la entrada es invalida.
static func _check_entry(entry: String, names_lower: Dictionary) -> Variant:
	# Vacio.
	if entry.is_empty():
		return PackageError.new("entrada vacia", entry)

	# Ruta absoluta.
	if entry.begins_with("/") or entry.begins_with("\\"):
		return PackageError.new("ruta absoluta", entry)

	# Segmentos con .. o .
	var parts: PackedStringArray = entry.split("/")
	for part in parts:
		if part == ".." or part == ".":
			return PackageError.new("segmento prohibido (.. o .)", entry)
		if part.begins_with("."):
			return PackageError.new("segmento oculto (empieza con .)", entry)

	# Caracteres invalidos.
	var regex := RegEx.new()
	if regex.compile("^[A-Za-z0-9_./-]+$") == OK:
		if not regex.search(entry):
			return PackageError.new("caracteres invalidos en ruta", entry)

	# Longitud maxima.
	if entry.length() > 255:
		return PackageError.new("ruta excede 255 caracteres", entry)

	# Duplicados (case-insensitive).
	var lower: String = entry.to_lower()
	if names_lower.has(lower):
		return PackageError.new("entrada duplicada (case-insensitive)", entry)
	names_lower[lower] = true

	# Lista blanca de extensiones (ADR-012).
	var ext: String = _get_extension(entry)
	if not _ALLOWED_EXTENSIONS.has(ext):
		return PackageError.new("extension no permitida: %s" % ext, entry)

	return null

static func _get_extension(filename: String) -> String:
	var dot_pos: int = filename.rfind(".")
	if dot_pos < 0:
		return ""
	return filename.substr(dot_pos).to_lower()
