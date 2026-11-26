import json
import warnings
from curl_cffi import requests

warnings.filterwarnings("ignore")

AXIS_COOKIES = [
    {
        "name": "_vis_opt_test_cookie",
        "value": "1",
        "domain": ".yourtarget.com",
        "path": "/"
    },
    {
        "name": "axis_auth",
        "value": "u%3D20623038%2Ct%3D1793466696004%2Cc%3Dstd%2Chsh%3DlEPTHrGm4rCgwUe9AOT8gPM2KxkWb4R53wypSie2BWZ%2B6BybQU6%2Fp%2F3YZD%2ByT2GHI2Ndogw1RgGX6i7cXop0TA%3D%3D",
        "domain": ".yourtarget.com",
        "path": "/"
    },
    {
        "name": "axis_connect_session_sid",
        "value": "acc_cookie_476db895-ddb3-405e-a808-463a7feda257",
        "domain": ".yourtarget.com",
        "path": "/"
    },
    {
        "name": "lastPage",
        "value": "yourtarget.com/en-us",
        "domain": ".yourtarget.com",
        "path": "/"
    }
]

def follow_oauth_redirect():
    print("[*] Following Avi Vantage OAuth Redirect Chain...")
    
    cookie_jar = {c['name']: c['value'] for c in AXIS_COOKIES}
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        "Referer": "https://yourtarget.com/"
    }
    
    oauth_url = (
        "https://yourtarget.com/oauth/v2/authorize?"
        "client_id=service_platform_prod&"
        "redirect_uri=https%3A%2F%yourtarget.com%2Foauth2%2Fidpresponse&"
        "scope=openid+email+profile&"
        "response_type=code"
    )
    
    print(f"[+] Requesting with allow_redirects=True -> {oauth_url}")
    try:
        res = requests.get(oauth_url, headers=headers, cookies=cookie_jar, impersonate="chrome120", verify=False, timeout=10.0, allow_redirects=True)
        print(f"    -> Final Status: {res.status_code} | Length: {len(res.text)}")
        print(f"    -> Final URL: {res.url}")
        print(f"    -> Content-Type: {res.headers.get('Content-Type', 'Unknown')}")
        print(f"    -> Response Preview:\n{res.text[:800]}\n")
    except Exception as e:
        print(f"[!] Redirect Following Error: {e}")

if __name__ == "__main__":
    follow_oauth_redirect()
