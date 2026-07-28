# Firma y empaquetado de mods

**Estado:** especificación inicial
**Cierra:** ADR-015
**Complementa:** `docs/08` (formato `.gmod`), `docs/19` (seguridad), `schemas/signature.schema.json`

`docs/08` define el contenedor `.gmod` con un `signature.json`, y `docs/19` declara que las firmas son opcionales y que una firma indica procedencia, no seguridad. Faltaba el contrato exacto: qué se firma, con qué algoritmo, en qué formato y qué hace el juego con el resultado. Este documento lo fija.

---

## 1. Qué es y qué no es

Una firma válida afirma: **este paquete no cambió desde que la clave X lo empaquetó**.

No afirma:

- que el contenido sea seguro;
- que el autor sea quien dice ser;
- que la licencia declarada sea correcta;
- que el mod respete el presupuesto de rendimiento;
- que el mod haya sido auditado.

La validación de contenido es trabajo del validador (`docs/15`), no de la firma. Un `.gmod` firmado y malicioso sigue siendo malicioso; la firma sólo permite saber que dos descargas distintas son el mismo paquete y provienen de la misma clave.

---

## 2. Estructura del paquete

```text
my_mod.gmod                 # ZIP, sin compresión para content.pck
├── manifest.json           # obligatorio, primero en el índice del ZIP
├── content.pck             # obligatorio para mods con contenido
├── icon.webp               # opcional, ≤ 256 × 256
├── README.md               # opcional
├── LICENSE                 # obligatorio si el manifest declara licencia no estándar
├── CHANGELOG.md            # opcional
└── signature.json          # opcional; si existe, debe validar
```

Reglas del contenedor:

1. Sólo rutas relativas con separador `/`, limitadas a `[A-Za-z0-9_.-]` y con un máximo de 255 caracteres. El juego corre en Windows, Linux y Android; restringir el juego de caracteres evita rutas que sólo fallan en una plataforma y nombres con homoglifos Unicode que aparentan ser otro archivo.
2. Prohibidos `..`, `.`, segmentos que empiecen con punto, rutas absolutas, enlaces simbólicos y entradas duplicadas.
3. Prohibidas las entradas con nombre que difiera sólo en mayúsculas: rompen en sistemas insensibles y permiten confundir al validador.
4. `manifest.json` se lee **sin montar** el resto (`docs/19`).
5. Tamaño máximo por defecto configurable; el instalador verifica antes de copiar.
6. El tamaño descomprimido declarado debe coincidir con el real, con tolerancia cero. Evita zip bombs.

---

## 3. Payload canónico

Se firma un texto derivado del contenido, no el ZIP. El ZIP no es reproducible byte a byte entre herramientas; el payload sí.

Construcción:

1. Listar todos los archivos del paquete **excepto `signature.json`**.
2. Para cada uno, calcular SHA-256 sobre los bytes crudos del archivo descomprimido.
3. Normalizar la ruta: relativa, separador `/`, sin `./` inicial, Unicode NFC.
4. Formar una línea por archivo: `<sha256 en hex minúscula><dos espacios><ruta>`.
5. Ordenar las líneas por comparación byte a byte de la ruta codificada en UTF-8.
6. Unir con `\n` y terminar con `\n` final.
7. `payload_sha256` = SHA-256 de ese texto en UTF-8.

Ejemplo:

```text
6f3a...b21c  content.pck
0d19...77ae  icon.webp
bebd...46b0  manifest.json
```

El formato es deliberadamente igual al de `sha256sum` para que sea verificable con herramientas estándar.

---

## 4. Algoritmo

| Campo | Valor |
|---|---|
| Hash | SHA-256, fijo |
| Firma | RSA PKCS#1 v1.5 sobre SHA-256 |
| Tamaño de clave | 2048 mínimo, 4096 recomendado |
| Codificación de clave pública | PEM SPKI |
| Codificación de firma | Base64 |
| `key_id` | primeros 16 hex de SHA-256 sobre la clave pública en DER |

**Por qué RSA y no Ed25519.** Ed25519 es preferible criptográficamente, pero el juego debe poder verificar dentro del APK público sin extensiones nativas, y eso limita a lo que expone la API de criptografía del motor: RSA y X.509. Introducir Ed25519 exigiría una GDExtension, lo que contradice `docs/08` — el APK público no carga extensiones nativas arbitrarias. La decisión se revisa si el motor expone Ed25519.

`algorithm: "none"` está permitido: produce un `signature.json` sin firma que sólo aporta manifiesto de integridad. Detecta corrupción y descargas truncadas, no procedencia. Es el modo por defecto del ModKit para mods personales.

---

## 5. Verificación

Orden exacto en el instalador, alineado con el flujo de `docs/19`:

