# Guía de contribución

## Antes de comenzar

1. Leer la visión.
2. Revisar decisiones arquitectónicas.
3. Buscar issue existente.
4. Para cambios grandes, abrir RFC.
5. No iniciar producción masiva sin presupuesto.

## Pull request

Debe incluir:

- problema;
- solución;
- alcance;
- pruebas;
- impacto de rendimiento;
- impacto de compatibilidad;
- capturas o video cuando corresponda;
- licencias de assets.

## Contenido visual

Adjuntar:

- fuente;
- licencia;
- archivo fuente;
- LOD;
- collider;
- atlas;
- impostor;
- HLOD si corresponde;
- benchmark.

## Código

- Typed GDScript donde sea razonable.
- Funciones pequeñas.
- No dependencias ocultas.
- IDs, no rutas hardcodeadas.
- No `_process()` innecesario.
- Errores recuperables.
- Tests para registries y serialización.

## Mods

Los mods enviados al catálogo comunitario deben:

- tener namespace;
- pasar schemas;
- declarar licencia;
- no contener propiedad intelectual no autorizada;
- incluir icono;
- incluir changelog;
- declarar perfil de rendimiento.

## Conducta

- Crítica técnica respetuosa.
- Decisiones documentadas.
- No ridiculizar principiantes.
- Priorizar evidencia y benchmarks.
- Evitar discusiones de estilo que no afecten mantenibilidad.

## Primeras contribuciones sugeridas

- traducciones;
- pruebas;
- documentación;
- props simples;
- sonidos CC0;
- plantillas;
- ejemplos de armas declarativas;
- mejoras del validador.
