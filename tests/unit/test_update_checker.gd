## Tests de `core/updater/update_checker.gd`.
##
## Todo offline: la lógica de decisión y de parseo no toca la red. La parte de
## red (`update_service.gd`) se verifica en dispositivo por logcat.
extends "res://tests/framework/test_case.gd"

const UpdateChecker := preload("res://core/updater/update_checker.gd")

func run() -> void:
	_test_parse_release_ok()
	_test_parse_release_sin_apk()
	_test_parse_release_invalida()
	_test_decide()
	_test_describe()
	_test_releases_url()


func _release_json(tag: String, with_apk: bool = true) -> String:
	var assets: String = ""
	if with_apk:
		assets = '{"name":"gale.apk","browser_download_url":"https://example/gale.apk","size":28401664}'
	return '{"tag_name":"%s","html_url":"https://example/releases/%s","prerelease":false,"assets":[%s]}' % [tag, tag, assets]


func _test_parse_release_ok() -> void:
	var r: Dictionary = UpdateChecker.parse_release(_release_json("v0.2.0"))
	check_ok(r.ok, "parsea release válida")
	check(r.version, "v0.2.0", "conserva el tag como versión")
	check(r.apk_url, "https://example/gale.apk", "encuentra el asset .apk")
	check(r.apk_size, 28401664, "tamaño del asset")
	check(r.prerelease, false, "marca de prerelease")


func _test_parse_release_sin_apk() -> void:
	var r: Dictionary = UpdateChecker.parse_release(_release_json("v0.2.0", false))
	check_ok(r.ok, "release sin APK sigue siendo válida")
	check(r.apk_url, "", "apk_url vacía cuando no hay asset")


func _test_parse_release_invalida() -> void:
	check_ok(not UpdateChecker.parse_release("no soy json").ok, "rechaza texto que no es JSON")
	check_ok(not UpdateChecker.parse_release('{"assets":[]}').ok, "rechaza release sin tag_name")
	check_ok(not UpdateChecker.parse_release('{"tag_name":"ultima"}').ok, "rechaza tag que no es semver")


func _test_decide() -> void:
	check(UpdateChecker.decide("0.1.0", "v0.2.0"), UpdateChecker.Status.UPDATE_AVAILABLE, "menor que la publicada")
	check(UpdateChecker.decide("0.2.0", "v0.2.0"), UpdateChecker.Status.UP_TO_DATE, "igual a la publicada")
	check(UpdateChecker.decide("0.3.0", "v0.2.0"), UpdateChecker.Status.AHEAD, "build local por delante")
	check(UpdateChecker.decide("basura", "v0.2.0"), UpdateChecker.Status.ERROR, "versión instalada inválida")
	check(UpdateChecker.decide("0.1.0", "basura"), UpdateChecker.Status.ERROR, "versión publicada inválida")
	# Una prerelease es menor que la final: 1.0.0-rc.1 no debe disparar update
	# contra 1.0.0-rc.1, pero sí contra 1.0.0.
	check(UpdateChecker.decide("1.0.0-rc.1", "v1.0.0"), UpdateChecker.Status.UPDATE_AVAILABLE, "rc anterior al final")


func _test_describe() -> void:
	check_ok(UpdateChecker.describe(UpdateChecker.Status.UP_TO_DATE).contains("al día"), "describe al día")
	check_ok(UpdateChecker.describe(UpdateChecker.Status.UPDATE_AVAILABLE, "v0.2.0").contains("v0.2.0"), "describe nombra la versión")
	check_ok(UpdateChecker.describe(UpdateChecker.Status.DISABLED).contains("desactivada"), "describe desactivada")


func _test_releases_url() -> void:
	check(
		UpdateChecker.releases_url("guideahon", "Proyect-Gale"),
		"https://api.github.com/repos/guideahon/Proyect-Gale/releases/latest",
		"URL de la API de releases"
	)
