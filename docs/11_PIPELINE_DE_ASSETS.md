# Pipeline de assets

## Objetivo

Todo asset externo o comunitario debe atravesar un pipeline reproducible antes de ingresar al juego.

## Directorios

```text
assets/
├── source/
├── working/blender/
├── generated/
│   ├── meshes/
│   ├── collisions/
│   ├── lod/
│   ├── impostors/
│   ├── hlod/
│   └── atlases/
└── manifests/
```

## Proceso

1. Registrar fuente y licencia.
2. Normalizar escala y ejes.
3. Aplicar paleta y dirección artística.
4. Eliminar geometría oculta.
5. Reducir materiales.
6. Crear o corregir UV.
7. Crear atlas.
8. Generar LOD.
9. Crear collider simple.
10. Hornear lightmaps o vertex colors.
11. Generar impostor.
12. Crear HLOD cuando corresponda.
13. Exportar GLB.
14. Validar presupuesto.
15. Registrar hash.

## Scripts de Blender previstos

- `normalize_scale.py`
- `merge_materials.py`
- `palette_remap.py`
- `remove_hidden_faces.py`
- `generate_lods.py`
- `generate_colliders.py`
- `create_lightmap_uv.py`
- `build_atlas.py`
- `export_glb.py`

## Reglas de colisión

- Árbol: cápsula o cilindro.
- Roca: convex hull simplificado.
- Edificio: cajas o malla muy simple.
- Terreno: malla sectorizada de colisión.
- Props pequeños: caja, esfera o cápsula.
- Vegetación decorativa: sin colisión.

## Reglas de materiales

- Prop: 1.
- Árbol: 1.
- Casa: 1–2.
- NPC: 1.
- Enemigo: 1.
- Barco: máximo 2.

## Estética

Los packs externos son materia prima, no producto terminado. Deben compartir:

- proporciones;
- paleta;
- shader;
- contraste;
- escala;
- densidad de detalle;
- diseño de silueta.

## Manifest de asset

Ver `templates/asset_manifest.example.json`.
