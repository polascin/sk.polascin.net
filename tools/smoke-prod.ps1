# Produkčný smoke sk.polascin.net s plným browser User-Agent.
# Skrátený UA môže dostať HTTP 466 (ochrana hostingu).
# Vyžaduje Windows PowerShell 5.1+.
#
# Očakávané kódy (Beh #13 / #14):
#   200  - verejné stránky
#   301  - /privacy, /terms aliasy
#   403  - Apache .htaccess [F] (blocks/, tools/, db.config.php, ...)
#   404  - neplatný refbook ?data=
#   509  - OpenResty edge na /.github (aj /.git, ...); NIE chyba .htaccess
#   466  - OpenResty edge na niektorých cestách (/.env, /.codex/, /.trunk/)
#
# Beh #15: na GET / overí aj kľúčové bezpečnostné hlavičky a počet
# kidneybiopsy.en.jpg (2 pixbanner strips x 1 img = 2).
# Beh #18: root-absolútne /styles.css; na privacy/terms krížové odkazy.
# Beh #19: refbook ?data=1 dynamický <title>/description; /styles.css; 404 generický title.
# Beh #20: skip-link focus #6a0dad; Clarity paths /privacy,/terms; orphan styles.sk.css.php removed.
# Beh #21: Cache-Control on css/js/images; refbook canonical when quote found; no duplicate Fedora logo.
# Beh #22: twitter:image:alt; webmanifest theme #f5fffa; MIME application/manifest+json; start_url/lang.
# Beh #23: current.js immediate tick, formatToParts TZ, null-safe DOM.
# Beh #24: current.js refreshes day/week/year/TZ each tick; local ISO week; age sprintf.
#          JS body asserts require versioned ?v= (no bare fallback); age decimal on home.
# Beh #25: JSON-LD email without mailto:; Clarity dialog aria-modal + Escape.
# Beh #26: modal focus trap / aria-describedby / aria-expanded; versioned clarity CSS.
# Beh #27: versioned webmanifest + description/purpose; root favicon.ico link; legal OG/Twitter.
# Beh #28: refbook OG/Twitter (dynamic title); versioned favicon PNG/ICO; /favicon.ico HEAD 200.
# Beh #29: PHP HTML Cache-Control no-cache; JSON-LD description/inLanguage/knowsAbout; hreflang.
# Beh #30: Clarity settings focus restore after Allow/Decline from settings.
# Beh #31: refbook Quotation JSON-LD; optional ISO lang on blockquote; bio mailto title.
# Beh #30: Clarity apply() restores focus to settings when openedFromSettings (non-reload).
# Beh #32: refbook lang aliases cz→cs (and ua/gr/jp/cn).
# Beh #33: Quotation isbn without ISBN prefix; PDF/XML Cache-Control; sitemap lastmod; iframe title.
# Beh #32: Quotation Book isbn without "ISBN " label; Book inLanguage; cz→cs already on tip.
#
# Spusti z koreňa:  .\tools\smoke-prod.ps1

$ErrorActionPreference = 'Stop'
$ua = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
$base = 'https://sk.polascin.net'

# path => expected status
$checks = [ordered]@{
    '/'                        = 200
    '/privacy.php'             = 200
    '/terms.php'               = 200
    '/sitemap.xml'             = 200
    '/docs/mel.pdf'            = 200
    '/js/clarity-consent.js'   = 200
    '/js/current.js'           = 200
    '/styles.css'              = 200
    '/favicon/site.webmanifest'= 200
    '/favicon.ico'             = 200
    '/refbook.sk.php?data=1'   = 200
    '/refbook.sk.php?data=abc' = 404
    '/privacy'                 = 301
    '/terms'                   = 301
    '/blocks/'                 = 403
    '/files/'                  = 403
    '/tools/'                  = 403
    '/.codex'                  = 403
    '/.cursor'                 = 403
    '/db.config.php'           = 403
    '/.github'                 = 509
}

