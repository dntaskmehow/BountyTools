import json
from playwright.sync_api import sync_playwright

print("[*] Launching headless browser to harvest Livewire snapshots...")
with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)
    page = browser.new_page()
    
    # Navigate to signup page
    page.goto("https://yourtarget.com/store/sign-up")
    page.wait_for_load_state("networkidle")
    
    # Extract all elements with wire:initial-data
    elements = page.query_selector_all("[wire\\:initial-data]")
    print(f"[+] Found {len(elements)} Livewire components on the page.\n")
    
    for idx, el in enumerate(elements):
        data_attr = el.get_attribute("wire:initial-data")
        if data_attr:
            parsed = json.loads(data_attr)
            print(f"--- Component {idx+1} ---")
            print(f"Name: {parsed.get('fingerprint', {}).get('name', 'Unknown')}")
            print(f"ID: {parsed.get('fingerprint', {}).get('id', 'Unknown')}")
            print(json.dumps(parsed, indent=2))
            print("=" * 50)
            
            # Save to file for our fuzzer
            with open(f"validation_logs/livewire_component_{idx+1}.json", "w") as f:
                f.write(json.dumps(parsed, indent=2))

    browser.close()
print("[*] Snapshot harvesting complete. Saved to validation_logs/")
