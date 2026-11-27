#!/usr/bin/env python3
"""Triage master/inspect.txt-style URL lists → critical buckets + shell commands."""
from __future__ import annotations

import argparse
import re
from collections import Counter
from pathlib import Path
from urllib.parse import urlparse

PATTERNS: list[tuple[str, str, re.Pattern[str]]] = [
    ("critical_api", "api/versioned", re.compile(r"/api/|/v[0-9]+/", re.I)),
    ("critical_graphql", "graphql", re.compile(r"graphql", re.I)),
    ("critical_auth", "login/oauth/session", re.compile(r"login|oauth|auth|token|session|signin|signup", re.I)),
    ("critical_webhook", "webhook/callback", re.compile(r"webhook|callback", re.I)),
    ("critical_admin", "admin", re.compile(r"admin", re.I)),
    ("critical_config", "config/env/swagger", re.compile(r"\.env|swagger|openapi|config\.|/\.git", re.I)),
    ("critical_debug", "debug/health/metrics", re.compile(r"debug|trace|metrics|health|status\.json", re.I)),
    ("critical_upload", "upload/import", re.compile(r"upload|import|export", re.I)),
    ("critical_fintech", "payments/wallet", re.compile(r"withdraw|transfer|wallet|payment|trade|ticker|transaction", re.I)),
    ("critical_params", "querystring", re.compile(r"\?[^#]+=")),
    ("critical_encoding", "path encoding anomalies", re.compile(r"%5[Cc]|\\u003|%00|%2e%2e", re.I)),
    ("critical_cloudflare", "cdn-cgi/challenge", re.compile(r"cdn-cgi/challenge|cf\.errors", re.I)),
]

OUT_DEFAULT = Path(__file__).resolve().parents[1] / "docs" / "generated"


def triage(inspect_path: Path, out_dir: Path, include_third_party: bool) -> int:
    out_dir.mkdir(parents=True, exist_ok=True)
    buckets: dict[str, list[str]] = {name: [] for name, _, _ in PATTERNS}
    hosts: Counter[str] = Counter()
    skipped_external = 0

    with inspect_path.open(encoding="utf-8", errors="replace") as f:
        for line in f:
            u = line.strip()
            if not u.startswith("http"):
                continue
            host = urlparse(u).netloc.lower()
            hosts[host] += 1
            if not include_third_party and host and any(
                x in host for x in ("linkedin.com", "youtube.com", "facebook.com", "instagram.com", "x.com", "twitter.com", "t.me", "substack", "w3.org")
            ):
                skipped_external += 1
                continue
            for name, _label, pat in PATTERNS:
                if pat.search(u) and u not in buckets[name]:
                    buckets[name].append(u)

    for name, urls in buckets.items():
        (out_dir / f"inspect_{name}.txt").write_text("\n".join(urls) + ("\n" if urls else ""), encoding="utf-8")

    cmd_lines = [
        "# Inspect triage commands — set paths on authorized assets only",
        'export INSPECT_FILE="/path/to/thetshas/master/inspect.txt"',
        'export TARGET="https://$DOMAIN"',
        'export DOMAIN="$(python3 -c \\"from urllib.parse import urlparse; import os; u=os.environ.get(\'TARGET\',\'\'); print(urlparse(u).netloc or \'COMP_HOST\')\\")"',
        'export OUT="$HOME/ops/$DOMAIN/inspect_triage"',
        'mkdir -p "$OUT"',
        "",
        "# Regenerate buckets with this repo:",
        f"python3 scripts/analyze_inspect_urls.py \"$INSPECT_FILE\" -o \"$OUT\"",
        "",
        "httpx -l \"$OUT/inspect_critical_api.txt\" -status-code -title -tech-detect -json -o \"$OUT/live_api.json\"",
        "httpx -l \"$OUT/inspect_critical_auth.txt\" -status-code -follow-redirects -o \"$OUT/live_auth.txt\"",
        "httpx -l \"$OUT/inspect_critical_fintech.txt\" -status-code -title -o \"$OUT/live_fintech.txt\"",
        "httpx -l \"$OUT/inspect_critical_params.txt\" -status-code -mc 200,301,302,403,500 | tee \"$OUT/live_params.txt\"",
        "",
        "nuclei -l \"$OUT/inspect_critical_api.txt\" -tags exposure,api,misconfig,token -severity medium,high,critical -o \"$OUT/nuclei_api.txt\"",
        "nuclei -l \"$OUT/inspect_critical_auth.txt\" -tags oauth,default-login,token,session -o \"$OUT/nuclei_auth.txt\"",
        "nuclei -l \"$OUT/inspect_critical_config.txt\" -tags exposure,config,backup,debug -o \"$OUT/nuclei_config.txt\"",
        "",
        "sqlmap -m \"$OUT/inspect_critical_params.txt\" --batch --smart --level=2 --risk=1 --random-agent --threads=2",
        "dalfox file \"$OUT/inspect_critical_params.txt\" --silence -o \"$OUT/dalfox_params.txt\"",
        "",
        "grep -Ei 'cdn-cgi/challenge' \"$INSPECT_FILE\" | sort -u > \"$OUT/cloudflare_challenge_urls.txt\"",
        "ffuf -request \"$OUT/encoding_probe.req\" -w \"$OUT/inspect_critical_encoding.txt\" 2>/dev/null || ffuf -u \"$TARGET/FUZZ\" -w \"$OUT/inspect_critical_encoding.txt\" -mc 200,301,302,403,500",
        "",
        "cat \"$OUT\"/inspect_critical_*.txt | sort -u > \"$OUT/all_critical_merged.txt\"",
        "httpx -l \"$OUT/all_critical_merged.txt\" -status-code -title -tech-detect | tee \"$OUT/all_critical_live.txt\"",
        "",
        "# Evidence extraction (minimal)",
        "jq -r '.url' \"$OUT/live_api.json\" 2>/dev/null | while read -r u; do curl -sS -m 15 \"$u\" -o \"$OUT/loot/$(echo \"$u\" | md5sum | cut -c1-16).body\"; done",
        'grep -RinE "api_key|secret|token|password" "$OUT/loot" 2>/dev/null | tee "$OUT/loot/grep_hits.txt"',
    ]

    summary = [
        f"# inspect source: {inspect_path}",
        f"# skipped third-party hosts lines: {skipped_external}",
        "# top hosts:",
    ]
    for h, c in hosts.most_common(20):
        summary.append(f"#   {h}: {c}")
    summary.append("# bucket counts:")
    for name, _, _ in PATTERNS:
        summary.append(f"#   {name}: {len(buckets[name])}")

    (out_dir / "inspect_summary.txt").write_text("\n".join(summary) + "\n", encoding="utf-8")
    (out_dir / "inspect_critical_commands.sh").write_text("\n".join(cmd_lines) + "\n", encoding="utf-8")
    print(f"wrote buckets + inspect_critical_commands.sh under {out_dir}")
    return sum(len(v) for v in buckets.values())


def main() -> int:
    p = argparse.ArgumentParser(description="Triage inspect.txt URL dumps")
    p.add_argument("inspect_file", type=Path)
    p.add_argument("-o", "--out-dir", type=Path, default=OUT_DEFAULT)
    p.add_argument("--include-third-party", action="store_true")
    args = p.parse_args()
    if not args.inspect_file.is_file():
        raise SystemExit(f"missing file: {args.inspect_file}")
    triage(args.inspect_file, args.out_dir, args.include_third_party)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())