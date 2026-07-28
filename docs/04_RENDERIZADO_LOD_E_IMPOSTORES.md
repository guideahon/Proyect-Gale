# Renderizado, LOD e impostores

## Pipeline visual

El mundo usa una cadena de representación:

1. geometría completa cercana;
2. LOD geométrico;
3. LOD extremadamente simplificado;
4. impostor multivista;
5. HLOD regional;
6. silueta de horizonte.

## Distancias iniciales

| Distancia | Representación |
|---:|---|
| 0–20 m | LOD0, física e interacción |
| 20–50 m | LOD1 |
| 50–100 m | LOD2 |
| 100–300 m | impostor multivista |
| 300–800 m | HLOD |
| >800 m | silueta de isla o montaña |

Las distancias finales se ajustan según tamaño proyectado y pruebas estereoscópicas.

## Billboards

### Billboard Y

Adecuado para árboles, postes y vegetación lejana. Gira alrededor del eje vertical y conserva orientación vertical.

### Planos cruzados

Dos o tres planos cruzados para arbustos y vegetación media. Aportan volumen barato, pero deben sectorizarse para reducir overdraw.

### Impostor multivista

Atlas de 8 o 16 vistas. El shader selecciona la vista más cercana. La primera implementación usa:

- albedo;
- alpha scissor;
- iluminación horneada;
- sin parallax;
- sin normal map para vegetación común.

### Impostor avanzado

Profundidad y normales se reservan para árboles gigantes, torres, barcos o rocas destacadas y sólo después de benchmark.

## HLOD

Los HLOD agrupan barrios, bosques, ruinas o una isla completa. El HLOD lejano debe:

- compartir atlas;
- eliminar interiores;
- hornear sombras;
- evitar scripts;
- evitar colisión;
- reducir materiales;
- conservar silueta y color.

## MultiMesh

La vegetación repetida se agrupa por sector:

```text
Sector_04_07
├── Trees_LOD0_MultiMesh
├── Trees_LOD1_MultiMesh
├── TreeImpostors_MultiMesh
├── Bushes_MultiMesh
└── Grass_MultiMesh
```

Nunca se crea un único MultiMesh para toda una isla.

## Alpha

La vegetación usa `alpha scissor` o dithering opaco. El alpha blending ordinario queda restringido porque aumenta overdraw, ordenamiento y fill rate.

## Shader toon

Familias autorizadas:

- `ToonOpaque`
- `ToonCutout`
- `ToonCharacter`
- `ToonWater`
- `ToonUnlit`
- `ToonImpostor`
- `ParticleSimple`

El perfil estricto no admite shaders comunitarios arbitrarios. Los mods cambian parámetros, texturas, ramps y colores.

## Océano

- Malla en anillos centrada en el jugador.
- Movimiento de vértices analítico.
- Olas sinusoidales limitadas.
- Color opaco y gradiente.
- Reflejo falso del cielo.
- Espuma con recorte.
- Sin reflexión planar.
- Sin refracción real.
- Sin simulación de fluidos.
