# API de mods

## Semántica de versiones

- Major: cambio incompatible.
- Minor: funciones nuevas compatibles.
- Patch: correcciones.

Una API obsoleta se conserva al menos durante dos versiones estables, salvo vulnerabilidad grave.

## Eventos públicos

- `game_started`
- `world_loaded`
- `island_entered`
- `sector_activated`
- `item_acquired`
- `weapon_equipped`
- `weapon_hit`
- `enemy_defeated`
- `dialogue_started`
- `dialogue_finished`
- `quest_updated`
- `player_damaged`
- `player_resting`
- `save_started`
- `save_completed`

## Triggers declarativos

- `on_use`
- `on_hit`
- `on_block`
- `on_parry`
- `on_pickup`
- `on_enter_area`
- `on_timer`
- `on_health_threshold`
- `on_dialogue_event`

## Condiciones

- `has_item`
- `stat_compare`
- `target_has_tag`
- `random_chance`
- `quest_state`
- `environment_tag`
- `cooldown_ready`

## Acciones

- `deal_damage`
- `heal`
- `apply_status`
- `remove_status`
- `consume_item`
- `spawn_projectile`
- `spawn_entity`
- `play_sound`
- `play_effect`
- `set_flag`
- `start_dialogue`
- `start_quest`
- `teleport`
- `modify_velocity`
- `give_item`

## Overrides

### Extend

Agrega comportamiento o listas sin eliminar el original.

### Patch

Modifica propiedades concretas.

### Replace

Sustituye toda la definición y genera advertencia de compatibilidad.

### Disable

Elimina una definición del registro activo, conservando placeholders para partidas.

## Límites del modo estricto

- Sin shaders arbitrarios.
- Sin GDScript arbitrario.
- Sin acceso a filesystem fuera de directorios asignados.
- Sin sockets.
- Sin extensiones nativas.
- Límites de assets y entidades.
- Acciones declarativas incluidas en whitelist.

## Extensiones de interfaz

Puntos autorizados:

- menú de mods;
- libro de misiones;
- mapa;
- inventario;
- pantalla de créditos;
- panel de depuración de mod.

La UI VR comunitaria utiliza componentes del ModKit para mantener tamaño, profundidad y legibilidad.
