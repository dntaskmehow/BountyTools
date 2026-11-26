from curl_cffi import requests

url = "https://yourtarget.com/hc/en-us/requests/new"
params = {"ticket_form_id": "126080567"}

# impersonate="chrome120" matches a real browser's TLS fingerprint (JA3/JA4)
try:
    res = requests.get(url, params=params, impersonate="chrome120", timeout=10)
    print(f"[+] Final URL: {res.url}")
    print(f"[+] Status Code: {res.status_code}")
    
    if res.status_code == 200:
        print("[+] Success! WAF successfully bypassed using browser TLS impersonation.")
        if "126080567" in res.text:
            print("[+] Form ID '126080567' verified in response DOM.")
        else:
            print("[-] Response loaded, but form ID was stripped.")
    else:
        print(f"[-] Blocked with status: {res.status_code}")
        print(f"[-] Response snippet: {res.text[:200]}")
        
except Exception as e:
    print(f"[-] Request error: {e}")
