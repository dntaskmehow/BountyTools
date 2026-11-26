import requests

url = "https://yourtarget.com/api/v3/coins"
methods = ["POST", "PUT", "DELETE", "PATCH"]

for m in methods:
    params = {"_method": m, "address": "0x0000000000000000000000000000000000000000"}
    r = requests.post(url, params=params, timeout=5)
    print(f"Method Override {m} -> Status: {r.status_code} | Len: {len(r.content)} | Body: {r.text[:100]}")
