import asyncio
import json
from playwright.async_api import async_playwright

async def dump_json():
    print("[+] Launching Playwright to capture exact form and field JSON endpoints...")
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True, args=["--disable-blink-features=AutomationControlled"])
        context = await browser.new_context(
            user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
        )
        page = await context.new_page()
        
        async def handle_response(response):
            if any(term in response.url for term in ["ticket_forms", "fields", "request", "form"]):
                try:
                    if "application/json" in response.headers.get("content-type", ""):
                        body = await response.json()
                        filename = f"validation_logs/api_dump_{abs(hash(response.url))}.json"
                        with open(filename, "w") as f:
                            json.dump({"url": response.url, "data": body}, f, indent=2)
                        print(f"[+] Logged JSON endpoint: {response.url} -> {filename}")
                except Exception:
                    pass

        page.on("response", handle_response)
        
        target_url = "https://yourtarget.com/hc/en-us/requests/new?ticket_form_id=4518845822874"
        print(f"[*] Navigating to {target_url}...")
        await page.goto(target_url, wait_until="networkidle", timeout=60000)
        await asyncio.sleep(5)
        
        await browser.close()

asyncio.run(dump_json())
