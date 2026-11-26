import json
from curl_cffi import requests
import urllib.parse

print("[*] Testing redirect parameter handling on learning.okta.com...")
session = requests.Session()

# Test payloads for open redirect validation
test_urls = [
    "https://yourtarget.com/auth/login?next=https://evil.com",
    "https://yourtarget.com/auth/login?next=//evil.com",
    "https://yourtarget.com/auth/login?next=/dashboard",
    "https://yourtarget.com/auth/login?next=%2Fpath%2Fprotect-non-human-identities"
]

for target in test_urls:
    try:
        res = session.get(target, impersonate="chrome120", allow_redirects=False, timeout=5)
        location = res.headers.get("Location", "No Location Header")
        print(f"    [+] Target: {target}")
        print(f"        -> Status: {res.status_code} | Redirect Location: {location}")
    except Exception as e:
        print(f"    [-] Error testing {target}: {e}")

print("[+] Redirect fuzzing complete.")

