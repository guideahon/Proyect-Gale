# Presupuestos de rendimiento

## Principio

A 120 Hz cada cuadro dispone de aproximadamente 8,33 ms. El proyecto no debe utilizar todo ese tiempo en una escena ideal; necesita margen para variación térmica, streaming, guardado, combate y picos del sistema.

## Quest 2 — modo estricto 120 Hz

| Indicador | Objetivo |
|---|---:|
| Tiempo CPU P95 | ≤ 6,5 ms |
| Tiempo GPU P95 | ≤ 6,5 ms |
| Tiempo CPU/GPU P99 | ≤ 8,0 ms |
| Draw calls visibles | 50–80 iniciales |
| Triángulos visibles | 100.000–180.000 iniciales |
| Enemigos de combate | 3–5 |
| NPC activos | 4–8 |
| Rigid bodies activos | 12–20 |
| Luces dinámicas | 1 direccional |
| Sombras dinámicas | 0–1 zona cercana |
| MSAA | 2× inicial |
| Render scale | 0,60–0,75 inicial |
| Prueba térmica | 30 minutos mínimos |

Estos valores son presupuestos de partida, no límites universales. Se modifican sólo con evidencia en hardware.

## Quest 1 — 72 Hz

| Indicador | Objetivo |
|---|---:|
| Tiempo CPU/GPU P95 | ≤ 11,5 ms |
| Tiempo CPU/GPU P99 | ≤ 13,0 ms |
| Draw calls | 50–90 |
| Enemigos activos | 3–5 |
| Render scale | perfil específico |

## Presupuesto de contenido

### Geometría LOD0

| Tipo | Triángulos recomendados |
|---|---:|
| Árbol grande | 600–1.200 |
| Roca | 100–500 |
| Casa modular | 1.000–3.000 |
| NPC | 2.500–4.500 |
| Enemigo común | 2.000–4.000 |
| Mano del jugador | 1.000–2.000 |
| Arma | 200–800 |
| Barco | 2.000–5.000 |

### Texturas

- Props: 128–256 px.
- Vegetación: 256–512 px.
- Personajes: 512 px.
- Edificios: atlas de 1024 px.
- Elementos excepcionales: hasta 1024 px.
- 2K sólo mediante excepción documentada.
- 4K y 8K prohibidas en perfil Quest.

## Reglas de merge

Toda pull request visual debe registrar:

- captura de la escena de prueba;
- CPU/GPU frame time;
- draw calls;
- triángulos;
- memoria de texturas;
- cantidad de materiales;
- variación respecto de `main`.

Una función que cumple visualmente pero rompe el presupuesto no se considera terminada.

## Niveles de certificación de mods

- `quest2_120_certified`: benchmark y validaciones aprobados.
- `quest_compatible`: formato válido, sin garantía de 120 Hz.
- `developer_unrestricted`: scripts o shaders arbitrarios, sin garantías.
