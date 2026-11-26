import httpx
from bs4 import BeautifulSoup
import warnings

warnings.filterwarnings("ignore")

URL = "https://yourtarget.com/user-center/api/v1/tokens"

def dump_page():
    client = httpx.Client(verify=False, timeout=10.0, follow_redirects=True)
    print(f"[*] Fetching full content of 200 OK endpoint: {URL}\n")
    
    try:
        res = client.get(URL, headers={"User-Agent": "BugX-TokenDumper/1.0"})
        print(f"[+] Status: {res.status_code} | Length: {len(res.text)} bytes\n")
        print("--- Response Body Preview ---")
        print(res.text[:1000])
        print("-----------------------------\n")
        
        soup = BeautifulSoup(res.text, 'html.parser')
        scripts = soup.find_all('script')
        print(f"[+] Discovered {len(scripts)} embedded script tags in HTML shell.")
        for idx, s in enumerate(scripts, 1):
            src = s.get('src', 'Inline Script')
            print(f"    -> Script [{idx}]: {src}")
            
    except httpx.RequestError as e:
        print(f"[!] Error fetching target: {e}")
        
    client.close()

if __name__ == "__main__":
    dump_page()
