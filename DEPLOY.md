# Deploy – sk.polascin.net

Automatické nasadenie cez GitHub Actions (`.github/workflows/deploy.yml`):
po každom pushi do `main` (alebo manuálne cez **Actions → Deploy → Run
workflow**) sa repozitár nahrá cez **FTPS** (`lftp mirror`) do web rootu na
WebSupport. Súbory vylúčené v kroku `mirror` (`.git`, `.github`, `tools`,
`*.md`, `*.ps1`, `db.config.php`, …) sa nenasadzujú; `--delete` sa nepoužíva,
takže serverové súbory mimo repozitára (napr. `db.config.php`) zostávajú
nedotknuté. Push s `[skip deploy]` v commit message deploy preskočí.

Kým secrets nie sú nastavené, deploy job sa iba preskočí s upozornením
(workflow nezlyhá).

## Prečo FTPS a nie SSH/rsync

WebSupport odmieta SSH kľúč zo zdrojových IP adries GitHub runnerov
(`Permission denied (publickey)`), hoci ten istý kľúč funguje lokálne. FTP beží
na inom porte (21) a toto obmedzenie nemá. Prenos je šifrovaný (vynútené FTPS);
server adresujeme cez pripnutú IPv4, preto je overenie certifikátu vypnuté
(certifikát je vystavený na hostname, nie na IP). Hostname `ftp.websupport.sk`
sa neresolvuje a shell hostname mal na runneroch občasné DNS výpadky — preto IP.

## GitHub Secrets (Settings → Secrets and variables → Actions)

| Secret                 | Popis                                                                  |
| ---------------------- | ---------------------------------------------------------------------- |
| `DEPLOY_FTP_SERVER`    | FTP host/IP (nastavené: `37.9.175.131`)                                |
| `DEPLOY_FTP_PORT`      | FTP port (predvolené `21`)                                             |
| `DEPLOY_FTP_USERNAME`  | **FTP používateľské meno** (z WebSupport panela) — *nutné doplniť*     |
| `DEPLOY_FTP_PASSWORD`  | **FTP heslo** (z WebSupport panela) — *nutné doplniť*                  |
| `DEPLOY_FTP_DIR`       | Cieľový adresár relatívne k FTP domovskému (nastavené: `polascin.net/sub/sk/`) |

FTP prihlasovacie údaje nastavíte vo WebSupport paneli (FTP účty). Secrety:

```bash
gh secret set DEPLOY_FTP_USERNAME -R polascin/sk.polascin.net   # zadá sa interaktívne
gh secret set DEPLOY_FTP_PASSWORD -R polascin/sk.polascin.net
```

Ak by FTP prihlásenie končilo v inom domovskom adresári, upravte `DEPLOY_FTP_DIR`
tak, aby ukazoval na web root subdomény (`…/polascin.net/sub/sk`).

## Lokálne (núdzové) nasadenie

Ak Actions deploy nefunguje, z lokálu funguje SFTP cez SSH kľúč
`~/.ssh/sk_deploy` na `uid58858@37.9.175.131:26650`, cieľ
`/data/8/6/868f981d-…/polascin.net/sub/sk`.
