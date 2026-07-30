<#
.SYNOPSIS
    Descarga los addons fijados en addons/LOCKFILE.md y verifica su hash.

.DESCRIPTION
    Los binarios de terceros no se versionan: 82 MB de .so/.dll/.aar por
    plataforma. La reproducibilidad sale del release fijado más el SHA-256
    registrado, igual que con los export templates (docs/02).

    Uso:
        pwsh tools/deploy/fetch_addons.ps1
        pwsh tools/deploy/fetch_addons.ps1 -Force   # reinstala aunque exista
#>

param([switch]$Force)

$ErrorActionPreference = "Stop"
$root = (Resolve-Path "$PSScriptRoot\..\..").Path

# Fijado en addons/LOCKFILE.md. Cambiar los tres campos a la vez.
$addon = @{
    Name   = "godotopenxrvendors"
    Version = "5.1.0-stable"
    Url    = "https://github.com/GodotVR/godot_openxr_vendors/releases/download/5.1.0-stable/godotopenxrvendorsaddon.zip"
    Sha256 = "6a838dbdf4115549e4511ebee0da9a5dcc8f9f6258d4cc2f2ee57a907a3e2911"
}

# Rutas armadas con Join-Path anidado y no con separadores literales: el
# script también corre en el runner de CI, que es Linux, donde `\` no separa
# directorios y `$env:TEMP` no existe.
$tempDir = [System.IO.Path]::GetTempPath()
$target = Join-Path (Join-Path $root "addons") $addon.Name
if ((Test-Path $target) -and -not $Force) {
    Write-Host "$($addon.Name) ya está en addons/. Usá -Force para reinstalar." -ForegroundColor Green
    exit 0
}

$zip = Join-Path $tempDir "$($addon.Name)-$($addon.Version).zip"
if (-not (Test-Path $zip)) {
    Write-Host "Descargando $($addon.Name) $($addon.Version)..."
    Invoke-WebRequest -Uri $addon.Url -OutFile $zip
}

$hash = (Get-FileHash $zip -Algorithm SHA256).Hash.ToLower()
if ($addon.Sha256 -and $hash -ne $addon.Sha256) {
    Write-Host "ERROR: SHA-256 no coincide." -ForegroundColor Red
    Write-Host "  esperado: $($addon.Sha256)"
    Write-Host "  obtenido: $hash"
    Write-Host "  -> si el release cambió legítimamente, actualizá el hash en este script y en addons/LOCKFILE.md"
    exit 1
}
Write-Host "SHA-256 verificado: $hash"

# Extraer primero, reemplazar después. Borrar el destino antes de tener la
# copia nueva dejó el addon a medio borrar cuando Windows tenía tomado un .dll
# que Godot estaba usando: quedaron 12 de 36 archivos y el export de Android
# perdió los .aar.
$tmp = Join-Path $tempDir "$($addon.Name)-extract"
if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue }
Expand-Archive -Path $zip -DestinationPath $tmp -Force

# El zip trae addons/<nombre>/... en la raíz.
$src = Join-Path (Join-Path $tmp "addons") $addon.Name
if (-not (Test-Path $src)) { $src = (Get-ChildItem $tmp -Directory -Recurse | Where-Object Name -eq $addon.Name | Select-Object -First 1).FullName }
if (-not $src) { Write-Host "ERROR: no se encontró addons/$($addon.Name) dentro del zip." -ForegroundColor Red; exit 1 }

New-Item -ItemType Directory -Force -Path (Split-Path $target) | Out-Null
if (Test-Path $target) {
    $old = "$target.old-$(Get-Random)"
    try {
        Rename-Item $target $old -ErrorAction Stop
    } catch {
        Write-Host "ERROR: no se pudo apartar la instalación anterior: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "  -> cerrá el editor de Godot (tiene el .dll tomado) y reintentá. La instalación actual quedó intacta."
        exit 1
    }
    Move-Item $src $target
    Remove-Item $old -Recurse -Force -ErrorAction SilentlyContinue
    if (Test-Path $old) {
        Write-Host "AVISO: no se pudo borrar $old (archivos tomados). Borralo a mano cuando cierres Godot." -ForegroundColor Yellow
    }
} else {
    Move-Item $src $target
}
Remove-Item $tmp -Recurse -Force

$mb = [math]::Round((Get-ChildItem $target -Recurse -File | Measure-Object -Sum Length).Sum / 1MB, 1)
Write-Host "$($addon.Name) $($addon.Version) instalado en addons/ ($mb MB)." -ForegroundColor Green
Write-Host "Siguiente: reimportar el proyecto para que Godot registre la GDExtension."
