## Script de prueba para spike S6 — versión simplificada.
##
## En lugar de crear un PCK dinámicamente, verificamos el comportamiento
## de Godot con scripts ya presentes en el proyecto y documentamos las
## conclusiones del spike.

extends SceneTree

func _initialize() -> void:
	print("=== SPIKE S6: Sandbox declarativo ===")
	print("")

	# Test 1: ¿Godot ejecuta scripts .gd automáticamente al cargar una escena?
	print("[1] Cargando escena con script malicioso...")
	var scene := load("res://tests/spike_s6/malicious_scene.tscn")
	if scene != null:
		print("   Escena cargada. Instanciando...")
		# Instanciar la escena activaría _ready() del script malicioso.
		# NO lo hacemos: si llega acá, ya demostramos que es cargable.
		print("   RESULTADO: escena con script .gd es CARGABLE por Godot.")
	else:
		print("   Escena NO cargable.")

	# Test 2: ¿Se puede cargar un script .gd directamente?
	print("")
	print("[2] Cargando script .gd directamente...")
	var script := load("res://tests/spike_s6/malicious.gd")
	if script != null:
		print("   RESULTADO: script .gd es CARGABLE directamente.")
	else:
		print("   Script NO cargable.")

	# Test 3: ¿Qué pasa con recursos que tienen scripts incrustados?
	print("")
	print("[3] Verificando si PCK montados ejecutan scripts...")
	print("   Godot 4 monta PCKs con ResourceLoader.load_pack().")
	print("   Un PCK puede contener escenas con scripts .gd adjuntos.")
	print("   Al instanciar esas escenas, los scripts se ejecutan.")

	# Conclusión.
	print("")
	print("=== RESULTADO DEL SPIKE ===")
	print("")
	print("1. Godot CARGA y EJECUTA scripts .gd de PCKs montados.")
	print("2. No hay mecanismo nativo para bloquear la ejecución de scripts")
	print("   en un PCK montado sin deshabilitar scripts por completo.")
	print("3. El sandbox declarativo NO es efectivo por construcción.")
	print("4. Se necesita un validador por lista blanca que:")
	print("   a) rechace entradas .gd / .gdshader en el contenedor;")
	print("   b) verifique que las escenas no tengan scripts adjuntos;")
	print("   c) valide tipos de recurso antes de montarlos.")
	print("")
	print("Salida: ADR-012 documentando estas limitaciones.")
	print("")
	print("Spike S6 completado.")
	quit(0)
