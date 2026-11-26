import warnings
from curl_cffi import requests

warnings.filterwarnings("ignore")

def discover():
    print("[*] Initializing Bitso API Route Discovery...")
    
    raw_cookies = (
        "htjs_anonymous_id=5a229d37-07d0-4878-9fde-8cec6f755a26; "
        "ISTIO_AUTH_SESSION_ID=\"082e749710ab5df7\"; "
        "csrf=oO5i5JNdGnLNsjbx; "
        "d_id=1adf556bc330374a; "
        "htjs_user_id=11920930; "
        "bitso_cc=1; "
        "_hjSessionUser_2335223=eyJpZCI6ImU2MzFlMWVlLWVjNjktNTQ2YS1iM2QyLWVhNDYzN2YwNjdjMCIsImNyZWF0ZWQiOjE3OTM0NzYzMTgyMjAsImV4aXN0aW5nIjp0cnVlfQ==; "
        "_ga=GA1.1.575290914.1793463390"
    )
    
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:159.0) Gecko/20100101 Firefox/159.0",
        "Accept": "application/json, text/plain, */*",
        "Cookie": raw_cookies,
        "X-CSRF-Token": "oO5i5JNdGnLNsjbx",
        "bts-client-platform": "web",
        "bts-client-name": "bitbank-wallet-web",
        "bts-client-method": "conversion",
        "bts-client-version": "04daf0281635372a64e00b2f60cbd9b284717755",
        "X-Bug-Bounty": "Bugcrowd-proresearcher",
        "Referer": "https://yourtarget.com/wallet"
    }

    paths = [
        "/api/v3/account",
        "/api/v3/user",
        "/api/v4/user",
        "/api/v3/profile",
        "/api/v4/profile",
        "/api/v3/ledger",
        "/api/v3/orders",
        "/api/v3/user_trades"
    ]

    for path in paths:
        url = f"https://yourtarget.com"
        try:
            res = requests.get(url, headers=headers, impersonate="chrome120", verify=False, timeout=5)
            print(f"    -> Path: {path} | Status: {res.status_code} | Length: {len(res.text)}")
            if res.status_code in [200, 403]:
                print(f"       [***] VALID ROUTE FOUND:\n{res.text[:300]}")
        except Exception as e:
            print(f"    -> Path: {path} | Error: {e}")

if __name__ == "__main__":
    discover()
