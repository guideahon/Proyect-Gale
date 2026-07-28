# Repositorio y CI

## Repositorios

```text
project-gale/
project-gale-modkit/
project-gale-api/
project-gale-example-mods/
project-gale-community-content/
```

## Estructura principal

```text
project-gale/
├── game/
├── core/
├── official_mods/
├── schemas/
├── tools/
├── tests/
├── benchmarks/
├── docs/
├── licenses/
├── .github/workflows/
├── LICENSE
├── THIRD_PARTY.md
└── README.md
```

## Ramas

- `main`: estable.
- `develop`: integración opcional.
- `feature/*`
- `fix/*`
- `release/*`

Se favorece trunk-based development con ramas cortas.

## Git LFS

Usar para:

- GLB;
- BLEND;
- audio;
- texturas fuente;
- APK;
- capturas grandes.

No usar para archivos JSON, GDScript, Markdown o schemas.

## CI

En cada pull request:

1. validar formato;
2. ejecutar tests;
3. validar schemas;
4. importar proyecto headless;
5. comprobar recursos faltantes;
6. construir mods de ejemplo;
7. exportar desktop de prueba;
8. generar reporte.

En tags:

1. exportar APK ARM64;
2. firmar;
3. calcular SHA-256;
4. crear release;
5. adjuntar APK, checksums y documentación;
6. publicar ModKit compatible.

## Commits

Formato sugerido:

```text
feat(modding): add dependency resolver
perf(render): split forest multimesh by sector
fix(save): preserve missing mod entities
docs(api): document ability action schema
```

## Releases

El juego y la Mod API tienen versiones relacionadas pero distintas. Un release indica:

- versión del juego;
- versión de Mod API;
- versión de formato `.gmod`;
- versión de Godot;
- hash de export templates.
