## PackMounter — extrae .gmod a user://mod_cache/, verifica y monta el PCK.
##
## Orden obligatorio de `docs/24` §5: estructura del contenedor y lista blanca
## de ADR-012 → firma e integridad → recién entonces copiar y montar. Montar
## primero y validar después sería inútil: al montar, el contenido ya está
## disponible para el motor.
extends RefCounted

const CACHE_DIR := "user://mod_cache"
const PackageReader := preload("res://core/mods/package_reader.gd")
const SignatureVerifier := preload("res://core/mods/signature_verifier.gd")

class MountResult:
	var ok: bool = false
	var message: String = ""
	var pack_path: String = ""

## `expected_hash` es el SHA-256 del PCK. Vacío sólo se acepta cuando el
## paquete trae firma verificable, que ya cubre la integridad de cada archivo.
static func mount(gmod_path: String, expected_hash: String) -> MountResult:
	var result := MountResult.new()

	# 1) Estructura del contenedor y lista blanca de extensiones (ADR-012).
	var pkg_err: Variant = PackageReader.validate(gmod_path)
	if pkg_err != null:
		result.message = "paquete rechazado: %s" % pkg_err.reason
		return result

	# 2) Firma e integridad. Un paquete sin signature.json es legítimo
	#    (docs/24 §6), pero entonces el hash del PCK es obligatorio.
	var sig := SignatureVerifier.verify(gmod_path)
	if not sig.ok:
		if sig.step == 3 and expected_hash.is_empty():
			result.message = "paquete sin firma: hace falta el SHA-256 esperado del PCK"
			return result
		if sig.step != 3:
			result.message = "verificación fallida en paso %d: %s" % [sig.step, sig.message]
			return result

	return _extract_and_mount(gmod_path, expected_hash, result)


static func _extract_and_mount(gmod_path: String, expected_hash: String, result: MountResult) -> MountResult:
	var cache_dir := DirAccess.open(CACHE_DIR)
	if cache_dir == null:
		var err := DirAccess.make_dir_recursive_absolute(CACHE_DIR)
		if err != OK:
			result.message = "no se pudo crear %s (err %d)" % [CACHE_DIR, err]
			return result
		cache_dir = DirAccess.open(CACHE_DIR)
		if cache_dir == null:
			result.message = "no se pudo abrir %s" % CACHE_DIR
			return result

	# Extraer PCK del ZIP
	var pck_path: String = CACHE_DIR.path_join("%s.pck" % _safe_name(gmod_path))
	var zip := ZIPReader.new()
	var open_err: int = zip.open(gmod_path)
	if open_err != OK:
		result.message = "no se pudo abrir %s (err %d)" % [gmod_path, open_err]
		return result

	# Buscar el PCK dentro del ZIP
	var files: PackedStringArray = zip.get_files()
	var pck_entry: String = ""
	for f: String in files:
		if f.ends_with(".pck"):
			pck_entry = f
			break
	if pck_entry.is_empty():
		zip.close()
		result.message = "no hay archivo .pck en %s" % gmod_path
		return result

	# Extraer
	var pck_data: PackedByteArray = zip.read_file(pck_entry)
	zip.close()
	if pck_data.is_empty():
		result.message = "archivo .pck vacio en %s" % gmod_path
		return result

	# Verificar hash
	var actual_hash: String = _hash(pck_data)
	if not expected_hash.is_empty() and actual_hash != expected_hash:
		result.message = "hash incorrecto: esperado %s, obtenido %s" % [expected_hash, actual_hash]
		return result

	# Escribir PCK en cache
	var f := FileAccess.open(pck_path, FileAccess.WRITE)
	if f == null:
		result.message = "no se pudo escribir %s" % pck_path
		return result
	f.store_buffer(pck_data)
	f.close()

	# Montar PCK — si falla, borrar el archivo y revertir
	var mount_ok: bool = ProjectSettings.load_resource_pack(pck_path)
	if not mount_ok:
		DirAccess.remove_absolute(pck_path)
		result.message = "montaje fallido"
		return result

	result.ok = true
	result.pack_path = pck_path
	result.message = "montado OK"
	return result

## Borra el PCK del caché. **No desmonta**: Godot 4 no expone unmount, así que
## el contenido ya montado sigue disponible hasta reiniciar. Por eso `docs/08`
## dice que los mods se activan y desactivan al reiniciar; el modo seguro
## (T3.12) depende de no volver a montarlo en el próximo arranque, no de sacarlo
## en caliente. Devuelve si el archivo se pudo borrar.
static func discard_cached_pack(pack_path: String) -> bool:
	if not FileAccess.file_exists(pack_path):
		return false
	return DirAccess.remove_absolute(pack_path) == OK

static func _hash(data: PackedByteArray) -> String:
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(data)
	return ctx.finish().hex_encode()

## Nombre de archivo para el caché. Se deriva del hash del path completo, no de
## sanear el nombre: al descartar caracteres, `mi-mod` y `mimod` colapsaban en
## el mismo archivo y un paquete sobrescribía al otro en silencio.
static func _safe_name(path: String) -> String:
	var base: String = path.get_file().get_basename().to_lower()
	var clean: String = ""
	for c: String in base:
		var ok := (c >= "a" and c <= "z") or (c >= "0" and c <= "9") or c == "_"
		clean += c if ok else "_"
	if clean.is_empty():
		clean = "mod"
	return "%s_%s" % [clean, _hash(path.to_utf8_buffer()).substr(0, 12)]
