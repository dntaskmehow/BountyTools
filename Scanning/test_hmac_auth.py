import hmac
import hashlib
import time
import requests

API_KEY = "client-UFZrv4LnwjsJVI8ksijDANScTChwf5Yy"
# If you have the associated API secret from your environment dump, insert it here:
API_SECRET = "YOUR_API_SECRET_HERE" 
BASE_URL = "https://yourtarget.com"

def generate_auth_header(method, request_path, body=""):
    nonce = str(int(time.time() * 1000))
    message = nonce + method.upper() + request_path + body
    signature = hmac.new(
        API_SECRET.encode('utf-8'),
        message.encode('utf-8'),
        hashlib.sha256
    ).hexdigest()
    
    return {
        "Authorization": f"Bitso {API_KEY}:{nonce}:{signature}",
        "Content-Type": "application/json",
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
    }

endpoint = "/api/v3/balance"
method = "GET"

print(f"[*] Dispatching HMAC-signed request to -> {BASE_URL}{endpoint}")
headers = generate_auth_header(method, endpoint)

try:
    res = requests.get(BASE_URL + endpoint, headers=headers, timeout=10)
    print(f"    -> Status: {res.status_code}")
    print(f"    -> Response: {res.text}")
except Exception as e:
    print(f"    -> Error: {e}")
