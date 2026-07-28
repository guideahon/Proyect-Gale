# Seguridad de mods

## Modelo de amenaza

Un mod puede intentar:

- ejecutar código malicioso;
- leer o escribir datos;
- degradar rendimiento;
- agotar memoria;
- sobrescribir recursos;
- corromper saves;
- engañar al usuario con metadatos;
- incluir contenido sin licencia.

## Niveles

### Declarativo

Sólo JSON, recursos validados y assets permitidos. Es el modo recomendado.

### Scripted

GDScript habilitado por usuario en modo desarrollador. Advertencia explícita.

### Native fork

Código C++ requiere compilar otra versión del APK.

## Restricciones declarativas

- schema estricto;
- límites de tamaño;
- whitelist de acciones;
- familias de shader autorizadas;
- límites de entidades;
- paths namespaced;
- sin reemplazo de `res://core`;
- sin red;
- sin filesystem arbitrario.

## Firmas

Las firmas son opcionales inicialmente. El catálogo comunitario puede publicar hashes y firma del índice. Una firma indica procedencia, no seguridad absoluta.

## Instalación

Flujo:

1. leer manifest sin montar contenido;
2. verificar tamaño;
3. validar nombre y paths;
4. verificar hash;
5. mostrar permisos/capacidades;
6. copiar a directorio de mods;
7. activar al reiniciar.

## Saves

Antes de ejecutar una migración:

- crear backup;
- validar versión;
- aplicar en copia;
- comprobar estructura;
- reemplazar de forma atómica.

## Crash loop

El juego registra el último mod activado y, tras fallos consecutivos, inicia en modo seguro.

## Privacidad

El juego no necesita telemetría obligatoria. Los reportes enviados por usuarios deben ser voluntarios y mostrar qué datos incluyen.
