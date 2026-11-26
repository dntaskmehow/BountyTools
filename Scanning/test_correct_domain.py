import requests

COOKIES = {
    "bitso_cc": "1",
    "ISTIO_AUTH_SESSION_ID": "082e749710ab5df7",
    "csrf": "oO5i5JNdGnLNsjbx",
    "htjs_user_id": "11920930",
    "NEXT_LOCALE": "us"
}

HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
    "X-CSRF-Token": "oO5i5JNdGnLNsjbx",
    "Accept": "application/json, text/plain, */*",
    "Referer": "https://yourtarget.com/"
}

# Correcting domain mapping: API endpoints live on yourtarget.com, not the S3 assets domain!
targets = [
    "https://yourtarget.com/api/v3/available_books",
    "https://yourtarget.com/api/v3/ticker",
    "https://yourtarget.com/terms_bff/v1/web/earnings_terms"
]

print("[*] Probing corrected API routes on the main Bitso gateway...")
for url in targets:
    print(f"\n[+] GET {url}")
    res = requests.get(url, headers=HEADERS, cookies=COOKIES, timeout=8)
    print(f"    -> Status: {res.status_code}")
    print(f"    -> Response: {res.text[:300]}")
