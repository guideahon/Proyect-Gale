# Gameplay VR

## Locomoción

- Movimiento continuo.
- Teleportación opcional.
- Giro suave.
- Snap turn.
- Viñeta configurable.
- Modo sentado y de pie.
- Calibración de altura.
- Mano dominante.
- Control de velocidad.
- Opciones de accesibilidad.

## Escalada

- Superficies con etiqueta `climbable`.
- Agarre por manos.
- Cuerpo representado por cápsula.
- Resistencia calculada a menor frecuencia.
- Agarre asistido opcional.
- Sin física por cada piedra.

## Planeador

- Activación con ambas manos.
- Dirección basada en pose de controladores.
- Movimiento cinemático.
- Descenso y aceleración limitados.
- Sin aerodinámica real.
- Diseñado para comodidad y previsibilidad.

## Navegación

- Barco cinemático.
- Altura y balanceo derivados de la misma función matemática que el shader del agua.
- Sin flotación física.
- Colisión simple.
- Estela económica.
- El océano funciona como espacio de transición y streaming.

## Espada

- Pose amortiguada.
- Barrido entre posición previa y actual.
- Cápsula de daño.
- Límite de velocidad efectiva.
- Cooldown por objetivo.
- Vibración háptica proporcional.
- No se acepta daño infinito por agitar el control.

## Escudo

- Collider simple.
- Bloqueo según ángulo.
- Parry según velocidad y ventana temporal.
- Respuesta visual, sonora y háptica.
- Sin resolver una simulación física completa entre armas.

## Arco

- Flechas mediante pool.
- Número máximo de proyectiles activos.
- Física simplificada.
- Flechas lejanas dormidas o eliminadas.
- Ajustes de accesibilidad para tensión y alcance.

## Enemigos

Estados iniciales:

- `SLEEP`
- `IDLE`
- `PATROL`
- `ALERT`
- `CHASE`
- `ATTACK`
- `STUN`
- `RETURN`
- `DEAD`

La IA decide a 15–30 Hz; la pose visual puede interpolarse a la frecuencia de pantalla.

## Elementos

Primera versión:

- fuego;
- viento.

Expansión posterior:

- electricidad;
- agua;
- hielo.

Las interacciones usan etiquetas y acciones declarativas, no simulación material universal.
