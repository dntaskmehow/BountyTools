import re
import httpx
import warnings

warnings.filterwarnings("ignore")

TARGET_URL = "https://yourtarget.com/api/reference/overview"

def harvest_endpoints():
    print(f"[*] Fetching documentation overview from {TARGET_URL}...")
    try:
        res = httpx.get(TARGET_URL, verify=False, timeout=15.0)
        if res.status_code == 200:
            print(f"[+] Successfully fetched {len(res.text)} bytes of documentation.")
            
            # Regex to find API path patterns like /v1/... or /v1/dashboard/...
            paths = set(re.findall(r'\/v1\/[a-zA-Z0-9_\-\/]+', res.text))
            
            print(f"\n[+] Discovered {len(paths)} unique API path patterns:")
            for path in sorted(paths):
                print(f"    -> {path}")
                
            # Save harvested endpoints to file for BugX reconnaissance tracking
            with open("harvested_endpoints.txt", "w") as f:
                for path in sorted(paths):
                    f.write(path + "\n")
            print(f"\n[+] Saved harvested paths to ~/BugX/harvested_endpoints.txt")
        else:
            print(f"[!] Failed to fetch: Status {res.status_code}")
    except httpx.RequestError as e:
        print(f"[!] Request error: {e}")

if __name__ == "__main__":
    harvest_endpoints()
