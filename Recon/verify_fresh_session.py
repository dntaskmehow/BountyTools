import json
import warnings
from curl_cffi import requests

warnings.filterwarnings("ignore")

FRESH_JWT = (
    "eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICJKbXFsOWdZOHBSdUl2UU55amY2MzZEVVo0NElCbDZ1Q0xySmhoZHdleUJ3In0."
    "eyJleHAiOjE3OTM0Nzc1OTAsImlhdCI6MTc5MzQ3NzI5MCwiYXV0aF90aW1lIjoxNzkzNDc2NDMyLCJqdGkiOiJvbnJ0cnQ6ZjgzMzU1YjktOGE3Zi0zMDlmLTMxNTUtMjNmZTRmZTE2NzlmIiwiaXNzIjoiaHR0cHM6Ly9iaXRzby5jb20vYXV0aC9yZWFsbXMvd2ViIiwiYXVkIjoiZW1iZWRkZWQtd2FsbGV0Iiwic3ViIjoiZjoxNzJhZmFmNS0zM2U3LTQwZjQtYTAxYS03NzYyNzk5NmQzZmI6MTE5MjA5MzA6MTE5MjA5MzAiLCJ0eXAiOiJCZWFyZXIiLCJhenAiOiJiaXRzby13ZWItY2xpZW50Iiwic2lkIjoiQVlhMHVQOzczTllON2VnSnRvQ2cwVWM0MXVBQ1M5Sjd2UHRDTnRCcWEzIiwicmVhbG1fYWNjZXNzIjp7InJvbGVzIjpbIm9mZmxpbmVfYWNjZXNzIiwidW1hX2F1dGhvcml6ZWQiXX0sInJlc291cmNlX2FjY2VzcyI6eyJhY2Nlc3MtYWNjb3VudCI6eyJyb2xlcyI6WyJtYW5hZ2VfYWNjb3VudCIsIm1hbmFnZV9hY2NvdW50X2hvbGRlciIsInByZWZlcnJlZF91c2VybmFtZSI6IjExOTIwOTMwOjExOTIwOTMwIiwiZW1haWwiOiJkb250YXNrbWVob3dAdWJnY3Jvd2RuaW5qYS5jb20iLCJkZnAiOiJVb1VIMERpWjRBTDJ3VTFzeFlua3kifX0sInNjb3BlIjoib3BlbmlkIGVtYWlsIHByb2ZpbGUiLCJzaWRfYWNjb3VudF9pZCI6IjExOTIwOTMwIiwicHJlZmVycmVkX3VzZXJuYW1lIjoiMTE5MjA5MzowMTE5MjA5MzAiLCJlbWFpbCI6ImRvbnRhc2ttZWhvd0BidWdjcm93ZG5pbmphLmNvbSIsImRmcCI6IlVvVUgwRGlaNEFMMndVMXN4WW5reSJ9."
    "dntkjyv7uLzSYAdFsRzrZabggmBkiRKeDC3UfdRhz56FND8geu-fwBrAsxrM0zIVbmuezxaTcgaWc-3Tw3R-dm8ZSgDANJCJC8H0v1eaTTBmonxdmywfWg0CCvXFjvsuGrSGf_hnqfDEXbufVPYGWEd0lGjcy6sx-lhqR_xX8iZvW5TdaA2eN26gAvcKfglh1HMrY9Y0Zo6D8RuNAz7Bh9wrhe3iWCNIABKOgF4k9p6WrDoLmlIFhshKmBqAUcdOV49h52NJqodXPc5lqAHvDXxZJTA4mpVyqkYysDYHDv-kp1KKh0yLfVSiYvci2QYuhGANs6GZns7lEm2BsK4xKw"
)

RAW_COOKIES = (
    "htjs_anonymous_id=5a229d37-07d0-4878-9fde-8cec6f755a26; "
    "htjs_sesh={%22id%22:1793476269363%2C%22expiresAt%22:1793479092863%2C%22timeout%22:1800000%2C%22sessionStart%22:false%2C%22autoTrack%22:true}; "
    "ISTIO_AUTH_SESSION_ID=\"082e749710ab5df7\"; "
    "cf_clearance=Cq2BPtgCJGdlfZjxtztcutfMb1GnbZaAuG6t66XAA83H-74MWARXDZ0I5V7iJdCw68bSCxMNS-KKRYLpd_Qk0Ug6P9fSQT2-kxg2WEYoFwoS_y5WGrXcpocZwtllqWaqID3eFgXEOPjLwgiIh9ga_LajFd0_0f0FsNFODvLoYo79WALNuprr8y1JKOLbX38ZvIZiLJqRRk8Vl5hfISDR3bT2nsoQpIrxM-wGq9uMqqZvKF4Q9K64BWJrgX38s0n0AtJ; "
    "_iidt=kIiDdMhcSqpE8jx6bcorDz1UHHV7Y6rUGcIMsp9Vfc2KYj/KCvSiH7ZI4Cnz/zD41VtKM3JGzSzs0HaKBmDZ6EQxK6gHlZ2iqvKU0LI=; "
    "csrf=oO5i5JNdGnLNsjbx; "
    "8149a4f8bbf3ffea5e8ddfdda13cfae1=89825aafc790f81ac769bea410f17b8e; "
    "d_id=1adf556bc330374a; "
    "htjs_user_id=11920930; "
    "_vid_t=A1w38Fc1GX5i0LvWbU/YcP8e/vUoduNJr3vFoCI9FMFcELbJ7dp4bOdPbGSW7abDdusqZ5LWqrcITatU4G6/BlcSGXkVxVa5hiHSB/U=; "
    "random_cookie=082e749710ab5df7; "
    "WZRK_S_468-4RZ-K46Z=%7B%22p%22%3A5%7D; "
    "COOKIE_REFERRER_HEADER=https://yourtarget.com/r/welcome; "
    "bitso_cc=1"
)

TARGETS = [
    "https://yourtarget.com/api/v3/cryptos",
    "https://yourtarget.com/api/v4/fees/trade",
    "https://yourtarget.com/api/v3/available_books/"
]

def verify_session():
    print("[*] Initializing Fresh Session Verification...")
    
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:159.0) Gecko/20100101 Firefox/159.0",
        "Accept": "application/json, text/plain, */*",
        "Authorization": f"Bearer {FRESH_JWT}",
        "Cookie": RAW_COOKIES,
        "bts-client-platform": "web",
        "bts-client-name": "bitbank-wallet-web",
        "bts-client-method": "conversion",
        "bts-client-version": "04daf0281635372a64e00b2f60cbd9b284717755",
        "X-Bug-Bounty": "Bugcrowd-proresearcher",
        "Referer": "https://yourtarget.com/wallet"
    }
    
    for url in TARGETS:
        print(f"\n[+] Probing Endpoint with Fresh Token -> {url}")
        try:
            res = requests.get(url, headers=headers, impersonate="chrome120", verify=False, timeout=10)
            print(f"    -> Status: {res.status_code} | Length: {len(res.text)}")
            if res.status_code == 200:
                print(f"    [***] SUCCESS:\n{res.text[:300]}")
            else:
                print(f"    -> Response: {res.text[:200].strip()}")
        except Exception as e:
            print(f"    -> Error: {e}")

if __name__ == "__main__":
    verify_session()
