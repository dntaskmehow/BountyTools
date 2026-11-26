import httpx
import warnings

warnings.filterwarnings("ignore")

BASE_ENDPOINTS = [
    "https://api.yourtarget.com/v1/admin/organizations",
    "https://api.yourtarget.com/v1/admin/users",
    "https://api.yourtarget.com/v1/admin/service_accounts"
]

# Action sub-path extensions and remote operations to fuzz
ACTION_MUTATIONS = [
    "",
    "/action",
    "/invoke",
    "/execute",
    "/batch",
    "/sync",
    "/export",
    "/purge",
    "/query"
]

def fuzz_remote_actions():
    client = httpx.Client(verify=False, timeout=5.0)
    
    print("[*] Fuzzing remote action sub-paths across verified admin endpoints...\n")
    
    for base in BASE_ENDPOINTS:
        print(f"[-] Base Target: {base}")
        for mutation in ACTION_MUTATIONS:
            target = base + mutation
            try:
                # Test with POST and JSON payload to trigger action handlers
                res = client.post(
                    target,
                    json={"action": "test", "id": "*"},
                    headers={
                        "Authorization": "Bearer test_token_org_alpha_xyz",
                        "User-Agent": "BugX-ActionFuzzer/1.0",
                        "Content-Type": "application/json"
                    }
                )
                print(f"    -> Mutation: {mutation:10s} | Status: {res.status_code} | Length: {len(res.text)}")
            except httpx.RequestError as e:
                print(f"    -> Mutation: {mutation:10s} | Error: {e}")
        print()

    client.close()

if __name__ == "__main__":
    fuzz_remote_actions()
