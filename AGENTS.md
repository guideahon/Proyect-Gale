# AGENTS.md

Instrucciones operativas para agentes automáticos que trabajen en este repositorio. Un humano también puede seguirlas.

Si sólo vas a leer un archivo antes de empezar, que sea este. Después, `docs/25_CHECKLIST_DE_EJECUCION.md`.

---

## 1. Qué es este repositorio

Proyecto Gale: juego de aventura y exploración en VR, libre, con arquitectura centrada en mods. Godot 4.7.1 + OpenXR, objetivo Quest 2 a 120 Hz como modo estricto certificado por contenido.

Estado real: la especificación está completa y madura; el juego no existe todavía. Hay quince JSON Schemas, una librería de versiones con tests, herramientas de CI iniciales y ningún runtime. No asumas que hay código donde no lo hay: verificá antes de importar o llamar algo.

---

## 2. Orden de lectura

1. `docs/00_README.md` — objetivos y regla de oro.
2. `docs/23_PLAN_DE_IMPLEMENTACION.md` — plan, hitos, riesgos, decisiones abiertas.
3. `docs/25_CHECKLIST_DE_EJECUCION.md` — de dónde sacás la tarea concreta.
4. El documento del área que vas a tocar (mods → `docs/08`, `docs/09`, `docs/19`, `docs/24`; render → `docs/04`; mundo → `docs/05`; gameplay → `docs/06`; arquitectura → `docs/07`).
5. `docs/03_PRESUPUESTOS_DE_RENDIMIENTO.md` si tu cambio dibuja, simula o carga algo.

Cuando dos documentos se contradicen, gana el más específico del área, y la contradicción se reporta. No la resuelvas en silencio.

---

## 3. Cómo correr las cosas

El motor está descargado en la raíz del repositorio y **está en `.gitignore`**: no lo commitees ni lo muevas.

```bash
# Importar el proyecto (primer paso tras clonar; debe terminar sin errores)
./Godot_v4.7.1-stable_win64_console.exe --headless --path . --import

# Todos los tests unitarios
./Godot_v4.7.1-stable_win64_console.exe --headless --path . --script tests/run_all.gd

# Sólo los que coincidan con un filtro
./Godot_v4.7.1-stable_win64_console.exe --headless --path . --script tests/run_all.gd -- semver

# Lint / chequeo sintáctico de un script
./Godot_v4.7.1-stable_win64_console.exe --headless --path . --check-only --script core/mods/semver.gd

# Schemas, ejemplos y casos dorados
python tools/ci/check_schemas.py

# Índice de archivos
python tools/ci/build_file_index.py --check   # verifica
python tools/ci/build_file_index.py           # regenera
```

En Linux o macOS el binario se llama distinto; usá la variable `GODOT` si preferís.

---

## 4. Ciclo de trabajo

Repetir por tarea. No agrupar cinco tareas en un commit.

1. **Elegir** una tarea de `docs/25`, respetando el orden de dependencias. No saltes a un hito posterior porque parece más entretenido.
2. **Leer** los documentos del área. La especificación ya decidió muchas cosas; implementá lo decidido, no lo que te parezca mejor.
3. **Implementar** el cambio mínimo que cumple la tarea.
4. **Escribir el test antes de declarar nada terminado.** Cada `.gd` nuevo en `core/` necesita su `tests/unit/test_*.gd`. Cada schema nuevo necesita casos en `tests/data/schema_cases.json`, positivos y negativos.
5. **Correr la batería completa** (sección 3). Los cuatro comandos, no sólo el tuyo.
6. **Marcar la tarea** en `docs/25` y regenerar `FILE_INDEX.json`.
7. **Commit** con el formato de `docs/16`.

Si un paso falla, se arregla antes de seguir. No dejes tests rotos "para después".

---

## 5. Reglas duras

Estas no se negocian sin un ADR que las cambie.

1. **El núcleo implementa capacidad, no contenido.** Ninguna espada, isla, misión o enemigo concreto se escribe dentro de `core/`. El contenido oficial se registra igual que un mod comunitario, mediante las mismas APIs públicas.
2. **IDs namespaced siempre**: `official:sword_basic`, `autor.mod:contenido`. Los sistemas consultan IDs, nunca rutas de recursos.
3. **Nunca inventes un número de rendimiento.** Si una tarea necesita medición en Quest y no tenés el visor, marcala `[!]` con motivo y seguí con otra. Un frame time inventado es peor que ninguna medición: contamina las decisiones de todo el proyecto.
4. **No modifiques los presupuestos de `docs/03` sin evidencia medida** adjunta en el PR. El sentido de la tabla es que duela cambiarla.
5. **Un mod declarativo no ejecuta código.** Nada de GDScript ni shaders arbitrarios en el perfil estricto; las acciones se limitan a la whitelist de `docs/09`. Si encontrás una vía para saltarse esto, es un hallazgo de seguridad: documentalo, no lo uses.
6. **Familias de shader cerradas** (`docs/04`). Un mod cambia parámetros, texturas y rampas; no agrega familias.
7. **Un mod defectuoso no cierra el juego.** Errores estructurados, desactivación, modo seguro, y jamás borrado automático de contenido del usuario.
8. **Sin telemetría obligatoria** y sin red en el camino crítico. El juego funciona offline.
9. **Sin propiedad intelectual ajena**: ni assets, ni nombres, ni música, ni símbolos de Zelda, Nintendo u otros juegos. La inspiración es estética, no material.
10. **Todo asset externo se registra** en `THIRD_PARTY.md` con fuente, licencia, modificaciones y hash, en el mismo commit que lo incorpora.

