import json
import warnings
from curl_cffi import requests

warnings.filterwarnings("ignore")

CORE_TARGETS = [
    "https://yourtarget.com/api/v3/cryptos",
    "https://yourtarget.com/api/v3/ticker/",
    "https://yourtarget.com/api/v3/available_books/",
    "https://yourtarget.com/api/v2/status.json",
    "https://yourtarget.com/alpha/register"
]

def fuzz_core():
    print("[*] Initializing Core Domain API Pivot & Fuzzing...")
    
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
        "Accept": "application/json, text/plain, */*",
        "Referer": "https://yourtarget.com/"
    }
    
    for url in CORE_TARGETS:
        print(f"\n[+] Probing Core Endpoint -> {url}")
        try:
            res = requests.get(url, headers=headers, impersonate="chrome120", verify=False, timeout=10.0)
            print(f"    -> Status: {res.status_code} | Length: {len(res.text)}")
            print(f"    -> Content-Type: {res.headers.get('Content-Type', 'Unknown')}")
            if res.status_code == 200:
                print(f"    [***] JACKPOT! LIVE CORE API RESPONSE:\n{res.text[:600]}")
            else:
                print(f"    -> Preview: {res.text[:150].strip()}")
        except Exception as e:
            print(f"    -> Error: {e}")

if __name__ == "__main__":
    fuzz_core()
