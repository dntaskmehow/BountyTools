import re
from curl_cffi import requests

session = requests.Session()
target = "https://yourtarget.com/help/s/"

print(f"[*] Probing Salesforce Experience Cloud endpoint: {target}")
res = session.get(target, impersonate="chrome120", timeout=15)

print(f"[+] Status Code: {res.status_code}")
print(f"[+] Final URL: {res.url}")

# Look for Salesforce framework version or debug mode flags in the DOM
debug_match = re.search(r'"mode"\s*:\s*"([^"]+)"', res.text)
if debug_match:
    print(f"[+] Aura Framework Mode Detected: {debug_match.group(1)}")

fwuid_match = re.search(r'"fwuid"\s*:\s*"([^"]+)"', res.text)
if fwuid_match:
    print(f"[+] Framework UID (fwuid): {fwuid_match.group(1)[:30]}...")

# Test for Open Redirect via startURL parameter
redirect_test = "https://yourtarget.com/help/s/login/?startURL=https%3A%2F%yourtarget.com"
print(f"[*] Testing startURL redirect handling: {redirect_test}")
res_redir = session.get(redirect_test, allow_redirects=False, impersonate="chrome120", timeout=15)
print(f"[+] Redirect Response Status: {res_redir.status_code}")
print(f"[+] Location Header: {res_redir.headers.get('Location', 'None')}")
