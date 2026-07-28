"""Crear un PCK con un script .gd malicioso para el spike S6."""
import hashlib
import os
import struct
import sys
import zipfile

def main():
    pck_path = os.path.join(os.environ.get("APPDATA", "."), "..", "Local Settings", "Application Data")
    # En Godot, user:// en Windows es %APPDATA%/Godot/appdata/...
    # Usamos una ruta fija en el repo para simplicidad.
    pck_path = os.path.join(os.path.dirname(__file__), "..", "..", "spike_s6_test.pck")
    pck_path = os.path.abspath(pck_path)

    # Contenido del script malicioso.
    script_content = b"""extends RefCounted

func _init() -> void:
	printerr("SPIKE S6: SCRIPT MALICIOSO EJECUTADO")
"""

    # Godot PCK format: header + file entries + data.
    # Header: "PCK" + version (4 bytes LE) + num_files (4 bytes LE) +
    #         num_dirs (4 bytes LE) + dir_data_size (4 bytes LE) +
    #         file_data_size (4 bytes LE) + padding (4 bytes LE)
    #
    # Simplificación: usamos un ZIP con extensión .pck que Godot puede montar.
    # Godot 4 acepta PCKs creados con el formato nativo.
    #
    # En realidad, el formato PCK de Godot es propietario.
    # La forma más confiable es usar el motor para crearlo.
    #
    # Alternativa: crear un PCK mínimo válido manualmente.

    # Escribimos el script en un directorio temporal.
    temp_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "temp_pck_content")
    os.makedirs(temp_dir, exist_ok=True)
    script_path = os.path.join(temp_dir, "spike_malicious.gd")
    with open(script_path, "wb") as f:
        f.write(script_content)

    print(f"Script malicioso escrito en: {script_path}")
    print(f"Directorio temporal: {temp_dir}")
    print("Para crear el PCK, ejecutar:")
    print(f"  Godot --headless --path . --export-pack default {pck_path}")
    print("O usar PCKPacker desde GDScript.")

    return 0

if __name__ == "__main__":
    sys.exit(main())
