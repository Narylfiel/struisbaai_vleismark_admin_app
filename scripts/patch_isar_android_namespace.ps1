# Patch isar_flutter_libs Android build.gradle to add required namespace (AGP 8+).
# Run after `flutter pub get` if you see: "Namespace not specified" for :isar_flutter_libs.
# See: https://d.android.com/r/tools/upgrade-assistant/set-namespace

$ErrorActionPreference = "Stop"
$pubCache = if ($env:PUB_CACHE) { $env:PUB_CACHE } else { Join-Path $env:LOCALAPPDATA "Pub\Cache\hosted\pub.dev" }
$baseDir = Join-Path $pubCache "isar_flutter_libs-3.1.0+1"
$buildGradle = Join-Path $baseDir "android\build.gradle"

if (-not (Test-Path $buildGradle)) {
    Write-Warning "isar_flutter_libs not found at $baseDir. Run 'flutter pub get' first."
    exit 1
}

$content = Get-Content $buildGradle -Raw
if ($content -match "namespace\s+['\`"]dev\.isar\.isar_flutter_libs['\`"]") {
    Write-Host "Namespace already set in isar_flutter_libs."
    exit 0
}

# Match "android {" followed by newline (Windows or Unix)
$newContent = $content -replace "(?m)^(android\s+\{\s*\r?\n)", "`$1    namespace 'dev.isar.isar_flutter_libs'`r`n"
if ($newContent -eq $content) {
    Write-Error "Could not find 'android {' in build.gradle."
    exit 1
}

# Preserve original line endings when writing
$bytes = [System.Text.Encoding]::UTF8.GetBytes($newContent)
[System.IO.File]::WriteAllBytes($buildGradle, $bytes)
Write-Host "Patched isar_flutter_libs android/build.gradle with namespace."
