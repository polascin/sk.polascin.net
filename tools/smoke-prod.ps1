# Produkčný smoke sk.polascin.net s plným browser User-Agent.
# Skrátený UA môže dostať HTTP 466 (ochrana hostingu).
# Vyžaduje Windows PowerShell 5.1+.
#
# Očakávané kódy (Beh #13 / #14):
#   200  — verejné stránky
#   301  — /privacy, /terms aliasy
#   403  — Apache .htaccess [F] (blocks/, tools/, db.config.php, …)
#   404  — neplatný refbook ?data=
#   509  — OpenResty edge na /.github (aj /.git, …); NIE chyba .htaccess
#   466  — OpenResty edge na niektorých cestách (/.env, /.codex/, /.trunk/)
#
# Beh #15: na GET / overí aj kľúčové bezpečnostné hlavičky a počet
# kidneybiopsy.en.jpg (2 pixbanner strips × 1 img = 2).
# Beh #18: root-absolútne /styles.css; na privacy/terms krížové odkazy.
# Beh #19: refbook ?data=1 dynamický <title>/description; /styles.css; 404 generický title.
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
        Write-Host "FAIL $url — $($_.Exception.Message)" -ForegroundColor Red
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
    $kbCount = ([regex]::Matches($probe.Body, 'kidneybiopsy\.en\.jpg')).Count
    if ($kbCount -eq 2) {
        Write-Host "OK kidneybiopsy.en.jpg count=$kbCount (2 pixbanner strips)" -ForegroundColor Green
    } else {
        Write-Host "FAIL kidneybiopsy.en.jpg count=$kbCount (expected 2)" -ForegroundColor Red
        $failed++
    }
    $failed += Assert-BodyContains -Label 'home' -Body $probe.Body -Pattern 'href="/docs/mel\.pdf"' -OkMessage 'home link /docs/mel.pdf'
    $failed += Assert-BodyContains -Label 'home' -Body $probe.Body -Pattern 'href="/styles\.css\?v=' -OkMessage 'home stylesheet /styles.css'
} catch {
    Write-Host "FAIL home GET probe — $($_.Exception.Message)" -ForegroundColor Red
    $failed++
}

Write-Host ""
Write-Host "Legal GET: root-absolute cross-links + stylesheet" -ForegroundColor Cyan
try {
    $privacy = Get-PageProbe -Path '/privacy.php' -UserAgent $ua
    $failed += Assert-BodyContains -Label 'privacy' -Body $privacy.Body -Pattern 'href="/styles\.css\?v=' -OkMessage 'privacy stylesheet /styles.css'
    $failed += Assert-BodyContains -Label 'privacy' -Body $privacy.Body -Pattern 'href="/terms"' -OkMessage 'privacy link /terms'
    $failed += Assert-BodyContains -Label 'privacy' -Body $privacy.Body -Pattern 'href="/refbook\.sk\.php"' -OkMessage 'privacy link /refbook.sk.php'

    $terms = Get-PageProbe -Path '/terms.php' -UserAgent $ua
    $failed += Assert-BodyContains -Label 'terms' -Body $terms.Body -Pattern 'href="/styles\.css\?v=' -OkMessage 'terms stylesheet /styles.css'
    $failed += Assert-BodyContains -Label 'terms' -Body $terms.Body -Pattern 'href="/privacy"' -OkMessage 'terms link /privacy'
} catch {
    Write-Host "FAIL legal GET probe — $($_.Exception.Message)" -ForegroundColor Red
    $failed++
}

Write-Host ""
Write-Host "Refbook GET: dynamic title/description + stylesheet" -ForegroundColor Cyan
$genericTitle = 'Kniha, z ktorej je citát \(sk\.polascin\.net\)'
try {
    $refOk = Get-PageProbe -Path '/refbook.sk.php?data=1' -UserAgent $ua
    if ($refOk.Body -match $genericTitle) {
        Write-Host "FAIL refbook data=1 still has generic <title>" -ForegroundColor Red
        $failed++
    } else {
        Write-Host "OK refbook data=1 dynamic <title> (not generic)" -ForegroundColor Green
    }
    # data=1 is a stable fixture (Isaac Bashevis Singer); assert author + non-empty snippet in <title>
    $failed += Assert-BodyContains -Label 'refbook' -Body $refOk.Body -Pattern '<title>Isaac Bashevis Singer:\s+[^<]{10,}</title>' -OkMessage 'refbook data=1 title has author + snippet'
    $failed += Assert-BodyContains -Label 'refbook' -Body $refOk.Body -Pattern 'name="description" content="Citát od autora Isaac Bashevis Singer' -OkMessage 'refbook data=1 description names author'
    $failed += Assert-BodyContains -Label 'refbook' -Body $refOk.Body -Pattern 'href="/styles\.css\?v=\d+"' -OkMessage 'refbook stylesheet /styles.css?v='

    $ref404 = Get-PageProbe -Path '/refbook.sk.php?data=abc' -UserAgent $ua -ExpectedStatus 404
    if ($ref404.Body -match $genericTitle) {
        Write-Host "OK refbook 404 keeps generic <title>" -ForegroundColor Green
    } else {
        Write-Host "FAIL refbook 404 missing generic <title>" -ForegroundColor Red
        $failed++
    }
} catch {
    Write-Host "FAIL refbook GET probe — $($_.Exception.Message)" -ForegroundColor Red
    $failed++
}

if ($failed -gt 0) {
    Write-Host ""
    Write-Host "Smoke zlyhal: $failed kontrol(y)." -ForegroundColor Red
    exit 1
}
Write-Host ""
Write-Host "Smoke OK (403 = Apache; 509 = OpenResty edge; headers + pixbanner + legal + refbook title)." -ForegroundColor Green
exit 0