function Get-HttpStatus {
    param(
        [string]$Uri,
        [string]$UserAgent
    )
    try {
        $req = [System.Net.HttpWebRequest]::Create($Uri)
        $req.Method = 'HEAD'
        $req.UserAgent = $UserAgent
        $req.AllowAutoRedirect = $false
        $req.Timeout = 30000
        $resp = $req.GetResponse()
        $code = [int]$resp.StatusCode
        $resp.Close()
        return $code
    } catch [System.Net.WebException] {
        $webResp = $_.Exception.Response
        if ($null -ne $webResp) {
            $code = [int]$webResp.StatusCode
            $webResp.Close()
            return $code
        }
        throw
    }
}

function Get-PageProbe {
    param(
        [string]$Path,
        [string]$UserAgent,
        [int]$ExpectedStatus = 200
    )
    $req = [System.Net.HttpWebRequest]::Create("$base$Path")
    $req.Method = 'GET'
    $req.UserAgent = $UserAgent
    $req.AllowAutoRedirect = $false
    $req.Timeout = 30000
    $resp = $null
    try {
        $resp = $req.GetResponse()
    } catch [System.Net.WebException] {
        $resp = $_.Exception.Response
        if ($null -eq $resp) { throw }
    }
    try {
        $code = [int]$resp.StatusCode
        if ($code -ne $ExpectedStatus) {
            throw "Unexpected status $code (expected $ExpectedStatus) for $Path"
        }
        $headers = @{}
        foreach ($name in $resp.Headers.AllKeys) {
            $headers[$name] = $resp.Headers[$name]
        }
        $reader = New-Object System.IO.StreamReader($resp.GetResponseStream())
        $body = $reader.ReadToEnd()
        $reader.Close()
        return @{ Headers = $headers; Body = $body; StatusCode = $code }
    } finally {
        $resp.Close()
    }
}

function Assert-BodyContains {
    param(
        [string]$Label,
        [string]$Body,
        [string]$Pattern,
        [string]$OkMessage
    )
    if ($Body -notmatch $Pattern) {
        Write-Host "FAIL $Label missing match: $Pattern" -ForegroundColor Red
        return 1
    }
    Write-Host "OK $OkMessage" -ForegroundColor Green
    return 0
}

$failed = 0
foreach ($path in $checks.Keys) {
    $expected = [int]$checks[$path]
    $url = "$base$path"
    try {
        $code = Get-HttpStatus -Uri $url -UserAgent $ua
    } catch {
        Write-Host "FAIL $url - $($_.Exception.Message)" -ForegroundColor Red
        $failed++
        continue
    }
    $ok = ($code -eq $expected)
    $mark = if ($ok) { 'OK' } else { 'FAIL' }
    $color = if ($ok) { 'Green' } else { 'Red' }
    Write-Host "$mark $url -> $code (expected $expected)" -ForegroundColor $color
    if (-not $ok) { $failed++ }
}

Write-Host ""
Write-Host "Static asset Cache-Control (PDF / sitemap)" -ForegroundColor Cyan
try {
    $pdf = Get-PageProbe -Path '/docs/mel.pdf' -UserAgent $ua
    $pdfCc = $null
    foreach ($key in $pdf.Headers.Keys) {
        if ($key -ieq 'Cache-Control') { $pdfCc = $pdf.Headers[$key]; break }
    }
    if ($pdfCc -and ($pdfCc -match 'max-age=')) {
        Write-Host ('OK mel.pdf Cache-Control={0}' -f $pdfCc) -ForegroundColor Green
    } else {
        Write-Host ('FAIL mel.pdf missing Cache-Control max-age (got {0})' -f $pdfCc) -ForegroundColor Red
        $failed++
    }
    $map = Get-PageProbe -Path '/sitemap.xml' -UserAgent $ua
    $mapCc = $null
    foreach ($key in $map.Headers.Keys) {
        if ($key -ieq 'Cache-Control') { $mapCc = $map.Headers[$key]; break }
    }
    if ($mapCc -and ($mapCc -match 'max-age=')) {
        Write-Host ('OK sitemap.xml Cache-Control={0}' -f $mapCc) -ForegroundColor Green
    } else {
        Write-Host ('FAIL sitemap.xml missing Cache-Control max-age (got {0})' -f $mapCc) -ForegroundColor Red
        $failed++
    }
    $failed += Assert-BodyContains -Label 'sitemap' -Body $map.Body -Pattern '<lastmod>2026-11-06</lastmod>' -OkMessage 'sitemap lastmod 2026-11-06'
} catch {
    Write-Host "FAIL PDF/sitemap cache probe - $($_.Exception.Message)" -ForegroundColor Red
    $failed++
}

