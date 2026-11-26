import json
import warnings
from curl_cffi import requests

warnings.filterwarnings("ignore")

def test_full_cookie():
    print("[*] Initializing Full Raw Cookie Header Replay Test...")
    
    url = "https://yourtarget.com/api/v3/settings"
    
    raw_cookie_string = (
        "_hjSessionUser_2335223=eyJpZCI6ImU2MzFlMWVlLWVjNjktNTQ2YS1iM2QyLWVhNDYzN2YwNjdjMCIsImNyZWF0ZWQiOjE3OTM0NzYzMTgyMjAsImV4aXN0aW5nIjp0cnVlfQ==;"
        "_ga=GA1.1.575290914.1793463390;"
        "d_id=1adf556bc330374a;"
        "ISTIO_AUTH_SESSION_ID=\"082e749710ab5df7\";"
        "_dd_s=logs=1&id=89aa7a43-49e1-42e1-b1cb-33882ab03fa2&created=1793476268363&expire=1793477760946;"
        "WZRK_S_468-4RZ-K46Z=%7B%22p%22%3A3%7D;"
        "amplitude_idundefinedbitso.com=eyJvcHRPdXQiOmZhbHNlLCJzZXNzaW9uSWQiOm51bGwsImxhc3RFdmVudFRpbWUiOm51bGwsImV2ZW50SWQiOjAsImlkZW50aWZ5SWQiOjAsInNlcXVlbmNlTnVtYmVyIjowfQ==;"
        "_gcl_au=1.1.793867541.1793463390;"
        "htjs_anonymous_id=5a229d37-07d0-4878-9fde-8cec6f755a26;"
        "htjs_sesh={%22id%22:1793476269363%2C%22expiresAt%22:1793478246281%2C%22timeout%22:1800000%2C%22sessionStart%22:false%2C%22autoTrack%22:true};"
        "__cf_bm=BVgO3CBh42vvzKiiw36gk5MdZifMCbe632skdU9OQ1A-1793476648.8877516-yourtarget.com-DMkhuJKeDVa2k.zkAZ8e9FYUpYVfXS13EhHrudtdsBRGZ3d3JGwppJGGP16jGvTU0x_obK6jmH6b.SxLwWc7ghA0Sjfx.Mx3RavMs6RUJ11y0d2wzXghBeKEB3d6B.yo;"
        "csrf=oO5i5JNdGnLNsjbx;"
        "_vid_t=A1w38Fc1GX5i0LvWbU/YcP8e/vUoduNJr3vFoCI9FMFcELbJ7dp4bOdPbGSW7abDdusqZ5LWqrcITatU4G6/BlcSGXkVxVa5hiHSB/U=;"
        "_iidt=kIiDdMhcSqpE8jx6bcorDz1UHHV7Y6rUGcIMsp9Vfc2KYj/KCvSiH7ZI4Cnz/zD41VtKM3JGzSzs0HaKBmDZ6EQxK6gHlZ2iqvKU0LI=;"
        "8149a4f8bbf3ffea5e8ddfdda13cfae1=89825aafc790f81ac769bea410f17b8e;"
        "__ssid=9902951e-53f9-4d8a-bd68-9b385e734fc1;"
        "_fbp=fb.1.1793463390932.688985559644737168;"
        "_ga_XK0M30WCTZ=GS2.1.s1793476273$o3$g1$t1793476282$j51$l0$h0;"
        "_hjSession_2335223=eyJpZCI6ImY1Y2U2NDFiLTQ5OTQtNGQyZi1iZGVjLTk4MTE1ZDc4YzkzNSIsImMiOjE3OTM0NzYzMTgyMjAsInMiOjAsInIiOjAsInNiIjowLCJzciI6MCwic2UiOjAsImZzIjoxLCJzcCI6MH0=;"
        "ajs_anonymous_id=781fde8c-ec6f-455a-a6ef-4a1db26432a0;"
        "amplitude_id_97f501324f9767de5d87311b949190f8bitso.com=eyJkZXZpY2VJZCI6ImU4M2E3ZmMzLWYyYWYtNDg2Ni1iZDQyLWFiNjM1MTkzYjBkMVIiLCJ1c2VySWQiOm51bGwsIm9wdE91dCI6ZmFsc2UsInNlc3Npb25JZCI6MTc5MzQ3NjI3MjQ1MywibGFzdEV2ZW50VGltZSI6MTc5MzQ3NjI4MTg5NywiZXZlbnRJZCI6NywiaWRlbnRpZnlJZCI6Mywic2VxdWVuY2VOdW1iZXIiOjEwfQ==;"
        "COOKIE_REFERRER_HEADER=https://yourtarget.com/r/welcome;"
        "htjs_user_id=11920930;"
        "NEXT_LOCALE=us;"
        "random_cookie=082e749710ab5df7"
    )
    
    headers = {
        "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/156.0.8078.4 Safari/537.36",
        "Accept": "application/json, text/plain, */*",
        "Referer": "https://yourtarget.com/wallet",
        "Cookie": raw_cookie_string,
        "bts-client-platform": "web",
        "bts-client-name": "bitbank-wallet-web",
        "bts-client-method": "conversion",
        "bts-client-version": "04daf0281635372a64e00b2f60cbd9b284717755",
        "X-Bug-Bounty": "Bugcrowd-proresearcher"
    }
    
    try:
        res = requests.get(url, headers=headers, impersonate="chrome120", verify=False, timeout=10)
        print(f"    -> Status: {res.status_code} | Length: {len(res.text)}")
        print(f"    -> Response: {res.text[:400]}")
    except Exception as e:
        print(f"    -> Error: {e}")

if __name__ == "__main__":
    test_full_cookie()
