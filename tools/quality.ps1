# Lokálna kontrola kvality PHP kódu (PHPStan + PHP-CS-Fixer).
# Spusti z koreňa projektu:
#   .\tools\quality.ps1          # statická analýza + náhľad formátovania (nič nemení)
#   .\tools\quality.ps1 -Fix     # aplikuje opravy formátovania
#
# Nástroje najprv nainštaluj cez:  .\tools\install-dev-tools.ps1

param([switch]$Fix)

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$phpstan = Join-Path $PSScriptRoot 'phpstan.phar'
$fixer   = Join-Path $PSScriptRoot 'php-cs-fixer.phar'

if (-not (Test-Path $phpstan) -or -not (Test-Path $fixer)) {
    Write-Host 'Chýbajú PHAR nástroje. Spusti najprv: .\tools\install-dev-tools.ps1' -ForegroundColor Red
    exit 1
}

Push-Location $root
try {
    Write-Host '=== PHPStan (statická analýza) ===' -ForegroundColor Cyan
    & php $phpstan analyse --no-progress
    $phpstanCode = $LASTEXITCODE

    Write-Host "`n=== PHP-CS-Fixer (formátovanie) ===" -ForegroundColor Cyan
    if ($Fix) {
        & php $fixer fix
    } else {
        & php $fixer fix --dry-run --diff
    }
    $fixerCode = $LASTEXITCODE

    if ($phpstanCode -ne 0 -or ($fixerCode -ne 0 -and -not $Fix)) {
        Write-Host "`nNašli sa nálezy (PHPStan: $phpstanCode, Fixer: $fixerCode)." -ForegroundColor Yellow
        if (-not $Fix) { Write-Host 'Formátovanie oprav cez: .\tools\quality.ps1 -Fix' -ForegroundColor Yellow }
        exit 1
    }
    Write-Host "`nVšetko v poriadku." -ForegroundColor Green
} finally {
    Pop-Location
}