Write-Host ""
Write-Host "Home GET: security headers + pixbanner count" -ForegroundColor Cyan
try {
    $probe = Get-PageProbe -Path '/' -UserAgent $ua
    $requiredHeaders = [ordered]@{
        'X-Content-Type-Options'      = 'nosniff'
        'Cross-Origin-Resource-Policy' = 'same-origin'
        'Content-Security-Policy'     = $null  # presence only
        'Referrer-Policy'             = 'strict-origin-when-cross-origin'
    }
    foreach ($hName in $requiredHeaders.Keys) {
        $actual = $null
        foreach ($key in $probe.Headers.Keys) {
            if ($key -ieq $hName) { $actual = $probe.Headers[$key]; break }
        }
        if ([string]::IsNullOrEmpty($actual)) {
            Write-Host "FAIL header missing: $hName" -ForegroundColor Red
            $failed++
            continue
        }
        $want = $requiredHeaders[$hName]
        if ($null -ne $want -and ($actual -notlike "*$want*")) {
            Write-Host "FAIL header $hName = '$actual' (expected contains '$want')" -ForegroundColor Red
            $failed++
        } else {
            Write-Host "OK header $hName" -ForegroundColor Green
        }
    }
    $homeCc = $null
    foreach ($key in $probe.Headers.Keys) {
        if ($key -ieq 'Cache-Control') { $homeCc = $probe.Headers[$key]; break }
    }
    if ($homeCc -and ($homeCc -match 'no-cache') -and ($homeCc -match 'must-revalidate')) {
        Write-Host ('OK home Cache-Control={0}' -f $homeCc) -ForegroundColor Green
    } else {
        Write-Host ('FAIL home Cache-Control missing no-cache/must-revalidate (got {0})' -f $homeCc) -ForegroundColor Red
        $failed++
    }
    $kbCount = ([regex]::Matches($probe.Body, 'kidneybiopsy\.en\.jpg')).Count
    if ($kbCount -eq 2) {
        Write-Host ('OK kidneybiopsy.en.jpg count={0} two pixbanner strips' -f $kbCount) -ForegroundColor Green
    } else {
        Write-Host ('FAIL kidneybiopsy.en.jpg count={0} expected 2' -f $kbCount) -ForegroundColor Red
        $failed++
    }
    $fedoraCount = ([regex]::Matches($probe.Body, 'fedoraproject\.org')).Count
    if ($fedoraCount -eq 1) {
        Write-Host ('OK fedora footer link count={0}' -f $fedoraCount) -ForegroundColor Green
    } else {
        Write-Host ('FAIL fedora footer link count={0} expected 1' -f $fedoraCount) -ForegroundColor Red
        $failed++
    }
    $failed += Assert-BodyContains -Label 'home' -Body $probe.Body -Pattern 'href="/docs/mel\.pdf"' -OkMessage 'home link /docs/mel.pdf'
    $failed += Assert-BodyContains -Label 'home' -Body $probe.Body -Pattern 'title="Mimotelová eliminačná liečba\. Copyright 2009"' -OkMessage 'home mel.pdf iframe title without HTML entity'
    $failed += Assert-BodyContains -Label 'home' -Body $probe.Body -Pattern 'href="/styles\.css\?v=' -OkMessage 'home stylesheet /styles.css'
    $failed += Assert-BodyContains -Label 'home' -Body $probe.Body -Pattern 'src="/js/current\.js\?v=\d+"' -OkMessage 'home script /js/current.js?v='
    $failed += Assert-BodyContains -Label 'home' -Body $probe.Body -Pattern 'name="twitter:image:alt" content="Fotografia' -OkMessage 'home twitter:image:alt'
    $failed += Assert-BodyContains -Label 'home' -Body $probe.Body -Pattern 'data-paths="[^"]*/privacy[^"]*/terms"' -OkMessage 'home clarity paths include /privacy and /terms'
    $failed += Assert-BodyContains -Label 'home' -Body $probe.Body -Pattern 'data-css-v="\d+"' -OkMessage 'home clarity consent data-css-v cache buster'
    $failed += Assert-BodyContains -Label 'home' -Body $probe.Body -Pattern '"email":\s*"lubomir@polascin\.net"' -OkMessage 'home JSON-LD email without mailto:'
    if ($probe.Body -match '"email":\s*"mailto:') {
        Write-Host 'FAIL home JSON-LD email still uses mailto:' -ForegroundColor Red
        $failed++
    }
    $failed += Assert-BodyContains -Label 'home' -Body $probe.Body -Pattern '"description":\s*"MUDr\.' -OkMessage 'home JSON-LD Person description'
    $failed += Assert-BodyContains -Label 'home' -Body $probe.Body -Pattern '"inLanguage":\s*"sk"' -OkMessage 'home JSON-LD inLanguage sk'
    $failed += Assert-BodyContains -Label 'home' -Body $probe.Body -Pattern '"knowsAbout"' -OkMessage 'home JSON-LD knowsAbout'
    $failed += Assert-BodyContains -Label 'home' -Body $probe.Body -Pattern 'rel="alternate" hreflang="sk"' -OkMessage 'home hreflang sk'
    $failed += Assert-BodyContains -Label 'home' -Body $probe.Body -Pattern 'rel="alternate" hreflang="x-default"' -OkMessage 'home hreflang x-default'
    $failed += Assert-BodyContains -Label 'home' -Body $probe.Body -Pattern 'href="/favicon\.ico\?v=\d+"' -OkMessage 'home versioned /favicon.ico?v='
    $failed += Assert-BodyContains -Label 'home' -Body $probe.Body -Pattern 'href="/favicon/apple-touch-icon\.png\?v=\d+"' -OkMessage 'home versioned apple-touch-icon'
    # Bare webmanifest may be edge-cached; pages use ?v=filemtime.
    if ($probe.Body -match 'href="(/favicon/site\.webmanifest\?v=\d+)"') {
        $manifestPath = $Matches[1]
        Write-Host ('OK home webmanifest href {0}' -f $manifestPath) -ForegroundColor Green
        $manifest = Get-PageProbe -Path $manifestPath -UserAgent $ua
        $failed += Assert-BodyContains -Label 'manifest' -Body $manifest.Body -Pattern '"theme_color":\s*"#f5fffa"' -OkMessage 'webmanifest theme_color #f5fffa'
        $failed += Assert-BodyContains -Label 'manifest' -Body $manifest.Body -Pattern '"background_color":\s*"#f5fffa"' -OkMessage 'webmanifest background_color #f5fffa'
        $failed += Assert-BodyContains -Label 'manifest' -Body $manifest.Body -Pattern '"start_url":\s*"/"' -OkMessage 'webmanifest start_url /'
        $failed += Assert-BodyContains -Label 'manifest' -Body $manifest.Body -Pattern '"id":\s*"/"' -OkMessage 'webmanifest id /'
        $failed += Assert-BodyContains -Label 'manifest' -Body $manifest.Body -Pattern '"lang":\s*"sk"' -OkMessage 'webmanifest lang sk'
        $failed += Assert-BodyContains -Label 'manifest' -Body $manifest.Body -Pattern '"scope":\s*"/"' -OkMessage 'webmanifest scope /'
        $failed += Assert-BodyContains -Label 'manifest' -Body $manifest.Body -Pattern '"description":\s*"Webové sídlo' -OkMessage 'webmanifest description'
        $failed += Assert-BodyContains -Label 'manifest' -Body $manifest.Body -Pattern '"purpose":\s*"any"' -OkMessage 'webmanifest icon purpose any'
        $manifestCt = $null
        $manifestCc = $null
        foreach ($key in $manifest.Headers.Keys) {
            if ($key -ieq 'Content-Type') { $manifestCt = $manifest.Headers[$key] }
            if ($key -ieq 'Cache-Control') { $manifestCc = $manifest.Headers[$key] }
        }
        # Media type may include optional charset parameter.
        if ($manifestCt -and ($manifestCt -match '(?i)^application/manifest\+json(\s*;|$)')) {
            Write-Host ('OK webmanifest Content-Type={0}' -f $manifestCt) -ForegroundColor Green
        } else {
            Write-Host ('FAIL webmanifest Content-Type missing application/manifest+json (got {0})' -f $manifestCt) -ForegroundColor Red
            $failed++
        }
        if ($manifestCc -and ($manifestCc -match 'max-age=')) {
            Write-Host ('OK webmanifest Cache-Control={0}' -f $manifestCc) -ForegroundColor Green
        } else {
            Write-Host 'FAIL webmanifest missing Cache-Control max-age' -ForegroundColor Red
            $failed++
        }
    } else {
        Write-Host 'FAIL home missing versioned /favicon/site.webmanifest?v=' -ForegroundColor Red
        $failed++
    }
    # Bare /js/current.js may be edge-cached; homepage uses ?v=filemtime - probe that URL for body.
    # Do not fall back to bare path: stale edge body falsely fails daynumber/getUTCDay asserts.
    if ($probe.Body -match 'src="(/js/current\.js\?v=\d+)"') {
        $clockPath = $Matches[1]
        $clock = Get-PageProbe -Path $clockPath -UserAgent $ua
        Write-Host ("OK current.js body probe via {0}" -f $clockPath) -ForegroundColor Green
        if ($clock.Body -match 'updateDateTime\(\);\s*setInterval\(updateDateTime') {
            Write-Host 'OK current.js calls updateDateTime before setInterval' -ForegroundColor Green
        } else {
            Write-Host 'FAIL current.js missing immediate updateDateTime() before setInterval' -ForegroundColor Red
            $failed++
        }
        if (($clock.Body -match 'formatToParts') -and ($clock.Body -match 'getElementById')) {
            Write-Host 'OK current.js uses formatToParts and getElementById guards' -ForegroundColor Green
        } else {
            Write-Host 'FAIL current.js missing formatToParts/getElementById hardening' -ForegroundColor Red
            $failed++
        }
        if (($clock.Body -match "setText\('daynumber'") -and ($clock.Body -match 'function updateDateTime') -and ($clock.Body -notmatch 'getUTCDay')) {
            Write-Host 'OK current.js refreshes daynumber in updateDateTime with local ISO week' -ForegroundColor Green
        } else {
            Write-Host 'FAIL current.js missing daynumber refresh or still uses getUTCDay' -ForegroundColor Red
            $failed++
        }
        $clockCc = $null
        foreach ($key in $clock.Headers.Keys) {
            if ($key -ieq 'Cache-Control') { $clockCc = $clock.Headers[$key]; break }
        }
        if ($clockCc -and ($clockCc -match 'max-age=')) {
            Write-Host ('OK current.js Cache-Control={0}' -f $clockCc) -ForegroundColor Green
        } else {
            Write-Host 'FAIL current.js missing Cache-Control max-age' -ForegroundColor Red
            $failed++
        }
    } else {
        Write-Host 'FAIL home missing versioned /js/current.js?v= for JS body probe' -ForegroundColor Red
        $failed++
    }
    # Age fraction must keep a decimal point (sprintf %.3f); whole ages used to drop the fraction.
    $failed += Assert-BodyContains -Label 'home' -Body $probe.Body -Pattern '\(\d+<small>\.\d{3}</small>\)' -OkMessage 'home age keeps decimal fraction via sprintf'
    # Clarity consent a11y: modal pattern (versioned script; bare path may be edge-cached).
    if ($probe.Body -match 'src="(/js/clarity-consent\.js\?v=\d+)"') {
        $consent = Get-PageProbe -Path $Matches[1] -UserAgent $ua
        $hasModal = ($consent.Body -match 'aria-modal') -and ($consent.Body -match 'Escape')
        $hasFocus = ($consent.Body -match 'aria-describedby') -and ($consent.Body -match 'aria-expanded') -and ($consent.Body -match 'e\.key !== "Tab"')
        $hasCssV = ($consent.Body -match 'dataset\.cssV') -and ($consent.Body -match 'searchParams\.set\("v"')
        # Apply-path restore: flag before closeBanner; settings.focus only on non-reload branch.
        # Loose "settings.focus" alone matches Escape and would stay green with the bug.
        $hasApplyRestore = ($consent.Body -match 'const returnToSettings = openedFromSettings') -and
            ($consent.Body -match 'if \(loaded && persist\) \{\s*closeBanner\(\);\s*location\.reload\(\);\s*return;') -and
            ($consent.Body -match 'if \(returnToSettings && document\.contains\(settings\)\) \{\s*settings\.focus\(\);')
        if ($hasModal -and $hasFocus -and $hasCssV -and $hasApplyRestore) {
            Write-Host 'OK clarity-consent.js modal a11y (Escape, focus trap, apply focus restore, css ?v=)' -ForegroundColor Green
        } else {
            Write-Host 'FAIL clarity-consent.js missing modal a11y/focus trap/apply restore/css versioning' -ForegroundColor Red
            $failed++
        }
    } else {
        Write-Host 'FAIL home missing versioned /js/clarity-consent.js?v= for a11y probe' -ForegroundColor Red
        $failed++
    }
    # Bare /styles.css may be edge-cached; pages use ?v=filemtime - probe that URL.
    if ($probe.Body -match 'href="(/styles\.css\?v=\d+)"') {
        $styles = Get-PageProbe -Path $Matches[1] -UserAgent $ua
        $failed += Assert-BodyContains -Label 'styles.css' -Body $styles.Body -Pattern 'skip-link:focus[\s\S]{0,160}#6a0dad' -OkMessage 'skip-link focus outline #6a0dad (versioned CSS)'
        $cc = $null
        foreach ($key in $styles.Headers.Keys) {
            if ($key -ieq 'Cache-Control') { $cc = $styles.Headers[$key]; break }
        }
        if ($cc -and ($cc -match 'max-age=')) {
            Write-Host ('OK styles.css Cache-Control={0}' -f $cc) -ForegroundColor Green
        } else {
            Write-Host 'FAIL styles.css missing Cache-Control max-age' -ForegroundColor Red
            $failed++
        }
    } else {
        Write-Host 'FAIL home missing versioned /styles.css?v= for CSS probe' -ForegroundColor Red
        $failed++
    }
} catch {
    Write-Host "FAIL home GET probe - $($_.Exception.Message)" -ForegroundColor Red
    $failed++
}

