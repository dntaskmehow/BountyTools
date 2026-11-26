import urllib.request
import urllib.error
from pathlib import Path

api_file = Path("04_evidence/katana/high_value_apis.txt")
if not api_file.exists():
    print("[-] high_value_apis.txt not found!")
    exit(1)

print("[*] Professor Bug: Initializing automated vulnerability audit on high-value endpoints...")

endpoints = [line.strip() for line in api_file.read_text().splitlines() if line.strip().startswith("http")]

vulnerable_candidates = []

for url in endpoints:
    if "yourtarget.com" not in url:
        continue
        
    req = urllib.request.Request(
        url,
        headers={"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) BugX-Security-Scanner"}
    )
    try:
        with urllib.request.urlopen(req, timeout=5) as resp:
            body_sample = resp.read(300).decode('utf-8', errors='ignore')
            print(f"[!] OPEN ACCESS [{resp.status}] -> {url}")
            vulnerable_candidates.append((url, resp.status, body_sample))
    except urllib.error.HTTPError as e:
        pass
    except Exception:
        pass

print(f"\n[+] Audit complete. Found {len(vulnerable_candidates)} potentially exposed endpoints.")
