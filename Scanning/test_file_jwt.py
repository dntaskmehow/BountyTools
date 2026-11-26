import warnings
from curl_cffi import requests

warnings.filterwarnings("ignore")

def test_file():
    print("[*] Initializing File-Based Clean JWT Loader...")
    
    with open("jwt.txt", "r", encoding="utf-8") as f:
        jwt_token = f.read().strip()
        
    print(f"[+] Loaded JWT (Length: {len(jwt_token)})")
    
    netscape_cookies = {
        "bitso_cc": "1",
        "_hjSessionUser_2335223": "eyJpZCI6ImU2MzFlMWVlLWVjNjktNTQ2YS1iM2QyLWVhNDYzN2YwNjdjMCIsImNyZWF0ZWQiOjE3OTM0NzYzMTgyMjAsImV4aXN0aW5nIjp0cnVlfQ==",
        "_ga": "GA1.1.575290914.1793463390",
        "d_id": "1adf556bc330374a",
        "ISTIO_AUTH_SESSION_ID": "082e749710ab5df7",
        "csrf": "oO5i5JNdGnLNsjbx",
        "htjs_user_id": "11920930",
        "NEXT_LOCALE": "us",
        "random_cookie": "082e749710ab5df7"
    }
    
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:159.0) Gecko/20100101 Firefox/159.0",
        "Accept": "application/json, text/plain, */*",
        "Authorization": f"Bearer {jwt_token}",
        "bts-client-platform": "web",
        "bts-client-name": "bitbank-wallet-web",
        "bts-client-version": "04daf0281635372a64e00b2f60cbd9b284717755",
        "X-Bug-Bounty": "Bugcrowd-proresearcher",
        "Referer": "https://yourtarget.com/r/user/overview"
    }
    
    url = "https://yourtarget.com/api/v4/fees/trade"
    print(f"\n[+] Probing Authenticated Endpoint -> {url}")
    try:
        res = requests.get(url, cookies=netscape_cookies, headers=headers, impersonate="chrome120", verify=False, timeout=10)
        print(f"    -> Status: {res.status_code} | Length: {len(res.text)}")
        print(f"    -> Response: {res.text[:400]}")
    except Exception as e:
        print(f"    -> Error: {e}")

if __name__ == "__main__":
    test_file()
