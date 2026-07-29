## Tests de signature_verifier.gd y key_store.gd.
extends "res://tests/framework/test_case.gd"

func run() -> void:
	# Limpiar config de key_store para tests aislados.
	DirAccess.remove_absolute("user://mod_config.json")
	_test_canonical_payload_format()
	_test_hash_bytes()
	_test_files_match_exact()
	_test_files_match_extra_rejected()
	_test_files_match_missing_rejected()
	_test_key_store_new_key()
	_test_key_store_key_changed()
	_test_key_store_official_mismatch()
	_test_key_store_official_rejected()

func _test_canonical_payload_format() -> void:
	var verifier: Script = load("res://core/mods/signature_verifier.gd")
	var files: Array = []
	var f1: Dictionary = {"path": "content.pck", "sha256": "aaa"}
	var f2: Dictionary = {"path": "manifest.json", "sha256": "bbb"}
	files.append(f1)
	files.append(f2)
	var payload: String = verifier._build_canonical_payload(files)
	# Ordenado por ruta: content.pck < manifest.json
	var expected: String = "aaa  content.pck\nbbb  manifest.json\n"
	check(payload, expected, "payload canonico ordenado correctamente")

func _test_hash_bytes() -> void:
	var verifier: Script = load("res://core/mods/signature_verifier.gd")
	var hash: String = verifier._hash_bytes("test".to_utf8_buffer())
	check_ok(hash.length() == 64, "SHA-256 produce 64 caracteres hex")
	check_ok(hash != "0".repeat(64), "hash no es todo ceros")

func _test_files_match_exact() -> void:
	var verifier: Script = load("res://core/mods/signature_verifier.gd")
	var zip_files: PackedStringArray = ["manifest.json", "content.pck", "signature.json"]
	var sig_files: Array = []
	sig_files.append({"path": "manifest.json", "sha256": "a"})
	sig_files.append({"path": "content.pck", "sha256": "b"})
	sig_files.append({"path": "signature.json", "sha256": "c"})
	var match: bool = verifier._files_match(zip_files, sig_files)
	check_ok(match, "coincidencia exacta")

func _test_files_match_extra_rejected() -> void:
	var verifier: Script = load("res://core/mods/signature_verifier.gd")
	var zip_files: PackedStringArray = ["manifest.json", "content.pck", "signature.json", "malicious.gd"]
	var sig_files: Array = []
	sig_files.append({"path": "manifest.json", "sha256": "a"})
	sig_files.append({"path": "content.pck", "sha256": "b"})
	sig_files.append({"path": "signature.json", "sha256": "c"})
	var match: bool = verifier._files_match(zip_files, sig_files)
	check_ok(not match, "rechaza archivo extra no listado")

func _test_files_match_missing_rejected() -> void:
	var verifier: Script = load("res://core/mods/signature_verifier.gd")
	var zip_files: PackedStringArray = ["manifest.json", "content.pck", "signature.json"]
	var sig_files: Array = []
	sig_files.append({"path": "manifest.json", "sha256": "a"})
	sig_files.append({"path": "content.pck", "sha256": "b"})
	var match: bool = verifier._files_match(zip_files, sig_files)
	check_ok(not match, "rechaza archivo faltante en la lista")

func _test_key_store_new_key() -> void:
	var ks: Script = load("res://core/mods/key_store.gd")
	var result: Dictionary = ks.verify_trust("test.new_key", "abc123", "TestAuthor", "fake_key")
	check(result.state, 1, "estado NEW para primera clave")
	var result2: Dictionary = ks.verify_trust("test.new_key", "abc123", "TestAuthor", "fake_key")
	check(result2.state, 0, "estado OK para clave conocida")

func _test_key_store_key_changed() -> void:
	var ks: Script = load("res://core/mods/key_store.gd")
	var result: Dictionary = ks.verify_trust("test.key_changed", "xyz789", "Author1", "key1")
	check(result.state, 1, "primera clave registrada")
	var result2: Dictionary = ks.verify_trust("test.key_changed", "different", "Author2", "key2")
	check(result2.state, 2, "estado KEY_CHANGED para key_id distinto")

func _test_key_store_official_mismatch() -> void:
	var ks: Script = load("res://core/mods/key_store.gd")
	var result: Dictionary = ks.verify_trust("official.base", "official_key", "GaleTeam", "official_pem")
	check(result.state, 1, "primera clave oficial registrada")
	var result2: Dictionary = ks.verify_trust("official.base", "imposter", "Evil", "evil_pem")
	check(result2.state, 3, "estado OFFICIAL_MISMATCH para official.* con clave distinta")

func _test_key_store_official_rejected() -> void:
	var ks: Script = load("res://core/mods/key_store.gd")
	# official.base ya tiene clave registrada (del test anterior).
	# Una clave distinta debe dar OFFICIAL_MISMATCH.
	var result: Dictionary = ks.verify_trust("official.base", "another_key", "Nobody", "key3")
	check(result.state, 3, "rechaza clave distinta para official.*")
