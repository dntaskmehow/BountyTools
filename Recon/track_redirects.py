import json
import httpx
import warnings

warnings.filterwarnings("ignore")

COOKIE_FILE = "harvested_cookies.json"
BASE_URL = "https://yourtarget.com"

def trace_redirects():
    print("[*] Initializing OAuth Redirect Location Tracer...")
    
    try:
        with open(COOKIE_FILE, "r", encoding="utf-8") as f:
            cookies_list = json.load(f)
    except Exception as e:
        print(f"[!] Error loading {COOKIE_FILE}: {e}")
        return
        
    cookie_jar = {c['name']: c['value'] for c in cookies_list}
    xsrf_token = cookie_jar.get("XSRF-TOKEN", "")
    
    # Disable follow_redirects=True so we can inspect the exact 302 Location header
    client = httpx.Client(verify=False, timeout=10.0, follow_redirects=False, cookies=cookie_jar)
    
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        "X-Requested-With": "XMLHttpRequest"
    }
    
    if xsrf_token:
        headers["X-XSRF-TOKEN"] = xsrf_token
        
    endpoints = ["/authorize", "/login", "/logout"]
    
    print(f"[+] Tracing 302 redirect targets across {len(endpoints)} endpoints...\n")
    
    for path in endpoints:
        url = BASE_URL + path
        try:
            res = client.get(url, headers=headers)
            print(f"    -> Endpoint: {path} | Status: {res.status_code}")
            if res.status_code in [301, 302, 303, 307, 308]:
                location = res.headers.get("Location", "No Location Header")
                print(f"        [***] REDIRECT TARGET (LOCATION): {location}\n")
            else:
                print(f"        [-] Response Body Preview: {res.text[:150]}\n")
        except httpx.RequestError as e:
            print(f"    -> Connection Error on {path}: {e}")
            
    client.close()
    print("[*] Redirect trace complete.")

if __name__ == "__main__":
    trace_redirects()
