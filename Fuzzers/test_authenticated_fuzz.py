from curl_cffi import requests

# Read cookies from harvested file
cookie_dict = {}
try:
    with open("validation_logs/cf_cookies.txt", "r") as f:
        for line in f:
            if "=" in line:
                parts = line.strip().split(";")[0].split("=", 1)
                if len(parts) == 2:
                    cookie_dict[parts[0].strip()] = parts[1].strip()
    print(f"[+] Loaded {len(cookie_dict)} cookies into fuzzer session.")
except Exception as e:
    print(f"[-] Error loading cookies: {e}")

url = "https://yourtarget.com/hc/en-us/requests/new"
params = {"ticket_form_id": "126080567"}

try:
    res = requests.get(url, params=params, cookies=cookie_dict, impersonate="chrome120", timeout=10)
    print(f"[+] Status Code: {res.status_code}")
    
    if res.status_code == 200:
        print("[+] SUCCESS! Authenticated bypass complete.")
        if "126080567" in res.text:
            print("[+] Target Form ID confirmed in response DOM.")
        else:
            print("[-] Page loaded, but form ID missing or redirected.")
    else:
        print(f"[-] Received status code: {res.status_code}")
        
except Exception as e:
    print(f"[-] Request error: {e}")
