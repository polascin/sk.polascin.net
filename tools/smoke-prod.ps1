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

if ($failed -gt 0) {
    Write-Host ""
    Write-Host "Smoke zlyhal: $failed kontrol(y)." -ForegroundColor Red
    exit 1
}
Write-Host ""
Write-Host "Smoke OK (403 = Apache; 509 = OpenResty edge)." -ForegroundColor Green
exit 0
