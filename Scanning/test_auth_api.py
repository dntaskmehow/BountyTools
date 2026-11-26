import urllib.request
import urllib.error

target = "https://yourtarget.com/api/items/v1/business-locations/"

print("[*] Professor Bug: Probing /api/items/v1 with authorization headers...")

req = urllib.request.Request(
    target,
    headers={
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) BugX-Security-Scanner",
        "Accept": "application/json",
        "Cookie": "connect.sid=s%3Atest_cookie_placeholder.sig;"
    }
)

try:
    with urllib.request.urlopen(req, timeout=5) as resp:
        print(f"[+] SUCCESS [{resp.status}] -> {resp.read(300).decode('utf-8', errors='ignore')}")
except urllib.error.HTTPError as e:
    print(f"[-] HTTP Error {e.code}: Server responded with protection mechanism.")
    body = e.read(200).decode('utf-8', errors='ignore')
    print(f"    Details: {body}")
except Exception as ex:
    print(f"[-] Connection error: {ex}")

print("\n[*] Test complete. Swap out 'connect.sid' with your active browser session cookie to query multi-tenant locations.")
