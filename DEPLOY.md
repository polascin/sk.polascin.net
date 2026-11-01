# Deploy – sk.polascin.net

## Cielené lokálne nasadenie od 1. 11. 2026

Pre samostatnú opravu `index.php` slúži `python tools/deploy-file.py
--expected-sha256 HASH`. Bez `--apply` iba overí PHP syntax a porovná
produkčný hash. S `--apply` vytvorí zálohu mimo web rootu v
`codex-deploy-backups/CAS/sk/`, prenesie súbor cez SSH alias `websupport`,
overí hash a atómovo ho premenuje. Následne overí HTTP 200 a SHA-256.
Pri zlyhaní následnej kontroly obnoví pôvodný súbor. Výsledok a cestu zálohy
vypíše do konzoly. Spúšťanie je ručné pri schválenom nasadení.

GitHub workflow pri pushi do main alebo workflow_dispatch validuje PHP
a cez FTPS prenáša checkout s DEPLOY_FTP_* secrets bez mazania. Spotrebiteľom
je verejný web. Nový miestny nástroj vykonáva cielený prenos jedného súboru
cez SSH s kontrolou integrity a zálohou. Nenahrádza synchronizáciu všetkých
súborov ani všetky CI kontroly. Workflow zostáva zachovaný, pri lokálnej práci
sa nasadzuje miestnymi nástrojmi. Commit lokálne nasadenej opravy môže použiť
existujúcu značku `[skip deploy]`, aby push nespustil druhé nasadenie cez FTPS.
Vzdialený repozitár a záznam review zostávajú na GitHube.

Automatické nasadenie cez **GitHub Actions** (`.github/workflows/deploy.yml`):
po každom pushi do `main` (alebo manuálne cez **Actions → Deploy → Run
workflow**) sa najprv overí PHP (`php -l`) a potom sa obsah nahrá na WebSupport
cez **FTPS** (`lftp`). Push s `[skip deploy]` v commit message deploy preskočí.
Kým nie sú nastavené `DEPLOY_FTP_*` secrets, deploy job sa iba preskočí.

## Poznámka k prístupu z runnerov (GEO ochrana)

Pôvodne deploy z GitHub-hostovaných runnerov zlyhával — SSH `Permission denied
(publickey)` aj FTP pasívny dátový kanál `max-retries` — hoci z lokálneho stroja
všetko fungovalo. Príčinou bola **GEO ochrana WebSupportu**, ktorá blokovala IP
adresy GitHub runnerov. Po jej úprave deploy z runnera funguje.

## GitHub Secrets (Settings → Secrets and variables → Actions)

| Secret                | Popis                                                        |
| --------------------- | ------------------------------------------------------------ |
| `DEPLOY_FTP_SERVER`   | FTP host/IP (`37.9.175.131`)                                  |
| `DEPLOY_FTP_PORT`     | FTP port (`21`)                                              |
| `DEPLOY_FTP_USERNAME` | FTP používateľské meno (`editor.polascin.net`)               |
| `DEPLOY_FTP_PASSWORD` | FTP heslo                                                    |
| `DEPLOY_FTP_DIR`      | Cieľový adresár relatívne k FTP domovu (`polascin.net/sub/sk/`) |

FTPS detaily: riadiaci kanál je šifrovaný (AUTH TLS → heslo chránené), dátový
kanál je bez TLS (PROT C — obchádza chybu OpenSSL 3 v lftp pri reuse TLS relácie
na dátovom kanáli; nahrávané súbory sú verejné). Server sa adresuje cez pripnutú
IPv4, preto je overenie certifikátu vypnuté (`ftp.websupport.sk` je NXDOMAIN,
shell hostname mal na runneroch DNS výpadky). Nahráva sa bez mazania, takže
serverové súbory mimo repozitára (napr. `db.config.php`) zostávajú nedotknuté.

## Lokálny (núdzový) deploy

Ak by Actions deploy zlyhal, funguje FTPS aj z lokálneho stroja:

```bash
set -a; . tools/deploy.local.env; set +a   # neverziovaný súbor s FTP údajmi
python tools/ftp_deploy.py
```

`tools/ftp_deploy.py` (Python `ftplib.FTP_TLS`) overí cieľ (`index.php`) a nahrá
bez mazania. Voliteľne existuje aj vypnutý pre-push hook
`.git/hooks/pre-push.disabled`, ktorý toto spúšťal automaticky lokálne —
pre návrat k lokálnemu deployu ho stačí premenovať späť na `pre-push`.

Alternatíva cez SSH: SFTP kľúčom `~/.ssh/sk_deploy` na
`uid58858@37.9.175.131:26650`, cieľ `/data/8/6/868f981d-…/polascin.net/sub/sk`.
