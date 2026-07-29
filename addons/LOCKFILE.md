# Addons Lockfile

Los binarios no se versionan: son 82 MB de `.so`, `.dll` y `.aar` por
plataforma. Se obtienen del release fijado acá, verificando el SHA-256:

```bash
pwsh tools/deploy/fetch_addons.ps1
```

| Addon | Versión | Asset | SHA-256 |
|---|---|---|---|
| godot_openxr_vendors | 5.1.0-stable | [`godotopenxrvendorsaddon.zip`](https://github.com/GodotVR/godot_openxr_vendors/releases/download/5.1.0-stable/godotopenxrvendorsaddon.zip) | `6a838dbdf4115549e4511ebee0da9a5dcc8f9f6258d4cc2f2ee57a907a3e2911` |

Para subir de versión hay que cambiar los tres campos a la vez, acá y en
`tools/deploy/fetch_addons.ps1`, y reexportar: el plugin inyecta entradas en el
manifest de Android, así que un cambio de versión puede alterar el APK.

XR Tools todavía no se usa; entra en M4.