---

## 6. Convenciones de código

- GDScript con tipos explícitos donde el motor los admite; `snake_case` para funciones y variables, `PascalCase` para clases.
- **Identificadores en inglés, comentarios y documentación en español.** El repositorio ya es así.
- Comentá el *porqué*, no el *qué*. Si el comentario repite la línea siguiente, borralo.
- Sistemas centralizados en lugar de miles de nodos con `_process()` (`docs/07`).
- Pools obligatorios para flechas, efectos, impactos, pickups y audio one-shot frecuente.
- Frecuencias de actualización según la tabla de `docs/07`: la IA de combate no corre a frecuencia de pantalla.
- Nada de `class_name` para clases internas de test: ocupan el espacio global de nombres del juego.
- Archivos de datos en JSON validado por schema; nunca configuración dispersa en constantes.

---

## 7. Qué no hacer

- No commitear binarios: motor, APK, keystores, texturas fuente sin LFS.
- No editar `FILE_INDEX.json` a mano; se regenera con la herramienta.
- No agregar un addon sin fijar tag o commit exacto y anotarlo en el lockfile.
- No cambiar el renderer, el motor ni el formato de guardado sin ADR (`docs/17` exige RFC para varios de esos).
- No ampliar la API de mods sin actualizar, en el mismo cambio: schema, `docs/09`, `docs/10` y el mod de ejemplo.
- No usar `res://core` como destino de overrides de mods.
- No agregar dependencias de red, analytics ni servicios externos.
- No "arreglar" un test cambiando lo que espera. Si el test estaba mal, explicá por qué en el commit.

---

## 8. Cuándo frenar y preguntar

Frená y escribí el problema en lugar de decidir solo cuando:

- hace falta una decisión arquitectónica no tomada → ADR nuevo con `templates/adr_template.md`, numerado desde el último de `docs/20`;
- el cambio rompe la Mod API, el formato de save o el sistema de mods → requiere RFC (`docs/17`);
- la especificación se contradice o falta un dato que cambia el diseño;
- la tarea exige hardware que no tenés;
- descubrís que una garantía documentada no se puede cumplir técnicamente. Esto es información valiosa, no un fracaso: documentala.

Entregar lo que sí se puede hacer y decir con precisión qué quedó afuera es mejor que entregar todo a medias.

---

## 9. Definición de terminado

Una tarea está terminada cuando:

1. el código pasa `--check-only` y la batería de tests;
2. la funcionalidad tiene test unitario o de integración;
3. si es visual o de simulación, adjunta reporte de rendimiento con variación respecto de `main`;
4. si toca la Mod API, actualiza schema, documentación y mod de ejemplo;
5. si toca guardado, pasa la batería de seis pasos de `docs/15`;
6. si toca contenido, se expresa mediante la API pública;
7. no introduce shaders fuera de las familias autorizadas;
8. el checklist de `docs/25` quedó actualizado y `FILE_INDEX.json` regenerado.

Una función que cumple visualmente pero rompe el presupuesto no está terminada.

---

## 10. Commits y pull requests

Formato de `docs/16`:

```text
feat(modding): add dependency resolver
perf(render): split forest multimesh by sector
fix(save): preserve missing mod entities
docs(api): document ability action schema
test(mods): cover semver prerelease gate
```

Mensajes de commit en inglés, en imperativo, sin punto final. El cuerpo explica el porqué sólo si no es obvio.

Toda PR visual registra: captura de la escena de prueba, CPU/GPU frame time, draw calls, triángulos, memoria de texturas, cantidad de materiales y variación respecto de `main`.

---

## 11. Mapa del repositorio

```text
core/            lógica del juego reutilizable; sin contenido concreto
game/            autoloads y escenas de arranque            (aún no existe)
official_mods/   contenido oficial, empaquetado como mod    (aún no existe)
schemas/         JSON Schemas Draft 2020-12
examples/        mod de ejemplo declarativo
tests/           framework mínimo, unit, data
tools/ci/        chequeos de integración continua
tools/blender/   pipeline de assets                         (aún no existe)
benchmarks/      escenas fijas de medición                  (aún no existe)
docs/            especificación; 23 = plan, 25 = checklist
templates/       ADR, asset manifest, performance report
```

---

## 12. Primera tarea

Abrí `docs/25_CHECKLIST_DE_EJECUCION.md` y tomá la primera tarea sin marcar respetando el orden. Si el checklist está limpio hasta M0, empezá por **T0.1**.

Antes de escribir una línea, corré la batería de la sección 3 y confirmá que el repositorio está verde. Si ya está roto, arreglarlo es la tarea.
