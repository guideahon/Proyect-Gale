## SignatureVerifier — verifica firma e integridad de un paquete .gmod.
extends RefCounted

class VerifyResult:
	var ok: bool = false
	var step: int = 0
	var message: String = ""

	func _init(p_ok: bool, p_step: int, p_msg: String) -> void:
		ok = p_ok
		step = p_step
		message = p_msg

static func verify(path: String) -> VerifyResult:
	var zip := ZIPReader.new()
	var err: int = zip.open(path)
	if err != OK:
		return VerifyResult.new(false, 1, "no se pudo abrir el ZIP")
	var zip_files: PackedStringArray = zip.get_files()
	var pkg_reader: Script = load("res://core/mods/package_reader.gd")
	var pkg_err: Variant = pkg_reader.validate(path)
	if pkg_err != null:
		zip.close()
		return VerifyResult.new(false, 2, "estructura invalida: %s" % pkg_err.reason)
	if not zip_files.has("signature.json"):
		zip.close()
		return VerifyResult.new(false, 3, "falta signature.json")
	var sig_data: PackedByteArray = _read_zip_file(zip, "signature.json")
	var sig: Variant = JSON.parse_string(sig_data.get_string_from_utf8())
	if not sig is Dictionary:
		zip.close()
		return VerifyResult.new(false, 4, "signature.json no es un objeto JSON")
	var sig_files: Array = sig.get("files", [])
	if not _files_match(zip_files, sig_files):
		zip.close()
		return VerifyResult.new(false, 5, "lista de archivos no coincide")
	for item in sig_files:
		if not item is Dictionary:
			zip.close()
			return VerifyResult.new(false, 6, "entrada invalida en signature.files")
		var file_path: String = item.get("path", "")
		var expected_hash: String = item.get("sha256", "")
		var actual_hash: String = _hash_zip_file(zip, file_path)
		if actual_hash != expected_hash:
			zip.close()
			return VerifyResult.new(false, 6, "hash incorrecto para %s" % file_path)
	var canonical: String = _build_canonical_payload(sig_files)
	var payload_hash: String = _sha256_string(canonical)
	var expected_payload: String = sig.get("payload_sha256", "")
	if payload_hash != expected_payload:
		zip.close()
		return VerifyResult.new(false, 7, "payload_sha256 no coincide")
	var algorithm: String = sig.get("algorithm", "none")
	if algorithm != "none":
		var signature_b64: String = sig.get("signature", "")
		var public_key_pem: String = sig.get("public_key", "")
		if signature_b64.is_empty() or public_key_pem.is_empty():
			zip.close()
			return VerifyResult.new(false, 8, "firma o clave publica vacia")
		var key := CryptoKey.new()
		var key_err: Error = key.load_from_string(public_key_pem, true)
		if key_err != OK:
			zip.close()
			return VerifyResult.new(false, 8, "no se pudo cargar la clave publica (err %d)" % key_err)
		var sig_bytes: PackedByteArray = Marshalls.base64_to_raw(signature_b64)
		# docs/24 §4: la firma cubre los 32 bytes raw de payload_sha256.
		# Crypto.verify() recibe el digest FINAL y NO lo vuelve a hashear; el
		# firmante debe usar Prehashed por el mismo motivo.
		var crypto := Crypto.new()
		var verify_ok: bool = crypto.verify(
			HashingContext.HASH_SHA256, _hex_to_bytes(payload_hash), sig_bytes, key)
		if not verify_ok:
			zip.close()
			return VerifyResult.new(false, 8, "firma RSA invalida")
	zip.close()
	return VerifyResult.new(true, 0, "firma verificada")

static func _read_zip_file(zip: ZIPReader, path: String) -> PackedByteArray:
	return zip.read_file(path)

static func _hash_zip_file(zip: ZIPReader, path: String) -> String:
	var data: PackedByteArray = _read_zip_file(zip, path)
	return _hash_bytes(data)

static func _hash_bytes(data: PackedByteArray) -> String:
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(data)
	return ctx.finish().hex_encode()

static func _hex_to_bytes(hex: String) -> PackedByteArray:
	# `int("0xff")` devuelve 0 en GDScript: la conversión de String a int no
	# interpreta el prefijo hexadecimal. Hay que usar `hex_to_int()`, o el
	# digest sale todo ceros y ninguna firma valida.
	var out: PackedByteArray = []
	for i in range(0, hex.length(), 2):
		out.append(("0x" + hex.substr(i, 2)).hex_to_int())
	return out

static func _sha256_string(text: String) -> String:
	return _hash_bytes(text.to_utf8_buffer())

static func _build_canonical_payload(sig_files: Array) -> String:
	var lines: PackedStringArray = []
	for item in sig_files:
		var file_path: String = item.get("path", "")
		var file_hash: String = item.get("sha256", "")
		lines.append("%s  %s" % [file_hash, file_path])
	lines.sort()
	var payload: String = "\n".join(lines)
	if not payload.is_empty():
		payload += "\n"
	return payload

static func _files_match(zip_files: PackedStringArray, sig_files: Array) -> bool:
	# docs/24 §3: el payload cubre todos los archivos EXCEPTO signature.json.
	var zip_set: Dictionary = {}
	for f: String in zip_files:
		if f == "signature.json":
			continue
		zip_set[f] = true
	if zip_set.size() != sig_files.size():
		return false
	for item in sig_files:
		var fp: String = item.get("path", "")
		if not zip_set.has(fp):
			return false
	return true
