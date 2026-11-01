"""Deploy one reviewed file using the existing websupport SSH alias.

No directory sync or deletion. Backups stay outside the public web root.
Use --expected-sha256 to reject concurrent production changes.
"""
import argparse
import hashlib
import os
from pathlib import Path
import re
import subprocess
from datetime import datetime, timezone


def run(*args):
    return subprocess.run(args, check=True, capture_output=True, text=True).stdout.strip()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source', type=Path)
    parser.add_argument('--expected-sha256', required=True)
    parser.add_argument('--apply', action='store_true')
    args = parser.parse_args()
    root = Path(__file__).resolve().parent.parent
    targets = {
        'sk.polascin.net': ('sk', 'index.php'),
        'nephrosite.polascin.net': ('nephrosite', '.htaccess'),
    }
    site, name = targets[root.name]
    source = (args.source or root / name).resolve()
    if not source.is_file() or not re.fullmatch('[a-f0-9]{64}', args.expected_sha256):
        raise ValueError('Expected a file and a lowercase SHA-256.')
    if name.endswith('.php'):
        run('php', '-l', str(source))
    else:
        run('php', str(root / 'tools/test-csp.php'))
    target = f'polascin.net/sub/{site}/{name}'
    ssh = ('ssh', '-o', 'BatchMode=yes', '-o', 'ConnectTimeout=20', 'websupport')
    old_hash = run(*ssh, f"test -f '{target}' && sha256sum '{target}'").split()[0]
    if old_hash != args.expected_sha256:
        raise RuntimeError('Production changed; inspect it before deploying.')
    new_hash = hashlib.sha256(source.read_bytes()).hexdigest()
    print(f'{root.name}: {name}, {old_hash} -> {new_hash}', flush=True)
    if not args.apply:
        print('Plan only. Add --apply to deploy.')
        return
    stamp = datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%S%fZ')
    backup_dir = f'codex-deploy-backups/{stamp}/{site}'
    backup = f'{backup_dir}/{name}'
    temporary = f'{target}.deploy-{stamp}'
    run(*ssh, f"umask 077; mkdir -p '{backup_dir}' && cp -p '{target}' '{backup}'")
    run('scp', '-o', 'BatchMode=yes', '-o', 'ConnectTimeout=20', str(source), f'websupport:{temporary}')
    # Recheck the original immediately before the atomic replacement.
    run(*ssh, f"test \"$(sha256sum '{target}' | cut -d ' ' -f 1)\" = '{old_hash}' && "
        f"test \"$(sha256sum '{temporary}' | cut -d ' ' -f 1)\" = '{new_hash}' && "
        f"chmod --reference='{target}' '{temporary}' && mv '{temporary}' '{target}'")
    try:
        status = run('curl.exe' if os.name == 'nt' else 'curl', '--silent', '--show-error',
                     '--location', '--max-time', '30', '--output', os.devnull,
                     '--user-agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
                     'AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36',
                     '--write-out', '%{http_code}', f'https://{root.name}/')
        if status != '200':
            raise RuntimeError(f'Homepage smoke test failed: HTTP {status}.')
        actual = run(*ssh, f"sha256sum '{target}'").split()[0]
        if actual != new_hash:
            raise RuntimeError('Post-deployment SHA-256 mismatch.')
    except Exception:
        run(*ssh, f"cp -p '{backup}' '{target}'")
        raise
    print(f'PASS: HTTP 200, SHA-256 verified; backup: {backup}')


if __name__ == '__main__':
    main()
