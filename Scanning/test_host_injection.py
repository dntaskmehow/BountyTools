import requests

url = "https://yourtarget.com/api/v1/fee-price?chain=ethereum&network=mainnet"
hosts = ["evil.com", "localhost", "internal.service"]

for h in hosts:
    headers = {"Host": h}
    try:
        r = requests.get(url, headers=headers, timeout=4, allow_redirects=False)
        print(f"Host {h} -> Status: {r.status_code} | Location: {r.headers.get('Location', 'None')}")
    except Exception as e:
        print(f"Host {h} error: {e}")
