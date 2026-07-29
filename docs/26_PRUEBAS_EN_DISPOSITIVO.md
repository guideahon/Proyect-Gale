# Pruebas en dispositivo

Cómo instalar y probar una versión del juego en el visor en un comando. Complementa `docs/15` (qué medir) y `docs/25` (cuándo).

**Hardware disponible:** Quest 3. Ver la sección 7 para qué significa eso respecto de los gates del plan, que están escritos sobre Quest 2.

---

## 1. Estado del entorno

Correr en cualquier momento:

```bash
pwsh tools/deploy/check_setup.ps1
```

Audita todo lo necesario y dice qué falta con la acción concreta. No modifica nada. Salida 0 si está todo listo.

Al 2026-07-28, en la máquina de desarrollo: `adb`, Android SDK, JDK 17 y debug keystore ya están. Faltan los export templates de Godot (tarea S1.b) y el preset de exportación (T0.7).

---

## 2. Preparación, una sola vez

### 2.1 Modo desarrollador en el visor

1. Crear una organización de desarrollador en el portal de Meta. Requiere verificación de la cuenta.
2. En la app Meta Horizon del teléfono: dispositivo → ajustes → modo desarrollador → activar.
3. Reiniciar el visor.
4. Conectar por USB-C y aceptar **dentro del visor** el diálogo «Permitir depuración por USB». Conviene marcar «permitir siempre».

Verificar desde la PC:

```bash
adb devices -l
```

Tiene que aparecer una línea con `device` al final. Si dice `unauthorized`, falta aceptar el diálogo en el visor.

### 2.2 Export templates de Godot

En el editor: **Editor → Administrar plantillas de exportación → Descargar**. Deben ser exactamente de la versión 4.7.1 stable; una mezcla de versiones produce APKs que no arrancan.

Registrar el hash de los templates en `VERSION_BASELINE.md`. Es la tarea S1.b y el plan la exige antes de cualquier build reproducible.

### 2.3 Rutas de Android en el editor

En **Editor → Configuración del editor → Export → Android**: ruta del SDK y del debug keystore. En esta máquina son `%LOCALAPPDATA%\Android\Sdk` y `%USERPROFILE%\.android\debug.keystore`.

### 2.4 Preset de exportación

Crear un preset Android llamado `Quest`, con:

- arquitectura **arm64-v8a** únicamente;
- XR habilitado con OpenXR;
- el vendor plugin de Meta, cuando se fije en S1.c;
- nombre de paquete propio, por ejemplo `org.projectgale.game`.

`export_presets.cfg` está en `.gitignore` porque Godot guarda ahí la contraseña del keystore. La tarea T0.7 incluye versionar un `export_presets.template.cfg` sin credenciales.

---

## 3. Ciclo diario

Con todo preparado, cada iteración es:

```bash
pwsh tools/deploy/deploy_quest.ps1
```

Exporta, instala, lanza y avisa cuánto tardó. Ponerse el visor y probar.

Variantes útiles:

```bash
pwsh tools/deploy/deploy_quest.ps1 -Logs        # deja el logcat filtrado en la terminal
pwsh tools/deploy/deploy_quest.ps1 -SkipBuild   # reinstala el último APK sin reexportar
pwsh tools/deploy/deploy_quest.ps1 -Release     # build de release, requiere keystore propio
```

El script falla con salida distinta de 0 en cualquier paso y explica qué hacer. Nunca dice que instaló si `adb install` no devolvió `Success`, y nunca da por buena una exportación que terminó en 0 sin generar el APK — Godot puede hacer exactamente eso cuando faltan los templates.

Una vez instalado, la app aparece en la biblioteca del visor bajo **Fuentes desconocidas**.

---

## 4. Sin cable

El cable sirve para la primera conexión; después conviene inalámbrico, sobre todo para sesiones largas donde el cable molesta y calienta distinto.

