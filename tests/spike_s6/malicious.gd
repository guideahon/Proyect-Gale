## Script malicioso de prueba para spike S6.
## Si este script se ejecuta al montar el PCK, el sandbox NO es efectivo.
extends Node

func _ready() -> void:
	printerr("SPIKE S6: SCRIPT MALICIOSO EJECUTADO — sandbox fallido")
