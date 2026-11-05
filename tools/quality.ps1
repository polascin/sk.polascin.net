# Lokálna kontrola kvality PHP kódu (PHPStan + PHP-CS-Fixer).
# Spusti z koreňa projektu:
#   .\tools\quality.ps1                      # PHPStan + dry-run formátovania (nič nemení)
#   .\tools\quality.ps1 -Fix -AllowRenormalize  # až po schválenom `git add --renormalize .`
#
# Nástroje najprv nainštaluj cez:  .\tools\install-dev-tools.ps1
#
# Poznámka (composer.json / PHPStan Turbo): tento projekt zámerne nemá composer.json.
# PHPStan PHAR môže vypísať NOTE o Turbo alebo „Install PHPStan with Composer“ —
# to nie je chyba ani požiadavka na Composer. PHAR cez tools/ stačí.
# PHP-CS-Fixer -Fix: na Windows často len CRLF→LF. Bez -AllowRenormalize sa -Fix odmietne
# (pozri .gitattributes a .audit.md).

param(
    [switch]$Fix,
    [switch]$AllowRenormalize
)

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$phpstan = Join-Path $PSScriptRoot 'phpstan.phar'
$fixer   = Join-Path $PSScriptRoot 'php-cs-fixer.phar'

if (-not (Test-Path $phpstan) -or -not (Test-Path $fixer)) {
    Write-Host 'Chýbajú PHAR nástroje. Spusti najprv: .\tools\install-dev-tools.ps1' -ForegroundColor Red
    exit 1
}

if ($Fix -and -not $AllowRenormalize) {
    Write-Host 'Odmietnuté: -Fix bez -AllowRenormalize.' -ForegroundColor Red
    Write-Host 'Dry-run diff je často len CRLF→LF. Najprv schváľ `git add --renormalize .`,' -ForegroundColor Yellow
    Write-Host 'potom: .\tools\quality.ps1 -Fix -AllowRenormalize' -ForegroundColor Yellow
    exit 2
}

Push-Location $root
try {
    Write-Host '=== PHPStan (statická analýza) ===' -ForegroundColor Cyan
    Write-Host '(NOTE o Turbo/Composer pri PHARe je očakávaný; composer.json tu nie je.)' -ForegroundColor DarkGray
    & php $phpstan analyse --no-progress
    $phpstanCode = $LASTEXITCODE

    Write-Host "`n=== PHP-CS-Fixer (formátovanie) ===" -ForegroundColor Cyan
    if ($Fix) {
        Write-Host 'Aplikujem -Fix (schválené cez -AllowRenormalize).' -ForegroundColor Yellow
        & php $fixer fix
    } else {
        & php $fixer fix --dry-run --diff
    }
    $fixerCode = $LASTEXITCODE

    if ($phpstanCode -ne 0 -or ($fixerCode -ne 0 -and -not $Fix)) {
        Write-Host "`nNašli sa nálezy (PHPStan: $phpstanCode, Fixer: $fixerCode)." -ForegroundColor Yellow
        if (-not $Fix) {
            Write-Host 'Formátovanie: skontroluj diff (často len EOL). -Fix len s -AllowRenormalize po schválení.' -ForegroundColor Yellow
        }
        exit 1
    }
    Write-Host "`nVšetko v poriadku." -ForegroundColor Green
} finally {
    Pop-Location
}
