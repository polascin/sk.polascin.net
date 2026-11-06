# Detached 15-minute portal-dev wake loop for local Cursor agents.
# Writes AGENT_LOOP_TICK_portal-dev lines for a watcher with notify_on_output.
# Honors .codex/LOOP_PAUSED: if that file exists, exits immediately (user pause).
$ErrorActionPreference = 'Continue'
$root = 'D:\Dev\sk.polascin.net'
$pauseFlag = Join-Path $root '.codex\LOOP_PAUSED'
$log = 'C:\Users\polas\.cursor\projects\d-Dev-sk-polascin-net\terminals\portal-dev-loop-detached.log'
$purpose = 'portal-dev'
$prompt = 'Pokracuj vo vyvoji a postupnom vylepsovani aplikacie portalov sk.polascin.net a polascin.sk. Vyhladaj chyby a oprav ich uplne. Optimalizuj. Po skonceni slucky uloz session-handoff a handoff. Spolupracuj s Grok botmi. Koreň: D:\Dev\sk.polascin.net. Raz denne .doaudit.md. Pred startom skontroluj .codex/LOOP_PAUSED.'

function Write-LoopLine {
    param([string]$Line)
    $utf8 = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::AppendAllText($log, $Line + [Environment]::NewLine, $utf8)
    Write-Output $Line
}

if (Test-Path -LiteralPath $pauseFlag) {
    Write-LoopLine ("LOOP_PAUSED exit pid=$PID reason=flag:$pauseFlag at=$(Get-Date -Format 'yyyy-MM-ddTHH:mm:ssK')")
    exit 0
}

Write-LoopLine ("LOOP_ARMED portal-dev interval=900s pid=$PID started=$(Get-Date -Format 'yyyy-MM-ddTHH:mm:ssK')")
while ($true) {
    if (Test-Path -LiteralPath $pauseFlag) {
        Write-LoopLine ("LOOP_PAUSED stop pid=$PID reason=flag:$pauseFlag at=$(Get-Date -Format 'yyyy-MM-ddTHH:mm:ssK')")
        exit 0
    }
    Start-Sleep -Seconds 900
    if (Test-Path -LiteralPath $pauseFlag) {
        Write-LoopLine ("LOOP_PAUSED stop-before-tick pid=$PID at=$(Get-Date -Format 'yyyy-MM-ddTHH:mm:ssK')")
        exit 0
    }
    $payload = (@{
            prompt          = $prompt
            purpose         = $purpose
            intervalSeconds = 900
            root            = $root
        } | ConvertTo-Json -Compress)
    Write-LoopLine ("AGENT_LOOP_TICK_portal-dev " + $payload)
}
