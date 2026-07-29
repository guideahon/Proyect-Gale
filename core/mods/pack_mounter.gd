## PackMounter — extrae .gmod a user://mod_cache/, verifica hash, monta PCK, revierte si falla.
extends RefCounted

const CACHE_DIR := "user://mod_cache"

class MountResult:
	var ok: bool = false
	var message: String = ""
	var pack_path: String = ""

static func mount(gmod_path: String, expected_hash: String) -> MountResult:
	var result := MountResult.new()
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

static func unmount(pack_path: String) -> bool:
	# Godot 4 no tiene unmount nativo; solo borramos el archivo.
	# El PCK queda cargado hasta que se cierre el proyecto.
	DirAccess.remove_absolute(pack_path)
	return true

static func _hash(data: PackedByteArray) -> String:
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(data)
	return ctx.finish().hex_encode()

static func _safe_name(path: String) -> String:
	var name: String = path.get_file().get_basename()
	var out: String = ""
	for c: String in name:
		if c.is_valid_identifier() or c.is_valid_int():
			out += c
	return out if out.length() > 0 else "mod"
