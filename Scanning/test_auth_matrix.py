import httpx
import json
import warnings

warnings.filterwarnings("ignore")

# Test credentials and sample tenant IDs
CREDENTIALS = {
    "Account_A": "Bearer test_token_org_alpha_xyz",
    "Account_B": "Bearer test_token_org_beta_123"
}

# Parameterized administrative endpoint templates
ENDPOINT_TEMPLATES = [
    "/v1/organizations/{org_id}/projects/{project_id}/service_accounts",
    "/v1/organizations/{org_id}/projects/{project_id}/spend_limit",
    "/v1/organizations/{org_id}/projects/{project_id}/rate_limits",
    "/v1/organizations/{org_id}/projects/{project_id}/api_keys"
]

# Sample placeholder IDs for fuzzing
SAMPLE_ORG_ID = "org-TestOrgAlpha123"
SAMPLE_PROJ_ID = "proj_TestProject456"

BASE_HOST = "api.yourtarget.com"

print(f"[*] Initializing Parameterized Authorization Fuzzer...")

def run_parameterized_matrix():
    client = httpx.Client(verify=False, timeout=5.0)
    
    for template in ENDPOINT_TEMPLATES:
        endpoint = template.format(org_id=SAMPLE_ORG_ID, project_id=SAMPLE_PROJ_ID)
        url = f"{BASE_HOST}{endpoint}"
        print(f"\n[+] Testing Endpoint: {endpoint}")
        
        for account_name, token in CREDENTIALS.items():
            headers = {
                "Authorization": token,
                "OpenAI-Organization": SAMPLE_ORG_ID,
                "Content-Type": "application/json",
                "User-Agent": "BugX-SecurityAuditor/1.0"
            }
            try:
                res_get = client.get(url, headers=headers)
                print(f"    -> [{account_name}] GET Status: {res_get.status_code}")
                
                if res_get.status_code != 404:
                    print(f"        [!] NON-404 RESPONSE ({res_get.status_code}) - Endpoint active or checking permissions!")
                    
            except httpx.RequestError as e:
                print(f"    -> [{account_name}] Request Error: {e}")

    client.close()
    print("\n[+] Parameterized fuzzing complete.")

if __name__ == "__main__":
    run_parameterized_matrix()
