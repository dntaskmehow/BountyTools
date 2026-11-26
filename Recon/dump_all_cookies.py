import json
from playwright.sync_api import sync_playwright

print("[*] Launching total browser context cookie dumper...")
with sync_playwright() as p:
    browser = p.chromium.launch(headless=False)
    context = browser.new_context()
    page = context.new_page()
    
    print("[+] Navigating to Okta Support...")
    page.goto("https://yourtarget.com/help/s/")
    
    print("\n" + "="*60)
    print("[!] ACTION REQUIRED: Log in in the browser window.")
    print("="*60 + "\n")
    
    input("Press [ENTER] in this terminal *after* you are fully logged in...")
    
    # Grab all cookies across ALL domains in the browser context
    all_cookies = context.cookies()
    print(f"\n[+] Total cookies captured across all domains: {len(all_cookies)}")
    
    session_cookies = {}
    for c in all_cookies:
        print(f"    [+] Domain: {c['domain']} | Name: {c['name']} | Value: {c['value'][:20]}...")
        if c['name'] in ['sid', 'renderCtx', 'shd', 'oid', 'at', 'token']:
            session_cookies[c['name']] = c['value']
            
    with open("all_browser_cookies.json", "w") as f:
        json.dump(all_cookies, f, indent=2)
        
    print(f"\n[🔥] Extracted {len(session_cookies)} high-value session cookies:")
    for k, v in session_cookies.items():
        print(f"    {k} = {v}")
        
    browser.close()

