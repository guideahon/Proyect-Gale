# Formatos de contenido

## Manifiesto

El manifiesto define identidad, compatibilidad, dependencias, licencia y perfil de rendimiento. Ver `schemas/mod_manifest.schema.json`.

## Armas

Una arma declara:

- ID;
- nombre localizado;
- tipo;
- escena visual;
- daño;
- masa percibida;
- velocidad efectiva máxima;
- cooldown;
- habilidades;
- perfil de audio;
- coste estimado.

## Habilidades

Una habilidad es un conjunto de triggers, condiciones y acciones. El motor valida cada acción antes de registrar el contenido.

## Diálogo

El diálogo es un grafo de nodos con:

- texto localizado;
- speaker;
- condiciones;
- opciones;
- acciones;
- siguiente nodo.

## Misiones

Una misión contiene etapas, objetivos, recompensas y eventos. Cada etapa puede migrar entre versiones mediante IDs estables.

## Islas

Una isla declara:

- posición solicitada;
- HLOD lejano;
- HLOD medio;
- sectores;
- navegación;
- spawn tables;
- música;
- entorno;
- presupuesto.

## Localización

Usar archivos PO o catálogos equivalentes. Las claves nunca son el texto visible.

```text
dialogue.fisher.start
quest.lost_compass.title
item.storm_sword.name
```

## Partidas guardadas

No guardar rutas ni índices. Guardar IDs:

```json
{
  "definition": "guideahon:storm_sword",
  "instance_id": "item_28917",
  "state": {
    "durability": 82
  }
}
```

## Migraciones

Un mod puede renombrar IDs o transformar estado simple. Las migraciones complejas con código sólo funcionan en modo desarrollador.

## Archivos de ejemplo

Ver `examples/sample_mod/`.
