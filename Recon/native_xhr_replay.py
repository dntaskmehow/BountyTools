import json
from playwright.sync_api import sync_playwright

print("[*] Launching native XHR request sniffer...")
with sync_playwright() as p:
    browser = p.chromium.launch(headless=False)
    context = browser.new_context()
    page = context.new_page()
    
    captured_requests = []

    def handle_request(request):
        if "sfsites/aura" in request.url and request.method == "POST":
            captured_requests.append({
                "url": request.url,
                "headers": request.headers,
                "post_data": request.post_data
            })

    page.on("request", handle_request)
    
    print("[+] Navigating to Okta Support...")
    page.goto("https://yourtarget.com/help/s/")
    
    print("\n" + "="*60)
    print("[!] ACTION REQUIRED: Log in and perform any search or click on the support portal.")
    print("[!] The sniffer is actively waiting to capture a legitimate signed Aura request.")
    print("="*60 + "\n")
    
    input("Press [ENTER] in this terminal *after* you have performed a search in the browser...")
    
    print(f"\n[+] Captured {len(captured_requests)} legitimate Aura requests:")
    if captured_requests:
        req = captured_requests[-1]
        print(f"    [🔥] Captured valid URL: {req['url']}")
        print(f"    [🔥] Captured valid Headers count: {len(req['headers'])}")
        
        with open("captured_aura_request.json", "w") as f:
            json.dump(req, f, indent=2)
        print("[+] Saved valid Aura request structure to captured_aura_request.json")
    else:
        print("[-] No Aura requests captured. Ensure you triggered a search or action on the page.")
        
    browser.close()

