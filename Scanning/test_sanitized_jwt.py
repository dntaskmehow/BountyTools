import json
import warnings
from curl_cffi import requests

warnings.filterwarnings("ignore")

# Sanitized JWT token (whitespace and newlines completely stripped)
RAW_JWT = (
    "eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICJKbXFsOWdZOHBSdUl2UU55amY2MzZEVVo0NElCbDZ1Q0xySmhoZHdleUJ3In0."
    "eyJleHAiOjE3OTM0NzcyMjcsImlhdCI6MTc5MzQ3NjkyNywiYXV0aF90aW1lIjoxNzkzNDc2NDMyLCJqdGkiOiJvbnJ0cnQ6NjE3ODQ5MjMtN2UzYi1mYmJiLTNhM2YtM2JmYTY1MTllNjExIiwiaXNzIjoiaHR0cHM6Ly9iaXRzby5jb20vYXV0aC9yZWFsbXMvd2ViIiwiYXVkIjoiZW1iZWRkZWQtd2FsbGV0Iiwic3ViIjoiZjoxNzJhZmFmNS0zM2U3LTQwZjQtYTAxYS03NzYyNzk5NmQzZmI6MTE5MjA5MzA6MTE5MjA5MzAiLCJ0eXAiOiJCZWFyZXIiLCJhenAiOiJiaXRzby13ZWItY2xpZW50Iiwic2lkIjoiQVlhMHUxU0F0SjZOWTdlZ0p0b0NnMFVjNDl1QUNTOUo3dlB0Q050QnFhMyIsInJlYWxtX2FjY2VzcyI6eyJyb2xlcyI6WyJvZmZsaW5lX2FjY2VzcyIsInVtYV9hdXRob3JpemVkIl19LCJyZXNvdXJjZV9hY2Nlc3MiOnsiYWNjZXNzLWFjY291bnQiOnsicm9sZXMSOjI1LCJyb2xlcyI6WyJtYW5hZ2VfYWNjb3VudCIsIm1hbmFnZV9hY2NvdW50X2hvbGRlciIsInByZWZlcnJlZF91c2VybmFtZSI6IjExOTIwOTMwOjExOTIwOTMwIiwiZW1haWwiOiJkb250YXNrbWVob3dAdWJnY3Jvd2RuaW5qYS5jb20iLCJkZnAiOiJVb1VIMERpWjRBTDJ3VTFzeFlua3kifQ."
    "QbkE1wyhCAkng7vqcoYt8R-3fxUC7JS3ai_Pwb2ugnsk5INJAqYIVgTAJntvfXucpnmz1u9PfkTrjTHw4SZmFkMhWCzKuYp4lVA99Rv8x3C0kPJ1g3fiydyuglZ4RTWYCVAHeTKPi7VBQV2IKnrvb4vlq7w3pCH53TYHjvh1KATHIqkXoHE6_Q7PxHZUwCIvx44VyYYFzDhy5ZlIf5V6-4pCW5fZBDcMtkmdeTEhwU9dSeyHCcjp4wDdfzOkhR53cQfWjNOMoWX5ESIl1LohwdgxTsbERIaXAWwIeP6c4t2AQqdyWd0ABYqRI__i77htidAMcXQ4RPzgQjA698OXmQ"
)

NETSCAPE_COOKIES = {
    "bitso_cc": "1",
    "_hjSessionUser_2335223": "eyJpZCI6ImU2MzFlMWVlLWVjNjktNTQ2YS1iM2QyLWVhNDYzN2YwNjdjMCIsImNyZWF0ZWQiOjE3OTM0NzYzMTgyMjAsImV4aXN0aW5nIjp0cnVlfQ==",
    "_ga": "GA1.1.575290914.1793463390",
    "d_id": "1adf556bc330374a",
    "ISTIO_AUTH_SESSION_ID": "082e749710ab5df7",
    "csrf": "oO5i5JNdGnLNsjbx",
    "htjs_user_id": "11920930",
    "NEXT_LOCALE": "us",
    "random_cookie": "082e749710ab5df7"
}

TARGETS = [
    "https://yourtarget.com/api/v4/fees/trade",
    "https://yourtarget.com/api/v3/balance/",
    "https://yourtarget.com/api/v3/available_books/"
]

def test_sanitized():
    print("[*] Initializing Sanitized JWT & Cookie Authenticated Fuzzer...")
    
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:159.0) Gecko/20100101 Firefox/159.0",
        "Accept": "application/json, text/plain, */*",
        "Authorization": f"Bearer {RAW_JWT}",
        "bts-client-platform": "web",
        "bts-client-name": "bitbank-wallet-web",
        "bts-client-version": "04daf0281635372a64e00b2f60cbd9b284717755",
        "X-Bug-Bounty": "Bugcrowd-proresearcher",
        "Referer": "https://yourtarget.com/r/user/overview"
    }
    
    for url in TARGETS:
        print(f"\n[+] Probing Authenticated Endpoint -> {url}")
        try:
            res = requests.get(url, cookies=NETSCAPE_COOKIES, headers=headers, impersonate="chrome120", verify=False, timeout=10)
            print(f"    -> Status: {res.status_code} | Length: {len(res.text)}")
            if res.status_code == 200:
                print(f"    [***] JACKPOT! AUTHENTICATED SUCCESS:\n{res.text[:400]}")
            else:
                print(f"    -> Response: {res.text[:200].strip()}")
        except Exception as e:
            print(f"    -> Error: {e}")

if __name__ == "__main__":
    test_sanitized()
