import requests

url = "https://yourtarget.com/hc/en-us/requests/new"
params = {"ticket_form_id": "126080567"}

# Full browser mimicry headers including Sec-Ch-Ua client hints
headers = {
    "Host": "yourtarget.com",
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8",
    "Accept-Language": "en-US,en;q=0.9",
    "Accept-Encoding": "gzip, deflate, br",
    "Sec-Ch-Ua": '"Chromium";v="122", "Not(A:Brand";v="24", "Google Chrome";v="122"',
    "Sec-Ch-Ua-Mobile": "?0",
    "Sec-Ch-Ua-Platform": '"Windows"',
    "Sec-Fetch-Dest": "document",
    "Sec-Fetch-Mode": "navigate",
    "Sec-Fetch-Site": "none",
    "Sec-Fetch-User": "?1",
    "Upgrade-Insecure-Requests": "1",
    "Referer": "https://yourtarget.com/",
}

# Use a Session to handle any potential cookies automatically across redirects
session = requests.Session()

try:
    res = session.get(url, params=params, headers=headers, timeout=10, allow_redirects=True)
    print(f"[+] Final URL: {res.url}")
    print(f"[+] Status Code: {res.status_code}")
    
    if res.status_code == 200:
        print("[+] Success! WAF bypassed.")
        if "126080567" in res.text:
            print("[+] Form ID '126080567' verified in response DOM.")
        else:
            print("[-] Response loaded, but form ID was sanitized or stripped.")
    elif res.status_code == 403:
        print("[-] Edge security (Cloudflare/DataDome) blocked the request. TLS/JA3 fingerprinting detected.")
    else:
        print(f"[-] Received unexpected status: {res.status_code}")
        
except Exception as e:
    print(f"[-] Request error: {e}")
