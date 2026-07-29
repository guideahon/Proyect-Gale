## UpdateService — parte de red de la comprobación de actualizaciones.
##
## Consulta la API pública de releases de GitHub y emite el resultado. No
## descarga ni instala nada: Android exige el diálogo del instalador del
## sistema y su comportamiento dentro de Horizon OS todavía no está verificado.
##
## Privacidad: una comprobación de versión es un beacon (IP + momento). Por eso
## está detrás de un flag y no envía ningún dato del usuario ni identificador.
## Ver `docs/27_ACTUALIZACIONES_OTA.md`.
extends Node

const UpdateChecker := preload("res://core/updater/update_checker.gd")

const OWNER := "guideahon"
const REPO := "Proyect-Gale"
const TIMEOUT_SECONDS := 10.0

## Resultado: (status, latest_version, url, apk_url).
signal check_finished(status: int, latest_version: String, url: String, apk_url: String)

var enabled: bool = true
var current_version: String = ""

var _request: HTTPRequest


func _ready() -> void:
	if current_version.is_empty():
		current_version = str(ProjectSettings.get_setting("application/config/version", "0.0.0"))
	# Comprobación al arrancar. En cuanto exista interfaz, esto pasa a ser
	# opt-in explícito del usuario, como exige docs/27.
	check.call_deferred()


## Lanza la comprobación. El resultado llega por `check_finished`.
func check() -> void:
	if not enabled:
		_emit(UpdateChecker.Status.DISABLED, "", "", "")
		return

	if _request == null:
		_request = HTTPRequest.new()
		_request.timeout = TIMEOUT_SECONDS
		add_child(_request)
		_request.request_completed.connect(_on_request_completed)

	var url: String = UpdateChecker.releases_url(OWNER, REPO)
	# La API de GitHub exige User-Agent. No se envía ningún dato del usuario.
	var headers: PackedStringArray = [
		"User-Agent: ProjectGale-UpdateChecker",
		"Accept: application/vnd.github+json",
	]
	var err: Error = _request.request(url, headers)
	if err != OK:
		push_warning("UpdateService: no se pudo iniciar la consulta (error %d)" % err)
		_emit(UpdateChecker.Status.ERROR, "", "", "")


func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS:
		push_warning("UpdateService: fallo de red (result %d)" % result)
		_emit(UpdateChecker.Status.ERROR, "", "", "")
		return
	if response_code == 404:
		# Repositorio sin releases todavía: no es un error del usuario.
		_emit(UpdateChecker.Status.UP_TO_DATE, "", "", "")
		return
	if response_code != 200:
		push_warning("UpdateService: HTTP %d" % response_code)
		_emit(UpdateChecker.Status.ERROR, "", "", "")
		return

	var release: Dictionary = UpdateChecker.parse_release(body.get_string_from_utf8())
	if not release.ok:
		push_warning("UpdateService: %s" % release.error)
		_emit(UpdateChecker.Status.ERROR, "", "", "")
		return

	var status: int = UpdateChecker.decide(current_version, release.version)
	_emit(status, release.version, release.url, release.apk_url)


func _emit(status: int, version: String, url: String, apk_url: String) -> void:
	print("UpdateService: instalada %s — %s" % [current_version, UpdateChecker.describe(status, version)])
	if not url.is_empty():
		print("UpdateService: release %s" % url)
	check_finished.emit(status, version, url, apk_url)