1. Abrir el ZIP en modo lectura, sin montar.
2. Validar la estructura del contenedor (sección 2). Fallo → rechazo, sin copiar nada.
3. Leer y validar `manifest.json` contra su schema.
4. Si existe `signature.json`, validarlo contra `schemas/signature.schema.json`.
5. Verificar que la lista `files` cubre exactamente el contenido del paquete, sin faltantes ni sobrantes. Un archivo no listado es un rechazo, no una advertencia: sería la vía obvia para colar contenido no firmado.
6. Recalcular cada SHA-256 y compararlo.
7. Reconstruir el payload canónico y comparar `payload_sha256`.
8. Si `algorithm != none`, verificar la firma con la clave pública incluida.
9. Resolver la confianza de la clave (sección 6).
10. Mostrar al usuario: nombre, autor declarado, licencia, permisos, tamaño, y **estado de firma**.
11. Copiar a `user://mods/`, activar al reiniciar.

En Godot esto se resuelve con `ZIPReader`, `HashingContext` con `HASH_SHA256`, `CryptoKey.load_from_string()` y `Crypto.verify(HashingContext.HASH_SHA256, digest, signature, key)`. No requiere red.

El paso 6 se ejecuta con lectura en bloques, no cargando el archivo entero en memoria: `content.pck` puede ser grande y el visor tiene poca RAM.

---

## 6. Confianza de claves

Modelo TOFU (*trust on first use*), sin autoridad central:

- La primera vez que se instala un mod de un `key_id`, se registra el par autor/clave en `user://mod_config.json`.
- Instalaciones posteriores con el mismo `key_id` muestran «firmado por la misma clave que la versión anterior».
- Un `key_id` distinto para el mismo `id` de mod produce una advertencia destacada y requiere confirmación explícita. Es la señal de una cuenta comprometida o de un paquete redistribuido por un tercero.
- El campo `signer` es texto libre no verificado. La interfaz nunca lo muestra solo: siempre acompañado del `key_id` abreviado.

Estados que muestra la interfaz:

| Estado | Significado |
|---|---|
| Sin firma | No hay `signature.json`. Permitido. |
| Integridad verificada | `algorithm: none`, hashes correctos. |
| Firmado, clave nueva | Firma válida, `key_id` desconocido. |
| Firmado, clave conocida | Firma válida, `key_id` ya asociado a ese mod. |
| **Clave distinta** | Firma válida pero `key_id` cambió. Advertencia fuerte. |
| **Firma inválida** | Rechazo. No se instala. |
| **Integridad rota** | Rechazo. No se instala. |

Distinguir «inválido» de «ausente» es central: la ausencia de firma es una opción legítima; una firma que no verifica es un paquete alterado.

---

## 7. Claves oficiales

- El contenido oficial (`official.base`, `official.campaign`) se firma en CI con una clave de release cuya parte privada vive sólo como secreto del repositorio.
- La clave pública oficial se embebe en el APK y se ancla: el juego rechaza un paquete con `id` que empiece por `official.` firmado por otra clave, o sin firma.
- La rotación de la clave oficial requiere un release que embeba ambas claves durante al menos dos versiones estables, igual que la política de deprecación de la Mod API.
- Un fork que cambia el contenido oficial debe cambiar el namespace, no la clave. Esto evita paquetes que se presenten como oficiales del proyecto original.

---

## 8. Revocación

No hay CRL ni servidor de validación; el juego funciona sin red.

- El catálogo comunitario puede publicar un índice firmado con hashes conocidos y una lista de paquetes retirados.
- El juego acepta importar esa lista como archivo; nunca la descarga por su cuenta.
- Un paquete en la lista se marca en la interfaz y no se activa sin confirmación explícita.
- Nunca se borra contenido del usuario de forma automática, ni siquiera revocado. Coherente con `docs/08`.

---

## 9. Firma y modo de mod

La firma es ortogonal al perfil de rendimiento y al nivel de seguridad:

- un mod `developer_unrestricted` firmado sigue ejecutando GDScript arbitrario;
- un mod declarativo sin firma sigue sin ejecutar código.

La interfaz muestra **capacidades y firma como dos ejes separados**. Presentar una firma como sello de aprobación sería exactamente el engaño con metadatos que enumera el modelo de amenaza de `docs/19`.

---

## 10. Trabajo derivado

- `tools/modkit/pack.gd` — empaquetador y firmante.
- `tools/validator/` — reproduce las secciones 2, 3 y 5 con las mismas reglas que el runtime.
- `core/mods/package_reader.gd` — lectura y verificación.
- `core/mods/key_store.gd` — TOFU sobre `user://mod_config.json`.
- Test de integración obligatorio: paquete alterado en un byte tras firmar debe ser rechazado en el paso 6, no en el 8.
