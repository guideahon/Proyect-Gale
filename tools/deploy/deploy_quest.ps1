<#
.SYNOPSIS
    Exporta el APK, lo instala en el Quest y lo lanza. Un comando por iteración.

.DESCRIPTION
    Ciclo completo: exportar -> instalar -> lanzar -> (opcional) ver logs.
    Falla ruidosamente con exit != 0 en cualquier paso; nunca reporta éxito
    sin haber verificado el resultado.

    Uso:
        pwsh tools/deploy/deploy_quest.ps1
        pwsh tools/deploy/deploy_quest.ps1 -Logs
        pwsh tools/deploy/deploy_quest.ps1 -SkipBuild          # reinstala el último APK
        pwsh tools/deploy/deploy_quest.ps1 -Wireless -DeviceIp 192.168.0.42

.PARAMETER Preset
    Nombre del preset de exportación en export_presets.cfg.

.PARAMETER Release
    Exporta en modo release en vez de debug. Requiere keystore de release.
#>

param(
    [string]$Preset = "Quest",
    [string]$Package = "",
    [switch]$SkipBuild,
    [switch]$Release,
    [switch]$Logs,
    [switch]$Wireless,
    [string]$DeviceIp = ""
)

$ErrorActionPreference = "Stop"
$root = (Resolve-Path "$PSScriptRoot\..\..").Path
$outDir = Join-Path $root "exports"
$apk = Join-Path $outDir "gale.apk"
$started = Get-Date

function Fail($message, $fix) {
    Write-Host "`nERROR: $message" -ForegroundColor Red
    if ($fix) { Write-Host "  -> $fix" }
    exit 1
}

function Step($n, $text) {
    Write-Host ("`n[{0}] {1}" -f $n, $text) -ForegroundColor Cyan
}

# --- Preparación ----------------------------------------------------------
if (-not (Get-Command adb -ErrorAction SilentlyContinue)) {
    Fail "adb no está en el PATH." "correr tools/deploy/check_setup.ps1"
}

$godot = Get-ChildItem $root -Filter "Godot_v*_console.exe" | Select-Object -First 1
if (-not $godot) {
    Fail "no se encontró el binario de Godot en la raíz." "descargar Godot 4.7.1 stable al repositorio"
}

# --- Conexión -------------------------------------------------------------
Step 1 "Conectando con el visor"

if ($Wireless) {
    if (-not $DeviceIp) {
        Fail "-Wireless necesita -DeviceIp." "conectá por USB una vez y corré: adb shell ip route"
    }
    & adb connect "${DeviceIp}:5555" | Out-Host
}

$devices = @(& adb devices | Select-Object -Skip 1 | Where-Object { $_ -match "\sdevice\b" })
if ($devices.Count -eq 0) {
    Fail "no hay ningún visor autorizado." "activá modo desarrollador, conectá por USB y aceptá el diálogo dentro del visor"
}
if ($devices.Count -gt 1) {
    Fail "hay $($devices.Count) dispositivos conectados; adb no sabe cuál usar." "desconectá los demás o exportá ANDROID_SERIAL"
}
$model = (& adb shell getprop ro.product.model 2>$null)
Write-Host "  visor: $model"

# --- Exportación ----------------------------------------------------------
if (-not $SkipBuild) {
    Step 2 "Exportando APK ($(if ($Release) { 'release' } else { 'debug' }))"

    $presetsFile = Join-Path $root "export_presets.cfg"
    if (-not (Test-Path $presetsFile)) {
        Fail "no existe export_presets.cfg." "crear el preset Android ARM64 en el editor. Es la tarea T0.7 del checklist"
    }

    New-Item -ItemType Directory -Force -Path $outDir | Out-Null

    # Exportar a un archivo temporal y reemplazar sólo si salió bien: una
    # exportación fallida no puede destruir el último APK que sí funcionaba.
    $apkTmp = Join-Path $outDir "gale.building.apk"
    if (Test-Path $apkTmp) { Remove-Item $apkTmp -Force }

    $mode = if ($Release) { "--export-release" } else { "--export-debug" }
    & $godot.FullName --headless --path $root $mode $Preset $apkTmp 2>&1 | Out-Host

    if ($LASTEXITCODE -ne 0) {
        if (Test-Path $apkTmp) { Remove-Item $apkTmp -Force }
        $kept = if (Test-Path $apk) { " El APK anterior sigue en $apk." } else { "" }
        Fail "la exportación devolvió $LASTEXITCODE.$kept" "revisá que el preset '$Preset' exista y que los export templates estén instalados (tarea S1.b)"
    }
    if (-not (Test-Path $apkTmp)) {
        Fail "la exportación terminó en 0 pero no generó el APK." "revisar la salida de arriba: Godot puede fallar silenciosamente sin templates"
    }
    Move-Item $apkTmp $apk -Force

    $sizeMb = [math]::Round((Get-Item $apk).Length / 1MB, 1)
    Write-Host "  APK: $apk ($sizeMb MB)"
} else {
    if (-not (Test-Path $apk)) { Fail "-SkipBuild pero no existe $apk." "correr sin -SkipBuild" }
    Step 2 "Salteando exportación (-SkipBuild)"
}

# --- Nombre del paquete ---------------------------------------------------
if (-not $Package) {
    $line = Select-String -Path (Join-Path $root "export_presets.cfg") -Pattern 'package/unique_name\s*=\s*"([^"]+)"' -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($line) { $Package = $line.Matches[0].Groups[1].Value }
}
if (-not $Package) {
    Fail "no se pudo determinar el nombre del paquete." "pasarlo con -Package org.tuorg.gale"
}

# --- Instalación ----------------------------------------------------------
Step 3 "Instalando $Package"
$installOutput = & adb install -r -d $apk 2>&1 | Out-String
Write-Host $installOutput.Trim()
if ($installOutput -notmatch "Success") {
    Fail "adb install no reportó Success." "si dice INSTALL_FAILED_UPDATE_INCOMPATIBLE, desinstalá primero: adb uninstall $Package"
}

# --- Lanzamiento ----------------------------------------------------------
Step 4 "Lanzando en el visor"
if ($Logs) { & adb logcat -c }
& adb shell monkey -p $Package -c android.intent.category.LAUNCHER 1 2>&1 | Out-Null

$elapsed = [math]::Round(((Get-Date) - $started).TotalSeconds, 1)
Write-Host "`nListo en $elapsed s. Ponete el visor." -ForegroundColor Green

# --- Logs -----------------------------------------------------------------
if ($Logs) {
    Write-Host "`nLogs (Ctrl+C para salir):`n" -ForegroundColor Cyan
    & adb logcat -s godot:V GodotXR:V OpenXR:V *:E
}
