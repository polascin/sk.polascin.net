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
Na `refbook.sk.php?data=1` overí dynamický `<title>` / description, `/styles.css`,
`rel=canonical`; pri `?data=abc` (404) generický title bez canonical. Skip-link
outline `#6a0dad` a `Cache-Control max-age` idú cez versioned `/styles.css?v=`
(holé `/styles.css` môže byť edge-cached). Overí aj jeden Fedora odkaz v pätičke,
`twitter:image:alt`, versioned `/favicon.ico?v=` + apple-touch-icon a versioned
`/favicon/site.webmanifest?v=` (`theme_color` / `background_color` `#f5fffa`,
`start_url`, `id`, `scope`, `lang`, `description`, icon `purpose`, `Content-Type`
`application/manifest+json`, Cache-Control). HEAD `/favicon.ico` → 200. Overí
OG/Twitter na privacy/terms a na `refbook.sk.php` (dynamický `og:title` /
`og:url` pri `?data=1`; 404 bez `og:url` s generickým `og:title`)
a `/js/current.js` (okamžitý
`updateDateTime` pred `setInterval`, `formatToParts`, null-safe DOM, obnovu
`daynumber` v každom ticku, lokálny ISO týždeň bez `getUTCDay`, Cache-Control;
telo JS sa číta výhradne z verziovaného `?v=` URL, bez fallbacku na holé
`/js/current.js` kvôli edge cache) a na homepage verziovaný
`src="/js/current.js?v="` plus vek so zachovanou desatinnou časťou
(`(N<small>.xxx</small>)`), JSON-LD e-mail bez `mailto:` plus `description` /
`inLanguage` / `knowsAbout`, `hreflang` sk/x-default, HTML `Cache-Control:
no-cache, must-revalidate` na PHP, Quotation JSON-LD na refbooku (Book `isbn`
bez textového prefixu `ISBN `, Book aj Quotation `inLanguage` vrátane mapovania
cz→cs), Cache-Control pre `mel.pdf` a `sitemap.xml`, `color-scheme: light`,
`loading=lazy` na odborných obrázkoch (`dial.jpeg`, `klinef.jpeg`, …),
nadpisy bez preskoku úrovní (Amazon knihy `h2`, podsekcie nefamb `h3`),
JSON-LD `@graph` (`WebSite` + `WebPage` + `Person`, `publisher`/`isPartOf`/
`mainEntity` `@id`), `sameAs` vrátane `https://polascin.sk/` (assert scoped
do `sameAs`, nie nav `href`), focus outline Clarity `#6a0dad` (zhoda so
skip-link), `main` `aria-label="Hlavný obsah"`, footer
`aria-label="Pätička stránky"`, bio `title` na kontaktných/Amazon odkazoch,
Permissions-Policy `browsing-topics=()` / `interest-cohort=()`,
`robots.txt` s `Allow: /docs/mel.pdf` pri `Disallow: /docs/`, a verziovaný
`clarity-consent.js` s `aria-modal`, Escape, focus trap, `aria-describedby` /
`aria-expanded`, `data-css-v` pre cache-bust CSS a obnovenie focusu na tlačidlo
nastavení po Allow/Decline, keď dialóg otvorili nastavenia: `returnToSettings`
pred `closeBanner()`, `settings.focus()` len na vetve bez `location.reload()`).
Súbor `smoke-prod.ps1` musí ostať UTF-8 s BOM
(Windows PowerShell 5.1 + slovenské znaky). Skrátený UA → 466.
Detaily: `docs/manual-steps-clarity-and-polascin-sk.md` sekcia C.

## Konfigurácia

| Súbor | Účel |
|-------|------|
| `phpstan.neon.dist` | PHPStan — úroveň 4 (postupne zvyšuj k 9) |
| `phpstan-baseline.neon` | zoznam ignorovaných existujúcich nálezov (regeneruje install skript) |
| `.php-cs-fixer.dist.php` | PHP-CS-Fixer — konzervatívna sada nízkorizikových pravidiel |
