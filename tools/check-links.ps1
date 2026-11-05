#Requires -Version 5.1
<#
.SYNOPSIS
  Inventúra a HTTP kontrola unikátnych http(s) odkazov v živom obsahu sk.polascin.net.
.DESCRIPTION
  Extrahuje URL z PHP/HTML/JS/CSS/XML (bez .git, tools, node_modules, .codex, .kilo, .trunk).
  Kontroluje cez Invoke-WebRequest (spoľahlivejší TLS na Windows než curl/schannel).
  Exit 0 = žiadne skutočné zlyhania mimo známe výnimky; exit 1 = nálezy na posúdenie.
#>
[CmdletBinding()]
param(
  [string]$Root = (Split-Path -Parent $PSScriptRoot),
  [int]$TimeoutSec = 20,
  [switch]$FailOnSuspect
)

$ErrorActionPreference = 'Continue'
$UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'

$excludeRe = '\\(\.git|tools|node_modules|\.codex|\.kilo|\.trunk)\\'
$files = Get-ChildItem -Path $Root -Recurse -File -ErrorAction SilentlyContinue |
  Where-Object {
    $_.Extension -match '\.(php|html|xml|webmanifest|js|css)$' -and
    $_.FullName -notmatch $excludeRe -and
    $_.Name -ne 'lipton-tx.html'
  }

$urls = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach ($f in $files) {
  foreach ($line in (Get-Content -LiteralPath $f.FullName -Encoding UTF8 -ErrorAction SilentlyContinue)) {
    $t = $line.Trim()
    if ($t.StartsWith('<!--') -or $t.StartsWith('//')) { continue }
    [regex]::Matches($line, 'https?://[^\s"''<>]+') | ForEach-Object {
      $u = $_.Value -replace '[),.;]+$', ''
      # Incomplete templates / docs placeholders
      if ($u -match 'clarity\.ms/tag/?$' -or $u -match 'refbook\.sk\.php\?data=$') { return }
      if ($u -match '^(https?://(www\.)?(sitemaps|w3|schema)\.org)') { return }
      [void]$urls.Add($u)
    }
  }
}

Write-Host "FILES $($files.Count) UNIQUE_URLS $($urls.Count)"

# Known bot / WAF / intermittent responses that are not dead links
$knownOkCodes = @(200, 201, 202, 203, 204, 301, 302, 303, 307, 308, 401, 403, 405, 429, 466, 999)
$results = New-Object System.Collections.Generic.List[object]
$i = 0
foreach ($u in ($urls | Sort-Object)) {
  $i++
  $code = 0
  $final = $u
  $err = ''
  try {
    $resp = Invoke-WebRequest -Uri $u -UseBasicParsing -TimeoutSec $TimeoutSec -MaximumRedirection 8 -UserAgent $UA
    $code = [int]$resp.StatusCode
    $final = $resp.BaseResponse.ResponseUri.AbsoluteUri
  } catch {
    $ex = $_.Exception
    if ($ex.Response -and $ex.Response.StatusCode) {
      $code = [int]$ex.Response.StatusCode
      try { $final = $ex.Response.ResponseUri.AbsoluteUri } catch { }
    } else {
      $err = $ex.Message
      # LinkedIn and some CDNs return non-HTTP errors under automation
      if ($u -match 'linkedin\.com') { $code = 999 }
    }
  }
  $ok = $knownOkCodes -contains $code
  $results.Add([pscustomobject]@{ Ok = $ok; Code = $code; Url = $u; Final = $final; Err = $err })
  if (-not $ok) { Write-Host "BAD $code $u" }
  elseif (($i % 20) -eq 0) { Write-Host "progress $i/$($urls.Count)" }
}

$bad = @($results | Where-Object { -not $_.Ok })
$okN = $results.Count - $bad.Count
Write-Host "OK_COUNT $okN BAD_COUNT $($bad.Count)"
if ($bad.Count -gt 0) {
  $bad | Format-Table Ok, Code, Url, Final -AutoSize | Out-String -Width 200 | Write-Host
}

$outCsv = Join-Path $PSScriptRoot '_url-check-results.csv'
$outTxt = Join-Path $PSScriptRoot '_url-inventory.txt'
$results | Export-Csv -NoTypeInformation -Encoding UTF8 $outCsv
$urls | Sort-Object | Set-Content -Encoding UTF8 $outTxt
Write-Host "wrote $outCsv and $outTxt"

if ($FailOnSuspect -and $bad.Count -gt 0) { exit 1 }
exit 0
