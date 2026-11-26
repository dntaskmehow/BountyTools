import json
import warnings
from curl_cffi import requests

warnings.filterwarnings("ignore")

JWT_TOKEN = "eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICJKbXFsOWdZOHBSdUl2UU55amY2MzZEVVo0NElCbDZ1Q0xySmhoZHdleUJ3In0.eyJleHAiOjE3OTM0NzcyMjcsImlhdCI6MTc5MzQ3NjkyNywiYXV0aF90aW1lIjoxNzkzNDc2NDMyLCJqdGkiOiJvbnJ0cnQ6NjE3ODQ5MjMtN2UzYi1mYmJiLTNhM2YtM2JmYTY1MTllNjExIiwiaXNzIjoiaHR0cHM6Ly9iaXRzby5jb20vYXV0aC9yZWFsbXMvd2ViIiwiYXVkIjoiZW1iZWRkZWQtd2FsbGV0Iiwic3ViIjoiZjoxNzJhZmFmNS0zM2U3LTQwZjQtYTAxYS03NzYyNzk5NmQzZmI6MTE5MjA5MzA6MTE5MjA5MzAiLCJ0eXAiOiJCZWFyZXIiLCJhenAiOiJiaXRzby13ZWItY2xpZW50Iiwic2lkIjoiQVlhMHUxU0F0SjZOWTdlZ0p0b0NnMFVjNDl1QUNTOUo3dlB0Q050QnFhMyIsInJlYWxtX2FjY2VzcyI6eyJyb2xlcyI6WyJvZmZsaW5lX2FjY2VzcyIsInVtYV9hdXRob3JpemVkIl19LCJyZXNvdXJjZV9hY2Nlc3MiOnsiYWNjZXNzLWFjY291bnQiOnsicm9sZXMSOjI1LCJyb2xlcyI6WyJtYW5hZ2VfYWNjb3VudCIsIm1hbmFnZV9hY2NvdW50X2hvbGRlciIsInByZWZlcnJlZF91c2VybmFtZSI6IjExOTIwOTMwOjExOTIwOTMwIiwiZW1haWwiOiJkb250YXNrbWVob3dAdWJnY3Jvd2RuaW5qYS5jb20iLCJkZnAiOiJVb1VIMERpWjRBTDJ3VTFzeFlua3kifQ.QbkE1wyhCAkng7vqcoYt8R-3fxUC7JS3ai_Pwb2ugnsk5INJAqYIVgTAJntvfXucpnmz1u9PfkTrjTHw4SZmFkMhWCzKuYp4lVA99Rv8x3C0kPJ1g3fiydyuglZ4RTWYCVAHeTKPi7VBQV2IKnrvb4vlq7w3pCH53TYHjvh1KATHIqkXoHE6_Q7PxHZUwCIvx44VyYYFzDhy5ZlIf5V6-4pCW5fZBDcMtkmdeTEhwU9dSeyHCcjp4wDdfzOkhR53cQfWjNOMoWX5ESIl1LohwdgxTsbERIaXAWwIeP6c4t2AQqdyWd0ABYqRI__i77htidAMcXQ4RPzgQjA698OXmQ"

TARGETS = [
    "https://yourtarget.com/api/v4/fees/trade",
    "https://yourtarget.com/api/v3/balance/",
    "https://yourtarget.com/api/v3/ledger/",
    "https://yourtarget.com/api/v3/user_profile/",
    "https://yourtarget.com/api/v4/user/profile"
]

def test_jwt():
    print("[*] Initializing JWT-Authenticated IDOR & BOLA Fuzzer...")
    
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:159.0) Gecko/20100101 Firefox/159.0",
        "Accept": "application/json, text/plain, */*",
        "Authorization": f"Bearer {JWT_TOKEN}",
        "bts-client-platform": "web",
        "bts-client-name": "bitbank-wallet-web",
        "bts-client-version": "04daf0281635372a64e00b2f60cbd9b284717755",
        "X-Bug-Bounty": "Bugcrowd-proresearcher",
        "Referer": "https://yourtarget.com/r/user/overview"
    }
    
    for url in TARGETS:
        print(f"\n[+] Probing Authenticated Endpoint -> {url}")
        try:
            res = requests.get(url, headers=headers, impersonate="chrome120", verify=False, timeout=10)
            print(f"    -> Status: {res.status_code} | Length: {len(res.text)}")
            if res.status_code == 200:
                print(f"    [***] JACKPOT! SUCCESS:\n{res.text[:400]}")
            else:
                print(f"    -> Response: {res.text[:200].strip()}")
        except Exception as e:
            print(f"    -> Error: {e}")

if __name__ == "__main__":
    test_jwt()
