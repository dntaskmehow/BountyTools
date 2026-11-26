import re
import httpx
import warnings

warnings.filterwarnings("ignore")

def scrape_full_html():
    print("[*] Fetching raw 592 KB HTML overview directly from developers.openai.com...")
    url = "https://yourtarget.com/api/reference/overview"
    
    try:
        res = httpx.get(url, verify=False, timeout=15.0)
        content = res.text
        print(f"[*] Successfully loaded {len(content)} bytes of HTML content.")
        
        # Comprehensive patterns for hidden paths, keys, and internal configs
        patterns = {
            "API Paths (/v1/...)": r'(\/v1\/[a-zA-Z0-9_\-\/]+)',
            "Potential API Keys / Tokens": r'(sk-[a-zA-Z0-9]{20,})',
            "Internal Hostnames / URIs": r'([a-zA-Z0-9\-]+\.internal\.[a-zA-Z0-9]+|[a-zA-Z0-9\-]+\.corp\.[a-zA-Z0-9]+|[a-zA-Z0-9\-]+\.openai\.com)',
            "Admin / Internal / Beta Routes": r'(\/(?:admin|internal|debug|test|private|v2|beta|dashboard)[a-zA-Z0-9_\/]*)'
        }

        for label, pattern in patterns.items():
            matches = sorted(list(set(re.findall(pattern, content))))
            print(f"\n[+] {label} ({len(matches)} found):")
            for match in matches[:20]:  # Limit output display to top 20 per category
                print(f"    -> {match}")
            if len(matches) > 20:
                print(f"    ... [and {len(matches) - 20} more]")

    except httpx.RequestError as e:
        print(f"[!] Request error: {e}")

if __name__ == "__main__":
    scrape_full_html()
