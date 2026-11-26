import re
from curl_cffi import requests

session = requests.Session()
bundle_url = "https://yourtarget.com/help/s/sfsites/l/%7B%22mode%22%3A%22PROD%22%2C%22dfs%22%3A%2241%22%2C%22app%22%3A%22siteforce%3AcommunityApp%22%2C%22fwuid%22%3A%22ZVYtV2g3NHN0UGNVNzBMbldfZ0ZwZ2tVMjdnTGFERUU2S3FfSVdrcU92bkExNS4zLjE2MDEw%22%2C%22loaded%22%3A%7B%22APPLICATION%40markup%3A%2F%2Fsiteforce%3AcommunityApp%22%3A%221897_Qx6CsUG7r803A_23Hon_1g%22%7D%2C%22apce%22%3A1%2C%22apck%22%3A%22JHt0aW1lc3RhbXB9MDAwMDAwMDE5Mzhlbl9VUw%22%2C%22mlr%22%3A%221%22%2C%22pathPrefix%22%3A%22%2Fhelp%22%2C%22dns%22%3A%22c%22%2C%22ls%22%3A1%2C%22lrmc%22%3A%22551347034%22%7D/app.js"

print("[*] Downloading app.js to map controller classes to ACTION$ bindings...")
res = session.get(bundle_url, impersonate="chrome120", timeout=25)

# Search for patterns where a controller name precedes an action
# Example pattern in minified code: ControllerName...ACTION$MethodName
matches = re.findall(r'([a-zA-Z0-9_]+Controller)[^}]+?(ACTION\$[a-zA-Z0-9_]+)', res.text)

print(f"[+] Discovered {len(matches)} controller-to-action mappings!")
unique_mappings = set(matches)
for ctrl, act in sorted(unique_mappings)[:25]:
    print(f"    - apex://{ctrl}/{act}")

