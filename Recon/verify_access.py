import urllib.request
from pathlib import Path

print("[*] Professor Bug: Verifying response content to rule out SPA login redirection shells...")

test_urls = [
    "https://yourtarget.com/account/user",
    "https://yourtarget.com/configuration/users",
    "https://yourtarget.com/configuration/cash-drawers"
]

for url in test_urls:
    req = urllib.request.Request(
        url,
        headers={"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) BugX-Security-Scanner"}
    )
    try:
        with urllib.request.urlopen(req, timeout=5) as resp:
            body = resp.read(1000).decode('utf-8', errors='ignore').lower()
            if "<html" in body and ("login" in body or "sign in" in body or "auth" in body):
                print(f"[[-] FALSE POSITIVE (SPA Login Shell): {url}")
            else:
                print(f"[+] POTENTIAL VULNERABILITY (Non-Login Content): {url}")
                print(f"    Snippet: {body[:150]}...\n")
    except Exception as e:
        print(f"[-] Error testing {url}: {e}")

print("\n[*] Verification complete. If responses contain login HTML, we need to test the underlying API endpoints instead of frontend routes!")
