import json
from curl_cffi import requests

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
    "Accept": "application/json, text/javascript, */*; q=0.01",
}

target_url = "https://yourtarget.com/api/v2/ticket_fields.json"

print(f"[*] Querying global ticket fields endpoint...")
try:
    res = requests.get(target_url, cookies=cookie_dict, headers=headers, impersonate="chrome120", timeout=15)
    print(f"[+] Status Code: {res.status_code}")
    
    if res.status_code == 200:
        data = res.json()
        with open("validation_logs/all_ticket_fields.json", "w") as f:
            json.dump(data, f, indent=2)
        print("[+] Saved all ticket fields to validation_logs/all_ticket_fields.json")
        
        # Search for our target field 4552500142106
        for field in data.get("ticket_fields", []):
            if str(field.get("id")) == "4552500142106":
                print("\n[!] FOUND TARGET FIELD 4552500142106:")
                print(json.dumps(field, indent=2))
    else:
        print(f"[-] Response: {res.text[:300]}")
except Exception as e:
    print(f"[-] Request error: {e}")
