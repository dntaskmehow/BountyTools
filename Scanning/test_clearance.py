import asyncio
from playwright.async_api import async_playwright

async def test_clearance():
    print("[*] Testing Acquired cf_clearance Cookie against Bitso Assets...")
    
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        context = await browser.new_context()
        page = await context.new_page()
        
        # First visit root to trigger challenge solving and store clearance
        print("[+] Solving challenge at root...")
        await page.goto("https://yourtarget.com/", timeout=30000)
        await asyncio.sleep(4)
        
        # Test fetching a legitimate static asset or chunk
        test_url = "https://yourtarget.com/public-pages-next/bf0a75d80/_next/static/chunks/35iyjcip2xapo.js"
        print(f"[+] Fetching valid asset -> {test_url}")
        
        res = await page.goto(test_url, timeout=15000)
        print(f"[-] Status Code: {res.status}")
        print(f"[-] Content-Type: {res.headers.get('content-type', 'unknown')}")
        print(f"[-] Content Length: {len(await page.content())}")
        
        await browser.close()

if __name__ == "__main__":
    asyncio.run(test_clearance())