```bash
adb tcpip 5555                       # con el cable puesto, una sola vez por arranque del visor
adb shell ip route                   # anotar la IP del visor
# desconectar el cable
pwsh tools/deploy/deploy_quest.ps1 -Wireless -DeviceIp 192.168.0.42
```

La conexión se pierde al reiniciar el visor; repetir `adb tcpip 5555` con cable.

Para sesiones térmicas, medir **siempre** en la misma condición: el cable carga la batería y cambia el perfil térmico, así que una prueba de 30 minutos con cable y otra sin cable no son comparables. Anotar cuál se usó en el reporte.

---

## 5. Logs y evidencia

```bash
adb logcat -c                                   # limpiar antes de la prueba
adb logcat -s godot:V GodotXR:V OpenXR:V *:E    # sólo lo relevante
adb logcat -d > logs/sesion.txt                 # volcar a archivo
```

Las capturas y videos que se graban desde el visor quedan en el propio dispositivo:

```bash
adb shell ls /sdcard/Oculus/Screenshots
adb pull /sdcard/Oculus/Screenshots ./capturas
```

Sirven para el requisito de `docs/03`: toda PR visual adjunta captura de la escena de prueba.

---

## 6. Problemas frecuentes

| Síntoma | Causa habitual |
|---|---|
| `unauthorized` en `adb devices` | falta aceptar el diálogo dentro del visor |
| El visor no aparece | modo desarrollador apagado, o cable sólo de carga sin datos |
| `INSTALL_FAILED_UPDATE_INCOMPATIBLE` | firma distinta: `adb uninstall <paquete>` y reinstalar |
| `INSTALL_FAILED_INSUFFICIENT_STORAGE` | espacio en el visor |
| La exportación sale 0 pero no hay APK | faltan export templates de la versión exacta |
| La app arranca en 2D, sin VR | OpenXR deshabilitado en el proyecto o falta el vendor plugin |
| Pantalla negra al entrar | el renderer del preset no coincide con el del proyecto |

---

## 7. Quest 3 contra Quest 2: los gates del plan

Esto no es un detalle de configuración, es una decisión de alcance pendiente.

La especificación fija **Quest 2 como dispositivo mínimo del modo estricto de 120 Hz** (`docs/02`, ADR-002), y el gate de M2 exige 120 Hz sostenidos durante 30 minutos **en Quest 2**. Con un Quest 3 se puede medir mucho, pero no se puede cerrar ese gate: el Quest 3 tiene bastante más margen de GPU y de térmica, así que un resultado bueno ahí no dice nada sobre el dispositivo objetivo.

Qué **sí** se desbloquea con Quest 3:

- S3, 120 Hz real y cómo el runtime concede o revoca la frecuencia;
- S4, foveation y resolución dinámica;
- S5, montar un PCK desde `user://` en Android;
- T0.11, el gate de M0: que el APK arranque en VR;
- T1.9, sesiones térmicas del perfil `quest3_120`.

Qué **queda abierto**:

- el gate de M2 tal como está escrito;
- S2, Compatibility contra Mobile en el dispositivo objetivo;
- S8, Quest 1.

Hay tres caminos, y conviene elegir uno explícitamente por ADR en vez de dejarlo implícito:

1. **Conseguir un Quest 2** prestado o usado, sólo para certificación. Mantiene el plan intacto.
2. **Re-escopar el objetivo**: Quest 3 pasa a ser el dispositivo de certificación de 120 Hz y Quest 2 queda como «compatible, sin garantía de frecuencia». Es un cambio de producto, no de implementación: contradice ADR-002 y hay que reescribirlo.
3. **Postergar la decisión** y medir todo en Quest 3 con perfil propio, dejando el gate de M2 explícitamente abierto hasta conseguir hardware.

Mientras no se decida, cualquier reporte de rendimiento debe declarar el dispositivo en el que se midió. El campo `device` del reporte ya existe justamente para eso.
