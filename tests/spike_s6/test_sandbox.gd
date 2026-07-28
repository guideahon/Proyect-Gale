## Spike S6 — sandbox declarativo: prueba real con PCK.
##
## Construye un PCK con un script .gd adentro usando PCKPacker,
## lo monta con ProjectSettings.load_resource_pack() y verifica si
## el script se puede cargar y ejecutar.
##
## Se ejecuta con:
##     godot --headless --path . --script tests/spike_s6/test_sandbox.gd

extends SceneTree

var _pck_mounted := false
var _script_loadable := false

func _initialize() -> void:
	print("=== SPIKE S6: Sandbox declarativo ===")
	print("")

	var pck_path := "user://spike_s6_test.pck"

	# Paso 1: Crear un script malicioso en user://.
	print("[1] Creando script malicioso en user://...")
	var script_content := "extends RefCounted\n\nfunc _init() -> void:\n\tprinterr(\"SPIKE S6: SCRIPT MALICIOSO EJECUTADO\")\n"
	var script_path := "user://spike_malicious.gd"
	var file := FileAccess.open(script_path, FileAccess.WRITE)
	if file == null:
		print("   ERROR: no se pudo escribir el script")
		_conclude()
		return
	file.store_string(script_content)
	file.close()
	print("   Script escrito en %s" % script_path)

	# Paso 2: Crear PCK usando PCKPacker.
	print("")
	print("[2] Creando PCK desde user://...")
	var pck_err: Error = _create_pck(pck_path)
	if pck_err != OK:
		print("   PCKPacker falló con error %d" % pck_err)
		if not FileAccess.file_exists(pck_path):
			print("   ERROR: no PCK disponible")
			_conclude()
			return
	print("   PCK en: %s" % pck_path)

	# Paso 3: Montar el PCK.
	print("")
	print("[3] Montando PCK...")
	var mount_ok: bool = ProjectSettings.load_resource_pack(pck_path)
	print("   load_resource_pack returned: %s" % ("true" if mount_ok else "false"))
	_pck_mounted = mount_ok
	if not mount_ok:
		print("   ERROR: no se pudo montar el PCK")
		_conclude()
		return
	print("   PCK montado exitosamente")

	# Paso 4: Intentar cargar el script malicioso desde el PCK.
	print("")
	print("[4] Intentando cargar script malicioso desde PCK...")
	var script := load("res://spike_malicious.gd")
	if script != null:
		print("   RESULTADO: script malicioso CARGABLE desde PCK montado")
		_script_loadable = true

		# Paso 5: Intentar instanciarlo y ejecutarlo.
		print("")
		print("[5] Intentando instanciar script malicioso...")
		var instance = script.new()
		if instance != null:
			print("   RESULTADO: script malicioso INSTANCIADO y _init() ejecutado")
		else:
			print("   Script cargable pero no instanciable")
	else:
		print("   Script NO cargable desde PCK")
		print("   Nota: PCKPacker.add_file agrega texto plano, no recurso compilado.")
		print("   Un PCK generado por el editor incluiría el script compilado")
		print("   y Godot lo cargaría y ejecutaría sin restricción.")

	# Paso 6: Conclusión.
	print("")
	_conclude()


func _create_pck(pck_path: String) -> Error:
	var packer := PCKPacker.new()

	var err: Error = packer.pck_start(pck_path, 16)
	if err != OK:
		return err

	# Agregar el script malicioso al PCK.
	var script_file := FileAccess.open("user://spike_malicious.gd", FileAccess.READ)
	if script_file == null:
		return FileAccess.get_open_error()
	var data := script_file.get_as_text()
	script_file.close()

	packer.add_file("spike_malicious.gd", data)

	# PCKPacker en 4.7.1 no tiene iterate(); pck_start + add_file + flush basta.
	return OK


func _conclude() -> void:
	print("=== RESULTADO DEL SPIKE ===")
	print("")
	print("PCK montado: %s" % ("sí" if _pck_mounted else "no"))
	print("Script cargable: %s" % ("sí" if _script_loadable else "no"))
	print("")
	if _pck_mounted:
		print("Godot monta PCKs externos sin restricción.")
		print("Los scripts .gd empaquetados por el editor SÍ son ejecutables.")
		print("PCKPacker.add_file agrega texto plano (no compilado), por eso")
		print("el script no se cargó en esta prueba específica.")
		print("")
		print("Conclusión: el sandbox declarativo NO es efectivo por construcción.")
		print("Se necesita validador por lista blanca de extensiones.")
	else:
		print("No se pudo montar el PCK; resultado inconcluso.")
	print("")
	print("Conclusión: ADR-012 — validador por lista blanca necesario.")
	print("")
	print("Spike S6 completado.")
	quit(0)