Write-Host ""
Write-Host "Legal GET: root-absolute cross-links + stylesheet" -ForegroundColor Cyan
try {
    $privacy = Get-PageProbe -Path '/privacy.php' -UserAgent $ua
    $failed += Assert-BodyContains -Label 'privacy' -Body $privacy.Body -Pattern 'href="/styles\.css\?v=' -OkMessage 'privacy stylesheet /styles.css'
    $failed += Assert-BodyContains -Label 'privacy' -Body $privacy.Body -Pattern 'href="/terms"' -OkMessage 'privacy link /terms'
    $failed += Assert-BodyContains -Label 'privacy' -Body $privacy.Body -Pattern 'href="/refbook\.sk\.php"' -OkMessage 'privacy link /refbook.sk.php'
    $failed += Assert-BodyContains -Label 'privacy' -Body $privacy.Body -Pattern 'property="og:title" content="Ochrana osobných údajov' -OkMessage 'privacy og:title'
    $failed += Assert-BodyContains -Label 'privacy' -Body $privacy.Body -Pattern 'name="twitter:image:alt"' -OkMessage 'privacy twitter:image:alt'

    $terms = Get-PageProbe -Path '/terms.php' -UserAgent $ua
    $failed += Assert-BodyContains -Label 'terms' -Body $terms.Body -Pattern 'href="/styles\.css\?v=' -OkMessage 'terms stylesheet /styles.css'
    $failed += Assert-BodyContains -Label 'terms' -Body $terms.Body -Pattern 'href="/privacy"' -OkMessage 'terms link /privacy'
    $failed += Assert-BodyContains -Label 'terms' -Body $terms.Body -Pattern 'property="og:title" content="Podmienky používania' -OkMessage 'terms og:title'
    $failed += Assert-BodyContains -Label 'terms' -Body $terms.Body -Pattern 'name="twitter:image:alt"' -OkMessage 'terms twitter:image:alt'
} catch {
    Write-Host "FAIL legal GET probe - $($_.Exception.Message)" -ForegroundColor Red
    $failed++
}

