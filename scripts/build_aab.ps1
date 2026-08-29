# Reliable Windows release AAB build.
# Fixes recurring PathExistsException (errno 183) from stale flutter_assets.
$ErrorActionPreference = "Stop"
Set-Location (Split-Path $PSScriptRoot -Parent)

Write-Host "==> Stopping Gradle daemons..." -ForegroundColor Cyan
if (Test-Path "android\gradlew.bat") {
  Push-Location android
  .\gradlew.bat --stop 2>$null
  Pop-Location
}

Write-Host "==> flutter clean..." -ForegroundColor Cyan
flutter clean

if (Test-Path "build") {
  Write-Host "==> Removing leftover build\" -ForegroundColor Cyan
  cmd /c "rmdir /s /q build"
}

Write-Host "==> flutter pub get..." -ForegroundColor Cyan
flutter pub get

Write-Host "==> flutter build appbundle --release..." -ForegroundColor Cyan
flutter build appbundle --release

if ($LASTEXITCODE -eq 0) {
  Write-Host "`nOK: build\app\outputs\bundle\release\app-release.aab" -ForegroundColor Green
} else {
  Write-Host "`nBuild failed (exit $LASTEXITCODE)." -ForegroundColor Red
  exit $LASTEXITCODE
}
