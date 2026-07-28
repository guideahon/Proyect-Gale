# Arquitectura de mods

## Principio

El contenido oficial se distribuye mediante los mismos mecanismos que el contenido comunitario.

```text
Game.apk
├── Core
├── VR Runtime
├── Renderer
├── Mod Loader
├── Registries
└── official.base.pck
```

## Tipos

### Mods declarativos

Permitidos por defecto:

- assets;
- objetos;
- armas;
- habilidades;
- enemigos configurables;
- NPC;
- diálogos;
- misiones;
- mapas;
- islas;
- mazmorras;
- audio;
- traducciones.

No ejecutan código arbitrario.

### Mods con GDScript

Disponibles en modo desarrollador. Pueden alterar comportamiento avanzado, pero no tienen garantía de seguridad, estabilidad o rendimiento.

### Mods nativos

No se cargan como extensión arbitraria en el APK público. Quien necesite C++ debe crear un fork y compilar su propio APK.

## Formato `.gmod`

```text
my_mod.gmod
├── manifest.json
├── content.pck
├── icon.webp
├── README.md
├── LICENSE
├── CHANGELOG.md
└── signature.json
```

## Directorios

```text
user://
├── mods/
├── mod_cache/
├── saves/
├── logs/
└── mod_config.json
```

## Orden de carga

1. Core.
2. `official.base`.
3. `official.campaign`.
4. dependencias.
5. mods del usuario en orden resuelto.
6. patches y overrides explícitos.

## Namespaces

IDs obligatorios:

```text
official:sword_basic
guideahon:storm_sword
author.mod:content_id
```

## Contenido oficial

No se permite hardcodear directamente una espada, misión o isla dentro del núcleo. El núcleo implementa capacidad; los paquetes registran contenido.

## Compatibilidad

Cada mod declara:

- versión de formato;
- versión de Mod API;
- rango de versión de juego;
- dependencias;
- conflictos;
- orden;
- perfil de rendimiento.

## Modo seguro

Ante un fallo:

- iniciar sólo con contenido oficial;
- mostrar mod causante;
- permitir desactivarlo;
- conservar su estado opaco en la partida;
- no borrar automáticamente contenido.
