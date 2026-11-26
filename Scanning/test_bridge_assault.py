import time
import requests

def assault_bridge():
    print("[*] Dispatching assault queries through local translation bridge (http://127.0.0.1:8888)...")
    
    paths = [
        "/api/v1/users/current",
        "/api/v2/users/current",
        "/graphql",
        "/api/v1/accounts"
    ]
    
    for path in paths:
        target = f"http://127.0.0.1:8888{path}"
        print(f"\n[+] Requesting: {target}")
        try:
            res = requests.get(target, timeout=10)
            print(f"    -> Status: {res.status_code} | Length: {len(res.text)}")
            print(f"    -> Content-Type: {res.headers.get('Content-Type', 'Unknown')}")
            print(f"    -> Response Preview:\n{res.text[:500]}\n")
        except Exception as e:
            print(f"    -> Bridge Assault Error: {e}")
            
    print("[*] Assault cycle complete.")

if __name__ == "__main__":
    assault_bridge()
