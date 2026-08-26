# Deploy – sk.polascin.net

Produkčný deploy sa robí **lokálne cez FTPS** (`python tools/ftp_deploy.py`),
spúšťaný automaticky **pre-push git hookom** pri pushi do `main`. GitHub Actions
robí na push iba **validáciu** (`php -l`).

## Prečo nie GitHub Actions deploy

WebSupport blokuje zdrojové IP adresy GitHub-hostovaných runnerov na úrovni
firewallu:

- **SSH** (port 26650): `Permission denied (publickey)` — hoci ten istý kľúč
  funguje lokálne.
- **FTP**: riadiaci kanál (port 21) prejde a prihlásenie funguje, ale **pasívny
  dátový kanál** (vysoké porty, napr. `:47653`) je z runnera nedostupný →
  `LIST/STOR max-retries exceeded`.

Z **dôveryhodnej IP** (lokálny stroj) funguje SSH aj FTPS bez problémov. Preto sa
deploy robí lokálne. Deploy job v `.github/workflows/deploy.yml` ostáva len pre
`workflow_dispatch` a je použiteľný iba zo **self-hosted runnera** na IP, ktorú
WebSupport povoľuje.

## Lokálny deploy (automatický, pre-push hook)

`.git/hooks/pre-push` pri pushi do `main` spustí `python tools/ftp_deploy.py`.
Prihlasovacie údaje číta z **neverziovaného** súboru `tools/deploy.local.env`
(v `.gitignore`):

```ini
FTP_SERVER=37.9.175.131
FTP_PORT=21
FTP_USER=editor.polascin.net
FTP_PASS=<FTP heslo>
FTP_DIR=polascin.net/sub/sk/
```

`tools/ftp_deploy.py` (Python `ftplib.FTP_TLS`):

- riadiaci kanál cez TLS (AUTH TLS → heslo chránené), certifikát sa neoveruje
  (server adresujeme cez pripnutú IP `37.9.175.131`),
- pred nahraním overí, že `FTP_DIR` je web root (obsahuje `index.php`),
- nahráva bez mazania — serverové súbory mimo repozitára (napr. `db.config.php`)
  zostávajú nedotknuté,
- vylučuje `.git`, `.github`, `tools`, `*.md`, `*.ps1`, `phpstan*`,
  `.php-cs-fixer*`, `db.config.php` a ďalšie.

**Manuálny deploy** (bez pushu):

```bash
set -a; . tools/deploy.local.env; set +a
python tools/ftp_deploy.py
```

## Overenie po deployi

```bash
curl -sI https://sk.polascin.net/            # 200 + bezpečnostné hlavičky vrátane CSP
curl -s -o /dev/null -w '%{http_code}\n' https://sk.polascin.net/privacy.php   # 200
```

## Núdzový deploy cez SSH (z lokálu)

Funguje aj SFTP cez SSH kľúč `~/.ssh/sk_deploy` na
`uid58858@37.9.175.131:26650`, cieľ
`/data/8/6/868f981d-…/polascin.net/sub/sk`.
