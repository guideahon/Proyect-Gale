<#
.SYNOPSIS
    Audita el entorno necesario para exportar e instalar en un Quest.

.DESCRIPTION
    No modifica nada. Informa qué está listo y qué falta, con la acción
    concreta para cada faltante. Salida 0 si todo está, 1 si falta algo.

    Uso:  pwsh tools/deploy/check_setup.ps1
#>

$ErrorActionPreference = "Continue"
$root = (Resolve-Path "$PSScriptRoot\..\..").Path
$missing = @()

function Report($ok, $label, $detail, $fix) {
    if ($ok) {
        Write-Host ("  [ok]    {0}: {1}" -f $label, $detail)
    } else {
        Write-Host ("  [falta] {0}: {1}" -f $label, $detail) -ForegroundColor Yellow
        Write-Host ("          -> {0}" -f $fix)
        $script:missing += $label
    }
}

Write-Host "`nEntorno de despliegue — Proyecto Gale`n"

# --- Herramientas de host -------------------------------------------------
$adb = (Get-Command adb -ErrorAction SilentlyContinue).Source
Report ($null -ne $adb) "adb" ($adb ?? "no está en PATH") `
    "instalar Android platform-tools y agregarlo al PATH"

$sdk = $env:ANDROID_HOME ?? $env:ANDROID_SDK_ROOT
Report ($null -ne $sdk -and (Test-Path $sdk)) "Android SDK" ($sdk ?? "sin ANDROID_HOME") `
    "instalar el SDK y exportar ANDROID_HOME"

$java = (Get-Command java -ErrorAction SilentlyContinue).Source
Report ($null -ne $java) "JDK" ($java ?? "no está en PATH") `
    "instalar JDK 17 (Godot 4.x exporta Android con 17)"

$keystore = "$env:USERPROFILE\.android\debug.keystore"
Report (Test-Path $keystore) "debug keystore" $keystore `
    "generar con: keytool -keyalg RSA -genkeypair -alias androiddebugkey -keypass android -keystore debug.keystore -storepass android -dname 'CN=Android Debug,O=Android,C=US' -validity 9999 -deststoretype pkcs12"

# --- Godot ----------------------------------------------------------------
$godot = Get-ChildItem $root -Filter "Godot_v*_console.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
Report ($null -ne $godot) "binario de Godot" (($godot.Name) ?? "no encontrado en la raíz") `
    "descargar Godot 4.7.1 stable a la raíz del repositorio"

$templates = "$env:APPDATA\Godot\export_templates"
$hasTemplates = (Test-Path $templates) -and ((Get-ChildItem $templates -ErrorAction SilentlyContinue).Count -gt 0)
Report $hasTemplates "export templates" ($(if ($hasTemplates) { (Get-ChildItem $templates -Name) -join ", " } else { "ninguno instalado" })) `
    "Godot > Editor > Administrar plantillas de exportación > Descargar. Es la tarea S1.b del checklist"

$presets = Join-Path $root "export_presets.cfg"
Report (Test-Path $presets) "preset de exportación" ($(if (Test-Path $presets) { "export_presets.cfg presente" } else { "sin export_presets.cfg" })) `
    "crear el preset Android ARM64 en el editor. Es la tarea T0.7 del checklist"

# --- Dispositivo ----------------------------------------------------------
if ($adb) {
    $devices = @(& adb devices | Select-Object -Skip 1 | Where-Object { $_ -match "\S" })
    $online = @($devices | Where-Object { $_ -match "\sdevice\b" })
    $unauth = @($devices | Where-Object { $_ -match "unauthorized" })

    if ($online.Count -gt 0) {
        $model = (& adb shell getprop ro.product.model 2>$null)
        Report $true "visor conectado" "$($online.Count) dispositivo(s): $model" ""
    } elseif ($unauth.Count -gt 0) {
        Report $false "visor conectado" "conectado pero sin autorizar" `
            "poné el visor y aceptá 'Permitir depuración por USB'"
    } else {
        Report $false "visor conectado" "ninguno" `
            "activá modo desarrollador en la app Meta Horizon, conectá por USB y aceptá el diálogo del visor"
    }
}

# --- Resumen --------------------------------------------------------------
Write-Host ""
if ($missing.Count -eq 0) {
    Write-Host "Todo listo. Siguiente: pwsh tools/deploy/deploy_quest.ps1" -ForegroundColor Green
    exit 0
}
Write-Host ("Faltan {0}: {1}" -f $missing.Count, ($missing -join ", ")) -ForegroundColor Yellow
exit 1
