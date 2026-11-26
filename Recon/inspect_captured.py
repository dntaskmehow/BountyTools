import json
import urllib.parse

with open("captured_aura_request.json", "r") as f:
    base_req = json.load(f)

print("[*] Inspecting captured post_data structure...")
post_data = base_req["post_data"]
parsed = dict(urllib.parse.parse_qsl(post_data))

print(f"[*] Form keys present: {list(parsed.keys())}")
if "message" in parsed:
    msg_json = json.loads(parsed["message"])
    print(f"[*] Captured message actions: {json.dumps(msg_json, indent=2)}")

