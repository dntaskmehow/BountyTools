import requests
import json

# Target base and extracted Adyen/Cart endpoints
BASE_URL = "https://yourtarget.com/on/yourtarget.com/Sites-bowers_us-Site/en_US/"
ENDPOINTS = [
    "Adyen-GetPaymentMethods",
    "Adyen-ShippingMethods",
    "Adyen-SelectShippingMethod",
    "Adyen-PaymentsDetails",
    "Adyen-PaymentFromComponent",
    "Adyen-ShowConfirmationPaymentFromComponent",
    "Adyen-CreateTemporaryBasket",
    "Cart-AddProduct"
]

headers = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
    "Content-Type": "application/x-www-form-urlencoded"
}

print("[*] Starting Adyen & SFCC Pipeline Authorization Audit...")

for endpoint in ENDPOINTS:
    url = BASE_URL + endpoint
    try:
        # Test GET request
        resp_get = requests.get(url, headers=headers, timeout=10, allow_redirects=False)
        
        # Test POST request with dummy payload
        resp_post = requests.post(url, headers=headers, data={"amount": "1.00", "currency": "USD"}, timeout=10, allow_redirects=False)
        
        print(f"[+] Endpoint: {endpoint}")
        print(f"    -> GET Status: {resp_get.status_code} | Size: {len(resp_get.content)}")
        print(f"    -> POST Status: {resp_post.status_code} | Size: {len(resp_post.content)}")
        
        if resp_post.status_code in [200, 302, 500]:
            print(f"    [!] INTERESTING RESPONSE on POST: {resp_post.status_code} (Check for server-side processing)")
            
    except Exception as e:
        print(<code>[-] Error testing {endpoint}: {e}</code>)

print("[*] Audit complete. Check output headers for server error leaks or open endpoints.")
