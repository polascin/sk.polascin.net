# Deploy – sk.polascin.net

Automatické nasadenie cez GitHub Actions (`.github/workflows/deploy.yml`):
po každom pushi do `main` (alebo manuálne cez **Actions → Deploy → Run
workflow**) sa repozitár zosynchronizuje rsyncom do web rootu na WebSupport.
Súbory vylúčené v `.deployignore` sa nenasadzujú; `--delete` sa nepoužíva,
takže serverové súbory mimo repozitára zostávajú nedotknuté. Push s
`[skip deploy]` v commit message deploy preskočí.

Kým secrets nie sú nastavené, deploy job sa iba preskočí s upozornením
(workflow nezlyhá).

## GitHub Secrets (Settings → Secrets and variables → Actions)

| Secret               | Popis                                                                |
| -------------------- | -------------------------------------------------------------------- |
| `DEPLOY_HOST`        | SSH host, napr. `shell.r1.websupport.sk`                              |
| `DEPLOY_USER`        | SSH používateľ, napr. `uid58858`                                      |
| `DEPLOY_PORT`        | SSH port (WebSupport shell používa `26650`; predvolené `22`)          |
| `DEPLOY_SSH_KEY`     | Celý obsah privátneho SSH kľúča                                       |
| `DEPLOY_KNOWN_HOSTS` | Host key servera (`ssh-keyscan -p <port> <host>`), formát `[host]:port` |
| `DEPLOY_REMOTE_PATH` | Absolútna cesta k web rootu subdomény (pravdepodobne `…/polascin.net/sub/sk` — overte vo WebSupport paneli) |

Workflow pred rsyncom overí, že vzdialený adresár existuje — pri zlej ceste
bezpečne zlyhá bez zápisu.
