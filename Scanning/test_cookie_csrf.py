import httpx
import warnings

warnings.filterwarnings("ignore")

ACTIVE_ENDPOINTS = [
    "https://api.yourtarget.com/v1/admin/organizations",
    "https://api.yourtarget.com/v1/admin/users",
    "https://api.yourtarget.com/v1/admin/invites",
    "https://api.yourtarget.com/v1/admin/service_accounts"
]

# Corrected variable name matching our dictionary list
COOKIE_MUTATIONS = [
    {"session": "mock_session_cookie_abc123"},
    {"__Secure-next-auth.session-token": "mock_token_xyz"},
    {"connect.sid": "s%3Afake_session_id.sig789"},
    {"openai_session": "sess_live_test_000"}
]

def test_cookie_auth():
    client = httpx.Client(verify=False, timeout=5.0)
    
    print("[*] Testing session cookie authentication vectors across active admin endpoints...\n")
    
    for url in ACTIVE_ENDPOINTS:
        print(f"[-] Target: {url}")
        for cookie in COOKIE_MUTATIONS:
            try:
                res = client.get(
                    url, 
                    cookies=cookie,
                    headers={
                        "User-Agent": "BugX-CookieTester/1.0",
                        "Referer": "https://yourtarget.com/"
                    }
                )
                cookie_name = list(cookie.keys())[0]
                print(f"    -> Cookie: {cookie_name:32s} | Status: {res.status_code} | Length: {len(res.text)}")
            except httpx.RequestError as e:
                print(f"    -> Error: {e}")
        print()

    client.close()

if __name__ == "__main__":
    test_cookie_auth()
