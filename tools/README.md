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

## Produkčný smoke (plný browser UA)

```powershell
.\tools\smoke-prod.ps1
```

Kontroluje 200 / 301 / 403 / 404 a **509** na `/.github` (OpenResty edge,
nie chyba `.htaccess`). Na GET `/` overí aj CORP / CSP / nosniff / Referrer-Policy,
počet `kidneybiopsy.en.jpg` (2 strips) a root-absolútne `/styles.css` + `/docs/mel.pdf`.
Na `privacy.php` / `terms.php` overí krížové odkazy (`/terms`, `/privacy`, `/refbook.sk.php`).
Na `refbook.sk.php?data=1` overí dynamický `<title>` / description a `/styles.css`;
pri `?data=abc` (404) generický title. Skip-link outline `#6a0dad` ide cez versioned
`/styles.css?v=` (holé `/styles.css` môže byť edge-cached). Súbor `smoke-prod.ps1`
musí ostať UTF-8 s BOM (Windows PowerShell 5.1 + slovenské znaky). Skrátený UA → 466.
Detaily: `docs/manual-steps-clarity-and-polascin-sk.md` sekcia C.

## Konfigurácia

| Súbor | Účel |
|-------|------|
| `phpstan.neon.dist` | PHPStan — úroveň 4 (postupne zvyšuj k 9) |
| `phpstan-baseline.neon` | zoznam ignorovaných existujúcich nálezov (regeneruje install skript) |
| `.php-cs-fixer.dist.php` | PHP-CS-Fixer — konzervatívna sada nízkorizikových pravidiel |