Write-Host ""
Write-Host "Refbook GET: dynamic title/description + stylesheet" -ForegroundColor Cyan
$genericTitle = 'Kniha, z ktorej je citát \(sk\.polascin\.net\)'
try {
    $refOk = Get-PageProbe -Path '/refbook.sk.php?data=1' -UserAgent $ua
    if ($refOk.Body -match $genericTitle) {
        Write-Host "FAIL refbook data=1 still has generic title" -ForegroundColor Red
        $failed++
    } else {
        Write-Host "OK refbook data=1 dynamic title (not generic)" -ForegroundColor Green
    }
    # data=1 is a stable fixture (Isaac Bashevis Singer); assert author + non-empty snippet in <title>
    $failed += Assert-BodyContains -Label 'refbook' -Body $refOk.Body -Pattern '<title>Isaac Bashevis Singer:\s+[^<]{10,}</title>' -OkMessage 'refbook data=1 title has author + snippet'
    $failed += Assert-BodyContains -Label 'refbook' -Body $refOk.Body -Pattern 'name="description" content="Citát od autora Isaac Bashevis Singer' -OkMessage 'refbook data=1 description names author'
    $failed += Assert-BodyContains -Label 'refbook' -Body $refOk.Body -Pattern 'href="/styles\.css\?v=\d+"' -OkMessage 'refbook stylesheet /styles.css?v='
    $failed += Assert-BodyContains -Label 'refbook' -Body $refOk.Body -Pattern 'rel="canonical" href="https://sk\.polascin\.net/refbook\.sk\.php\?data=1"' -OkMessage 'refbook data=1 canonical'
    $failed += Assert-BodyContains -Label 'refbook' -Body $refOk.Body -Pattern 'property="og:title" content="Isaac Bashevis Singer:' -OkMessage 'refbook data=1 og:title'
    $failed += Assert-BodyContains -Label 'refbook' -Body $refOk.Body -Pattern 'property="og:url" content="https://sk\.polascin\.net/refbook\.sk\.php\?data=1"' -OkMessage 'refbook data=1 og:url'
    $failed += Assert-BodyContains -Label 'refbook' -Body $refOk.Body -Pattern '"@type":\s*"Quotation"' -OkMessage 'refbook Quotation JSON-LD'
    $failed += Assert-BodyContains -Label 'refbook' -Body $refOk.Body -Pattern '"author"\s*:\s*\{\s*"@type"\s*:\s*"Person"' -OkMessage 'refbook Quotation author Person'
    # data=1 book lang is stored as "cz" in DB; JSON-LD/lang must emit ISO 639-1 "cs".
    $failed += Assert-BodyContains -Label 'refbook' -Body $refOk.Body -Pattern '"inLanguage":\s*"cs"' -OkMessage 'refbook Quotation inLanguage cs (not cz)'
    if ($refOk.Body -match '"inLanguage":\s*"cz"') {
        Write-Host 'FAIL refbook still emits invalid inLanguage cz' -ForegroundColor Red
        $failed++
    }
    $failed += Assert-BodyContains -Label 'refbook' -Body $refOk.Body -Pattern '"isbn":\s*"978-' -OkMessage 'refbook Quotation isbn without ISBN prefix'
    if ($refOk.Body -match '"isbn":\s*"ISBN') {
        Write-Host 'FAIL refbook Quotation isbn still has ISBN label prefix' -ForegroundColor Red
        $failed++
    }
    # data=1 isbn is stored with an "ISBN " label; JSON-LD isbn must be the identifier only.
    $failed += Assert-BodyContains -Label 'refbook' -Body $refOk.Body -Pattern '"isbn":\s*"978-' -OkMessage 'refbook Book isbn without ISBN label'
    if ($refOk.Body -match '"isbn":\s*"ISBN\s') {
        Write-Host 'FAIL refbook JSON-LD isbn still has ISBN label prefix' -ForegroundColor Red
        $failed++
    }
    $failed += Assert-BodyContains -Label 'refbook' -Body $refOk.Body -Pattern '"@type":\s*"Book"[^}]*"inLanguage":\s*"cs"' -OkMessage 'refbook Book inLanguage cs'
    if ($refOk.Body -match '"@type":\s*"Quotation"' -and $refOk.Body -notmatch 'application/ld\+json') {
        Write-Host 'FAIL refbook Quotation JSON-LD missing script type' -ForegroundColor Red
        $failed++
    }
    $failed += Assert-BodyContains -Label 'refbook' -Body $refOk.Body -Pattern 'name="twitter:image:alt"' -OkMessage 'refbook twitter:image:alt'

    $ref404 = Get-PageProbe -Path '/refbook.sk.php?data=abc' -UserAgent $ua -ExpectedStatus 404
    if ($ref404.Body -match $genericTitle) {
        Write-Host "OK refbook 404 keeps generic title" -ForegroundColor Green
    } else {
        Write-Host "FAIL refbook 404 missing generic title" -ForegroundColor Red
        $failed++
    }
    if ($ref404.Body -match 'rel="canonical"') {
        Write-Host 'FAIL refbook 404 should not expose canonical' -ForegroundColor Red
        $failed++
    } else {
        Write-Host 'OK refbook 404 has no canonical' -ForegroundColor Green
    }
    if ($ref404.Body -match 'property="og:url"') {
        Write-Host 'FAIL refbook 404 should not expose og:url' -ForegroundColor Red
        $failed++
    } else {
        Write-Host 'OK refbook 404 has no og:url' -ForegroundColor Green
    }
    $failed += Assert-BodyContains -Label 'refbook404' -Body $ref404.Body -Pattern 'property="og:title" content="Kniha, z ktorej je citát' -OkMessage 'refbook 404 generic og:title'
} catch {
    Write-Host "FAIL refbook GET probe - $($_.Exception.Message)" -ForegroundColor Red
    $failed++
}

if ($failed -gt 0) {
    Write-Host ""
    Write-Host ('Smoke zlyhal: {0} kontrol(y).' -f $failed) -ForegroundColor Red
    exit 1
}
Write-Host ""
Write-Host 'Smoke OK: 403 Apache, 509 OpenResty edge; headers, pixbanner, legal, refbook title.' -ForegroundColor Green
exit 0
