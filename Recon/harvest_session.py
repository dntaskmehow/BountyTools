import json
from curl_cffi import requests

print("[*] Probing community authentication gateway to harvest session cookies...")
session = requests.Session()

# Hit the community login/home portal to initialize session cookies
res = session.get("https://yourtarget.com/help/s/", impersonate="chrome120", timeout=10)

print(f"[+] Status Code: {res.status_code} | Cookies received: {dict(session.cookies)}")

if "sid" in session.cookies or len(session.cookies) > 0:
    print("[🔥] SESSION COOKIES ACQUIRED!")
    for name, value in session.cookies.items():
        print(f"    [+] {name}: {value}")
else:
    print("[-] No active session cookies returned on public root.")

