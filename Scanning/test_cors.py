import requests

url = "https://api.yourtarget.com/v1/connection"
origins = [
    "https://evil.com",
    "https://moonpay.com.evil.com",
    "null",
    "https://api.yourtarget.com"
]

for orig in origins:
    headers = {"Origin": orig}
    r = requests.get(url, headers=headers, timeout=4)
    acao = r.headers.get("Access-Control-Allow-Origin", "None")
    acac = r.headers.get("Access-Control-Allow-Credentials", "None")
    print(f"Origin {orig} -> ACAO: {acao} | ACAC: {acac}")
