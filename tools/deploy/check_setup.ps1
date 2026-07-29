<#
.SYNOPSIS
    Audita el entorno necesario para exportar e instalar en un Quest.
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

Write-Host "`nDeploy environment - Project Gale`n"

# --- Host tools -----------------------------------------------------------
$adb = (Get-Command adb -ErrorAction SilentlyContinue).Source
$adb_detail = if ($adb) { $adb } else { "not in PATH" }
Report ($null -ne $adb) "adb" $adb_detail `
    "install Android platform-tools and add to PATH"

$sdk = if ($env:ANDROID_HOME) { $env:ANDROID_HOME } elseif ($env:ANDROID_SDK_ROOT) { $env:ANDROID_SDK_ROOT } else { $null }
$sdk_detail = if ($sdk) { $sdk } else { "no ANDROID_HOME" }
$sdk_ok = ($null -ne $sdk) -and (Test-Path $sdk)
Report $sdk_ok "Android SDK" $sdk_detail `
    "install SDK and set ANDROID_HOME"

$java = (Get-Command java -ErrorAction SilentlyContinue).Source
$java_detail = if ($java) { $java } else { "not in PATH" }
Report ($null -ne $java) "JDK" $java_detail `
    "install JDK 17 (Godot 4.x Android export)"

$keystore = "$env:USERPROFILE\.android\debug.keystore"
Report (Test-Path $keystore) "debug keystore" $keystore `
    "generate with keytool -keyalg RSA -genkeypair -alias androiddebugkey ..."

# --- Godot ----------------------------------------------------------------
$godot = Get-ChildItem $root -Filter "Godot_v*_console.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
$godot_name = if ($godot) { $godot.Name } else { "not found in root" }
Report ($null -ne $godot) "Godot binary" $godot_name `
    "download Godot 4.7.1 stable to repo root"

$templates = "$env:APPDATA\Godot\export_templates"
$hasTemplates = (Test-Path $templates) -and ((Get-ChildItem $templates -ErrorAction SilentlyContinue).Count -gt 0)
$tmpl_detail = if ($hasTemplates) { (Get-ChildItem $templates -Name) -join ", " } else { "none installed" }
Report $hasTemplates "export templates" $tmpl_detail `
    "Godot Editor - Manage Export Templates - Download (task S1.b)"

$addon = Join-Path $root "addons\godotopenxrvendors\plugin.gdextension"
$addon_detail = if (Test-Path $addon) { "godotopenxrvendors present" } else { "not installed" }
Report (Test-Path $addon) "OpenXR vendors addon" $addon_detail `
    "run tools/deploy/fetch_addons.ps1 (binaries are not versioned; see addons/LOCKFILE.md)"

$gradleTpl = Join-Path $root "android\build\build.gradle"
$gradle_detail = if (Test-Path $gradleTpl) { "android/build present" } else { "not installed" }
Report (Test-Path $gradleTpl) "Gradle build template" $gradle_detail `
    "Godot Editor - Project - Install Android Build Template (required: the vendor plugin only injects the Meta VR manifest entries via Gradle)"

$presets = Join-Path $root "export_presets.cfg"
$preset_detail = if (Test-Path $presets) { "export_presets.cfg present" } else { "no export_presets.cfg" }
Report (Test-Path $presets) "export preset" $preset_detail `
    "create Android ARM64 preset in editor (task T0.7)"

# --- Device ---------------------------------------------------------------
if ($adb) {
    $devices = @(& adb devices | Select-Object -Skip 1 | Where-Object { $_ -match "\S" })
    $online = @($devices | Where-Object { $_ -match "\sdevice\b" })
    $unauth = @($devices | Where-Object { $_ -match "unauthorized" })

    if ($online.Count -gt 0) {
        $model = (& adb shell getprop ro.product.model 2>$null)
        Report $true "headset connected" ("{0} device(s): {1}" -f $online.Count, $model) ""
    } elseif ($unauth.Count -gt 0) {
        Report $false "headset connected" "connected but not authorized" `
            "accept USB debugging prompt on headset"
    } else {
        Report $false "headset connected" "none" `
            "enable developer mode in Meta Horizon app, connect USB"
    }
}

# --- Summary --------------------------------------------------------------
Write-Host ""
if ($missing.Count -eq 0) {
    Write-Host "All good. Next: pwsh tools/deploy/deploy_quest.ps1" -ForegroundColor Green
    exit 0
}
Write-Host ("Missing {0}: {1}" -f $missing.Count, ($missing -join ", ")) -ForegroundColor Yellow
exit 1
