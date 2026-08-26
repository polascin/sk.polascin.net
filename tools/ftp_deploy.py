#!/usr/bin/env python3
"""FTPS nasadenie pre sk.polascin.net (GitHub Actions).

Používa štandardnú knižnicu `ftplib.FTP_TLS` — na rozdiel od `lftp` na runneri
korektne zvláda opätovné použitie TLS relácie na dátovom kanáli (pure-ftpd to
vyžaduje). Prihlasovacie údaje a cieľ prichádzajú cez premenné prostredia.

Env:
  FTP_SERVER, FTP_PORT (default 21), FTP_USER, FTP_PASS, FTP_DIR

Nahráva pracovný adresár (checkout) do FTP_DIR bez mazania (serverové súbory
mimo repozitára, napr. db.config.php, zostávajú). Certifikát sa neoveruje
(server adresujeme cez pripnutú IP). Pred nahraním overí, že FTP_DIR obsahuje
index.php (t.j. je to web root subdomény).
"""
import ftplib
import fnmatch
import os
import ssl
import sys

server = os.environ["FTP_SERVER"]
port = int(os.environ.get("FTP_PORT") or "21")
user = os.environ["FTP_USER"]
password = os.environ["FTP_PASS"]
remote_root = os.environ["FTP_DIR"].strip("/")

EXCLUDE_DIRS = {".git", ".github", ".githooks", ".vscode", ".claude", ".trunk", "tools"}
EXCLUDE_GLOBS = [
    "*.md", "*.ps1", "phpstan*", ".php-cs-fixer*", "db.config.php",
    ".gitignore", ".gitattributes", ".deployignore",
]


def excluded(name):
    return any(fnmatch.fnmatch(name, pat) for pat in EXCLUDE_GLOBS)


def main():
    ctx = ssl._create_unverified_context()
    ftp = ftplib.FTP_TLS(context=ctx)
    ftp.connect(server, port, timeout=30)
    ftp.auth()
    ftp.login(user, password)
    ftp.prot_p()
    print("login OK; pwd:", ftp.pwd())

    # Overenie cieľového adresára (web root musí obsahovať index.php).
    try:
        names = ftp.nlst(remote_root)
    except ftplib.all_errors as exc:
        print(f"::error::Nedá sa vypísať FTP_DIR '{remote_root}': {exc}")
        return 1
    if not any(os.path.basename(n.rstrip("/")) == "index.php" for n in names):
        print(f"::error::index.php sa nenašiel v FTP_DIR='{remote_root}' — zlý cieľový adresár.")
        return 1
    print(f"target OK: index.php je v {remote_root}")

    made = set()

    def ensure_dir(rel):
        cur = remote_root
        for part in rel.split("/"):
            if not part:
                continue
            cur = f"{cur}/{part}"
            if cur in made:
                continue
            try:
                ftp.mkd(cur)
            except ftplib.error_perm:
                pass  # existuje
            made.add(cur)

    count = 0
    for root, dirs, files in os.walk("."):
        dirs[:] = sorted(d for d in dirs if d not in EXCLUDE_DIRS and not excluded(d))
        rel = os.path.relpath(root, ".").replace("\\", "/")
        rel = "" if rel == "." else rel
        if rel:
            ensure_dir(rel)
        for name in sorted(files):
            if excluded(name):
                continue
            local_path = os.path.join(root, name)
            remote_path = f"{remote_root}/{rel + '/' if rel else ''}{name}"
            with open(local_path, "rb") as handle:
                ftp.storbinary(f"STOR {remote_path}", handle)
            count += 1
            print("put", remote_path)

    ftp.quit()
    print(f"OK — nahraných {count} súborov do {remote_root}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
