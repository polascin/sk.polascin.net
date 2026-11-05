# Stiahne lokálne vývojárske PHP nástroje (PHPStan + PHP-CS-Fixer) ako PHAR.
# Composer nie je potrebný. Spusti z koreňa projektu:  .\tools\install-dev-tools.ps1
#
# PHAR súbory sú v .gitignore — NEnasadzujú sa na server (sú len pre lokálny vývoj).

$ErrorActionPreference = 'Stop'
$toolsDir = Join-Path $PSScriptRoot ''

$phpstanUrl  = 'https://github.com/phpstan/phpstan/releases/latest/download/phpstan.phar'
$fixerUrl    = 'https://cs.symfony.com/download/php-cs-fixer-v3.phar'
$phpstanPhar = Join-Path $toolsDir 'phpstan.phar'
$fixerPhar   = Join-Path $toolsDir 'php-cs-fixer.phar'

Write-Host 'Sťahujem PHPStan...' -ForegroundColor Cyan
Invoke-WebRequest -Uri $phpstanUrl -OutFile $phpstanPhar

Write-Host 'Sťahujem PHP-CS-Fixer...' -ForegroundColor Cyan
Invoke-WebRequest -Uri $fixerUrl -OutFile $fixerPhar

if (-not (Get-Command php -ErrorAction SilentlyContinue)) {
    Write-Host 'PHP nenájdený v PATH — PHAR súbory stiahnuté, overenie preskočené.' -ForegroundColor Yellow
    exit 0
}

Write-Host "`nVerzie:" -ForegroundColor Green
& php $phpstanPhar --version
& php $fixerPhar --version

# Vygeneruj baseline, aby existujúce nálezy neblokovali — rieš len NOVÉ chyby.
$projectRoot = Split-Path $PSScriptRoot -Parent
$baseline = Join-Path $projectRoot 'phpstan-baseline.neon'
Write-Host "`nGenerujem PHPStan baseline (existujúce nálezy sa ignorujú)..." -ForegroundColor Cyan
Push-Location $projectRoot
try {
    # Pri nula nálezoch treba --allow-empty-baseline, inak PHPStan baseline nevytvorí.
    & php $phpstanPhar analyse --generate-baseline=$baseline --allow-empty-baseline --no-progress
    if ($LASTEXITCODE -eq 0) {
        Write-Host 'Hotovo. Baseline: phpstan-baseline.neon' -ForegroundColor Green
    } else {
        Write-Host "PHPStan baseline skončil s kódom $LASTEXITCODE" -ForegroundColor Yellow
    }
} catch {
    Write-Host "PHPStan analýza zlyhala (baseline nevygenerovaný): $_" -ForegroundColor Yellow
} finally {
    Pop-Location
}

Write-Host "`nNástroje sú pripravené. Spúšťaj ich cez:  .\tools\quality.ps1" -ForegroundColor Green
