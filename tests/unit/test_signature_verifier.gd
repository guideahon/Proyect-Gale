## Tests de signature_verifier.gd y key_store.gd.
extends "res://tests/framework/test_case.gd"

func run() -> void:
	DirAccess.remove_absolute("user://mod_config.json")
	_test_canonical_payload_format()
	_test_hash_bytes()
	_test_files_match_excludes_signature()
	_test_files_match_extra_rejected()
	_test_files_match_missing_rejected()
	_test_e2e_valid_signed_package()
	_test_e2e_tampered_byte_rejected_at_step6()
	_test_e2e_extra_file_rejected_at_step2()
	_test_e2e_integrity_only_passes()
	_test_key_store_new_key()
	_test_key_store_key_changed()
	_test_key_store_official_mismatch()
	_test_key_store_official_rejected()

func _test_canonical_payload_format() -> void:
	var verifier: Script = load("res://core/mods/signature_verifier.gd")
	var files: Array = []
	files.append({"path": "content.pck", "sha256": "aaa"})
	files.append({"path": "manifest.json", "sha256": "bbb"})
	var payload: String = verifier._build_canonical_payload(files)
	var expected: String = "aaa  content.pck\nbbb  manifest.json\n"
	check(payload, expected, "payload canonico ordenado correctamente")

func _test_hash_bytes() -> void:
	var verifier: Script = load("res://core/mods/signature_verifier.gd")
	var hash: String = verifier._hash_bytes("test".to_utf8_buffer())
	check_ok(hash.length() == 64, "SHA-256 produce 64 caracteres hex")
	check_ok(hash != "0".repeat(64), "hash no es todo ceros")

func _test_files_match_excludes_signature() -> void:
	var verifier: Script = load("res://core/mods/signature_verifier.gd")
	var zip_files: PackedStringArray = ["manifest.json", "content.pck", "signature.json"]
	var sig_files: Array = []
	sig_files.append({"path": "manifest.json", "sha256": "a"})
	sig_files.append({"path": "content.pck", "sha256": "b"})
	var match: bool = verifier._files_match(zip_files, sig_files)
	check_ok(match, "signature.json excluido de la comparacion (E3)")

func _test_files_match_extra_rejected() -> void:
	var verifier: Script = load("res://core/mods/signature_verifier.gd")
	var zip_files: PackedStringArray = ["manifest.json", "content.pck", "signature.json", "malicious.gd"]
	var sig_files: Array = []
	sig_files.append({"path": "manifest.json", "sha256": "a"})
	sig_files.append({"path": "content.pck", "sha256": "b"})
	var match: bool = verifier._files_match(zip_files, sig_files)
	check_ok(not match, "rechaza archivo extra no listado")

func _test_files_match_missing_rejected() -> void:
	var verifier: Script = load("res://core/mods/signature_verifier.gd")
	var zip_files: PackedStringArray = ["manifest.json", "signature.json"]
	var sig_files: Array = []
	sig_files.append({"path": "manifest.json", "sha256": "a"})
	sig_files.append({"path": "content.pck", "sha256": "b"})
	var match: bool = verifier._files_match(zip_files, sig_files)
	check_ok(not match, "rechaza archivo faltante en la lista")

func _test_e2e_valid_signed_package() -> void:
	var verifier: Script = load("res://core/mods/signature_verifier.gd")
	var result: Variant = verifier.verify("res://tests/data/e2e_valid.gmod")
	check_ok(result.ok, "paquete firmado valido pasa entero")
	check(result.step, 0, "sin fallos")

func _test_e2e_tampered_byte_rejected_at_step6() -> void:
	var verifier: Script = load("res://core/mods/signature_verifier.gd")
	var result: Variant = verifier.verify("res://tests/data/e2e_tampered.gmod")
	check_ok(not result.ok, "paquete alterado rechazado")
	check(result.step, 6, "rechazo en paso 6 (integridad), no en 8 (firma)")

func _test_e2e_extra_file_rejected_at_step2() -> void:
	# docs/24 §5: el orden de rechazo es estructura primero (paso 2),
	# luego firma (paso 5). package_reader rechaza .gd por lista blanca
	# antes de que signature_verifier llegue a comparar archivos.
	var verifier: Script = load("res://core/mods/signature_verifier.gd")
	var result: Variant = verifier.verify("res://tests/data/e2e_extra.gmod")
	check_ok(not result.ok, "paquete con archivo extra rechazado")
	check(result.step, 2, "rechazo en paso 2 (estructura), antes de paso 5 (firma)")

func _test_e2e_integrity_only_passes() -> void:
	var verifier: Script = load("res://core/mods/signature_verifier.gd")
	var result: Variant = verifier.verify("res://tests/data/e2e_none.gmod")
	check_ok(result.ok, "paquete con algorithm=none pasa (integridad solo)")
	check(result.step, 0, "sin fallos")

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
	var result: Dictionary = ks.verify_trust("official.base", "another_key", "Nobody", "key3")
	check(result.state, 3, "rechaza clave distinta para official.*")
