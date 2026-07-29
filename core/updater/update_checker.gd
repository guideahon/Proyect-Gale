## UpdateChecker — lógica pura de comprobación de versiones.
##
## No hace red: recibe el JSON de la API de releases y decide. La parte de red
## vive en `update_service.gd`, para que esta se pueda testear sin conexión.
##
## Alcance deliberado: el juego **avisa**, no instala. Android no permite que
## una app se reemplace a sí misma sin el diálogo del instalador del sistema, y
## el comportamiento de ese diálogo dentro de Horizon OS no está verificado.
## Ver `docs/27_ACTUALIZACIONES_OTA.md`.
extends RefCounted

const Semver := preload("res://core/mods/semver.gd")

enum Status {
	DISABLED,          ## El usuario no activó la comprobación.
	UP_TO_DATE,        ## La versión instalada es la última.
	UPDATE_AVAILABLE,  ## Hay una versión mayor publicada.
	AHEAD,             ## La instalada es mayor que la publicada (build local).
	ERROR,             ## No se pudo determinar.
}


## Extrae los datos que nos interesan de la respuesta de la API de GitHub.
## Devuelve `{ok, version, tag, url, apk_url, apk_size, error}`.
static func parse_release(json_text: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(json_text)
	if not parsed is Dictionary:
		return {"ok": false, "error": "respuesta no es un objeto JSON"}

	var tag: String = parsed.get("tag_name", "")
	if tag.is_empty():
		return {"ok": false, "error": "release sin tag_name"}

	# Los tags del proyecto son `v1.2.3`; semver.gd ya tolera la `v` inicial.
	var version: String = tag
	if not Semver.is_valid(version):
		return {"ok": false, "error": "tag '%s' no es una versión semver" % tag}

	var apk_url: String = ""
	var apk_size: int = 0
	for asset in parsed.get("assets", []):
		if not asset is Dictionary:
			continue
		var name: String = asset.get("name", "")
		if name.ends_with(".apk"):
			apk_url = asset.get("browser_download_url", "")
			apk_size = int(asset.get("size", 0))
			break

	return {
		"ok": true,
		"error": "",
		"tag": tag,
		"version": version,
		"url": parsed.get("html_url", ""),
		"apk_url": apk_url,
		"apk_size": apk_size,
		"prerelease": bool(parsed.get("prerelease", false)),
	}


## Compara la versión instalada contra la publicada.
static func decide(current_version: String, latest_version: String) -> Status:
	if not Semver.is_valid(current_version) or not Semver.is_valid(latest_version):
		return Status.ERROR
	var cmp: int = Semver.compare(current_version, latest_version)
	if cmp < 0:
		return Status.UPDATE_AVAILABLE
	if cmp > 0:
		return Status.AHEAD
	return Status.UP_TO_DATE


## Texto legible para el log y para la interfaz.
static func describe(status: Status, latest_version: String = "") -> String:
	match status:
		Status.DISABLED:
			return "comprobación de actualizaciones desactivada"
		Status.UP_TO_DATE:
			return "al día"
		Status.UPDATE_AVAILABLE:
			return "hay una versión nueva: %s" % latest_version
		Status.AHEAD:
			return "la versión instalada (%s) es posterior a la publicada" % latest_version
		Status.ERROR:
			return "no se pudo comprobar"
	return "estado desconocido"


## URL de la API de releases para un repositorio público.
static func releases_url(owner: String, repo: String) -> String:
	return "https://api.github.com/repos/%s/%s/releases/latest" % [owner, repo]
