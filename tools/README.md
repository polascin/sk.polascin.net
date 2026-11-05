# Lokálne vývojárske nástroje

Kontrola kvality PHP kódu **bez Composera** — nástroje sa sťahujú ako samostatné
PHAR súbory (sú v `.gitignore`, na server sa nedeployujú). Projekt **nemá**
`composer.json` zámerne. Ak PHPStan PHAR vypíše NOTE o Turbo / Composer, ignoruj
ho: nie je to chyba ani dôvod pridávať Composer.

## Inštalácia (raz)

```powershell
.\tools\install-dev-tools.ps1
```

Stiahne `phpstan.phar` + `php-cs-fixer.phar` do `tools/` a vygeneruje
`phpstan-baseline.neon` (existujúce nálezy sa ignorujú → hlásia sa len NOVÉ chyby).

## Každodenné použitie

```powershell
.\tools\quality.ps1                         # PHPStan + dry-run formátovania (nič nemení)
.\tools\quality.ps1 -Fix -AllowRenormalize  # až po schválenom `git add --renormalize .`
```

`-Fix` bez `-AllowRenormalize` sa odmietne: na Windows je diff často len CRLF→LF.

## Konfigurácia

| Súbor | Účel |
|-------|------|
| `phpstan.neon.dist` | PHPStan — úroveň 4 (postupne zvyšuj k 9) |
| `phpstan-baseline.neon` | zoznam ignorovaných existujúcich nálezov (regeneruje install skript) |
| `.php-cs-fixer.dist.php` | PHP-CS-Fixer — konzervatívna sada nízkorizikových pravidiel |
