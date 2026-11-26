import re
from curl_cffi import requests

session = requests.Session()
url = "https://yourtarget.com/help/apex/CommunitiesSelfReg"

res = session.get(url, impersonate="chrome120", timeout=15)
viewstate = re.search(r'id="com\.salesforce\.visualforce\.ViewState"[^>]+value="([^"]+)"', res.text)

payload = {
    "communitiesSelfRegPage:theForm": "communitiesSelfRegPage:theForm",
    "communitiesSelfRegPage:theForm:firstName": "BugX",
    "communitiesSelfRegPage:theForm:lastName": "SecurityAuditor",
    "communitiesSelfRegPage:theForm:communityNickname": "bugx_auditor",
    "communitiesSelfRegPage:theForm:email": "audit@bugx.local",
    "communitiesSelfRegPage:theForm:password": "TestPassword123!",
    "communitiesSelfRegPage:theForm:confirmPassword": "TestPassword123!",
    "communitiesSelfRegPage:theForm:submit": "Register",
    "com.salesforce.visualforce.ViewState": viewstate.group(1) if viewstate else ""
}

headers = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
    "Content-Type": "application/x-www-form-urlencoded",
    "Referer": url
}

post_res = session.post(url, data=payload, headers=headers, impersonate="chrome120", timeout=15)

print("[*] Scanning response text for validation and error keywords...")
lines = post_res.text.split("\n")
for line in lines:
    if any(k in line.lower() for k in ["error", "invalid", "fail", "disabled", "exception", "required", "message"]):
        cleaned = re.sub(r'<[^>]+>', '', line).strip()
        if len(cleaned) > 5:
            print(f"    [🔥] Found: {cleaned}")

