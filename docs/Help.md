# Toolkit Help and Troubleshooting

Use this guide when setup, imports, browser automation, network requests, scripts, or shell tools are not working. This applies to Windows, PowerShell, Git Bash, and WSL.

## 1. Before Running Anything

### Confirm authorization

Use the toolkit only against systems covered by your written authorization or an explicit bug bounty scope.

Before a test, confirm:

- The exact allowed domain and subdomains
- Whether API and development subdomains are allowed
- IP ranges and direct-IP testing rules
- Maximum request rate or concurrency
- Whether automated tools or fuzzing are permitted
- Whether exploit validation is allowed
- What evidence may be retained
- How to report sensitive findings

Stop if the target URL is missing, incorrect, or not listed in scope.

### Replace placeholders

At the top of every script, replace placeholders with authorized values:

```python
BASE_URL = "https://yourtarget.com"
TARGET_URL = "https://api.yourtarget.com/v1/example"
TOKEN = "YOUR_TOKEN"
COOKIE = "YOUR_COOKIE"
```

Do not reuse one user's token while testing another user's account unless the authorization and scope explicitly permit it.

## 2. Set Up Python

### Windows PowerShell

```powershell
cd C:\path\to\Bountykit-github
python --version
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
pip install -r requirements.txt
```

If PowerShell blocks activation:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\.venv\Scripts\Activate.ps1
```

### Git Bash

```bash
cd /c/path/to/Bountykit-github
python -m venv .venv
source .venv/Scripts/activate
python -m pip install --upgrade pip
pip install -r requirements.txt
```

### WSL or Linux

```bash
cd /path/to/Bountykit-github
python3 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
pip install -r requirements.txt
```

Do not mix different Python environments. Confirm the interpreter used:

```powershell
where.exe python
python -c "import sys; print(sys.executable)"
```

```bash
which python
python -c 'import sys; print(sys.executable)'
```

## 3. Install Playwright Browsers

For Playwright scripts:

```powershell
python -m playwright install chromium
```

For all browsers:

```powershell
python -m playwright install
```

On Linux or WSL, if browser libraries are missing:

```bash
python -m playwright install --with-deps chromium
```

Do not run browser setup in one environment and execute scripts from another environment.

## 4. Common Python Errors

### `python: command not found`

Try:

```powershell
py --version
py -m venv .venv
```

```bash
python3 --version
```

### `ModuleNotFoundError: No module named 'requests'`

The virtual environment is not active or dependencies were not installed.

```powershell
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
python -c "import requests, httpx, playwright, aiohttp; print('Dependencies loaded')"
```

The Playwright package and Chromium browser are separate. Run:

```powershell
python -m playwright install chromium
```

### `No module named curl_cffi`

```powershell
python -m pip install "curl-cffi>=0.7,<1"
```

For repeated failures:

```powershell
python -m pip uninstall curl-cffi
python -m pip install --upgrade curl-cffi
```

### `No module named bs4`

```powershell
python -m pip install beautifulsoup4
```

### `No module named lib.core.enums`

The file `Exploits/url_double_encode_null.py` expects SQLMap's `lib.core.enums` module. It is not an ordinary toolkit dependency and will not work outside a SQLMap source tree.

Options:

- Use the file only inside a compatible SQLMap tamper-plugin environment.
- Replace the import with a local constant if you do not need SQLMap integration.
- Do not install random packages claiming to provide `lib.core.enums`.

For this standalone repository, the script currently is a SQLMap plugin-style example rather than a normal independent tool.

### `SyntaxError` or indentation error

Open the exact file and line reported. Typical causes are:

- Editing an existing line without keeping indentation
- Mixing spaces and tabs
- A missing comma, quote, bracket, or parenthesis
- Running a file intended for a different Python version

Check syntax without sending network requests:

```powershell
python -m py_compile Recon\discover_routes.py
```

Replace the filename as needed.

## 5. Network and Target Problems

### The script keeps sending to `yourtarget.com`

The script still contains placeholder values. Replace target variables near the top of the script.

Search placeholders:

```powershell
Select-String -Path *.py, Recon/*.py, Scanning/*.py, Fuzzers/*.py, Exploits/*.py -Pattern "yourtarget|YOUR_TOKEN|YOUR_COOKIE" -CaseSensitive
```

In Git Bash or WSL:

```bash
grep -RInE 'yourtarget|YOUR_TOKEN|YOUR_COOKIE' --include='*.py' --include='*.sh' .
```

### `Name or service not known`

Check:

- The target hostname is spelled correctly
- DNS can resolve it
- The domain is in scope
- A VPN or proxy is not misconfigured
- The API subdomain is being used instead of the normal domain

Do not replace the target with an unrelated public domain for testing.

### `Connection refused`

Possible reasons:

- A local bridge is not running
- The wrong port is selected
- The service is intentionally offline
- A firewall blocks outbound or inbound traffic
- The script is using a direct IP, but direct-IP testing is not allowed

For the local bridge:

```powershell
python Exploits\local_bridge_proxy.py
```

Default URL:

```text
http://127.0.0.1:8888
```

### `Timeout`

Lower concurrency and request volume. Check whether the script contains values such as `asyncio.gather`, worker counts, thread counts, or `timeout=`.

Start with:

- 1 worker
- 1 second or longer timeout
- One URL
- One header mutation
- One account

Do not increase concurrency until the program allows it.

### `CERTIFICATE_VERIFY_FAILED`, SSL, or TLS error

Confirm:

- The target URL uses the correct scheme
- The system clock is correct
- A proxy or VPN certificate is trusted
- A direct-IP test is using the correct SNI or Host value
- The target still supports the negotiated TLS version

Do not disable certificate verification by default. If a local or explicitly approved test requires it, understand the risk and keep the exception limited to that script or session.

### Proxy or VPN problems

If using a proxy, inspect environment variables:

```powershell
Get-ChildItem Env: | Where-Object Name -Match 'PROXY'
```

```bash
env | grep -i proxy
```

Check both uppercase and lowercase variables. A proxy set for one environment may not apply to another terminal.

## 6. Authentication Problems

### `401 Unauthorized`

A request was not authenticated.

Check:

- `Authorization: Bearer YOUR_TOKEN` contains a real token
- The token was not pasted with extra quotes or spaces
- The token has not expired
- The correct token type is used
- The token belongs to the target environment
- Cookie names match the target application
- Cookies are not from an unrelated browser or domain

Never paste a live token into a screenshot or commit.

### `403 Forbidden`

Authentication worked, but the action was denied. It may be:

- Missing authorization scope
- A role restriction
- A BOLA or tenant boundary
- A CSRF requirement
- A WAF or rate limit
- An unsupported HTTP method

Compare a valid authorized account and object first. Do not assume a vulnerability from `403` alone.

### A session stops working

Session cookies and CSRF tokens can expire or rotate.

Use a fresh session and repeat the collection process:

```powershell
python Recon\harvest_session.py
python Recon\verify_fresh_session.py
```

Do not reuse Playwright profiles or cookie exports outside their intended authorized environment.

### JWTs or bearer tokens are invalid

Confirm:

- The JWT is complete and has exactly two dots
- No newline or whitespace was copied
- The header and payload do not contain placeholder text
- The token belongs to the current test tenant
- The signature is not being modified unintentionally
- The script is not sending the token twice

## 7. Cookie Problems

### Cookie strings have encoding such as `%3A`

This may be valid encoded cookie content. Do not remove URL encoding unless the application documentation or browser shows the plain value.

### Cookie domain mismatch

Browser cookies are commonly restricted by:

- Exact hostname
- Parent domain
- `Secure` flag
- `HttpOnly` flag
- `SameSite` policy
- Path

Check the domain and path fields while collecting the session. Do not copy a cookie to an unrelated hostname.

## 8. Playwright Problems

### `Executable doesn't exist at ...`

Run:

```powershell
python -m playwright install chromium
```

### `BrowserType.launch: Target page, context or browser has been closed`

Possible causes:

- The script's browser context closed before an awaited request finished
- The page redirected to a login page
- The target changed the session after navigation
- The script has a runtime exception before cleanup

Run only one browser script and add enough output to identify the last successful step.

### Playwright hangs

Increase or remove a single timeout for diagnosis, but do not make it infinite.

Look for:

- `page.goto(..., timeout=...)`
- `wait_for_load_state(...)`
- Slow redirects
- A login challenge
- Cookie consent overlays
- Captcha or MFA

## 9. HTTP Method and Header Problems

### `405 Method Not Allowed`

The endpoint supports a different HTTP method. Verify against the application's API documentation or browser Network panel.

### Unexpected redirect

Capture:

- Status code
- `Location` header
- Original URL
- Redirect URL
- Authentication state

Do not follow redirects during every test when the location itself is the behavior being tested.

### CORS test returned nothing

Test with an actual browser fetch or an explicit Origin header. Some servers ignore arbitrary Origin headers unless the script stores or sends cookies and credentials.

Review `Access-Control-Allow-Origin` and `Access-Control-Allow-Credentials` together.

### Host-header test had no effect

Possible reasons:

- The local proxy replaced the header
- The test target only accepts TLS SNI
- A load balancer overwrote the header
- The application uses `X-Forwarded-Host` instead
- The request was not allowed in scope

Keep one variable changed at a time.

## 10. Fuzzer Problems

### Too many HTTP responses

Reduce the list of candidates and payloads. Start with:

- 5 to 10 endpoints
- 5 to 10 mutations
- 1 to 3 concurrent requests
- A low request rate

### Fuzzer causes login lockouts or rate limits

Stop immediately if the scope's limits are reached. Preserve timestamps and logs, then wait until the program permits testing again.

### Everything appears vulnerable

Compare against a known unauthenticated baseline. A false positive may occur because:

- The response is a generic error page
- The test account has broad privileges
- The script sent a cached response
- The endpoint returns static public content
- Redirects were followed
- The WAF replaced the real response

## 11. Exploit and Direct-IP Problems

### Direct-IP requests fail

Direct-IP testing requires SNI or Host information. Review:

- IP address
- SNI hostname
- HTTP `Host` header
- TLS certificate
- Authorized direct-IP scope

A direct-IP response may come from a shared CDN or reverse proxy. Do not test unrelated virtual hosts.

### Bridge returns `502`, `503`, or `504`

Check:

- Bridge process is active
- Upstream hostname is configured
- Upstream target is authorized
- TLS SNI and Host values agree
- Proxy settings are not bypassing or capturing the request twice
- The upstream service is available

### The exploit script changed or damaged data

Stop all requests. Disconnect the tool from the network if necessary. Preserve logs and report the unintended effect according to the bug bounty program or incident process.

Only use scripts that can safely create test data. Never delete, modify, or exfiltrate production data unless explicitly authorized.

## 12. Shell Script Problems

### `bash: command not found` in PowerShell

Install or open Git Bash or WSL.

```powershell
bash Recon\thuringer_sweep.sh
```

### External tool not found

Install only tools allowed by the target program and your operating environment. Example tools used by large shell scripts include:

- `curl`
- `jq`
- `nmap`
- `nuclei`
- `ffuf`
- `katana`
- `sqlmap`
- `gobuster`
- `feroxbuster`
- `nikto`
- `whatweb`
- `wafw00f`

Check installation:

```bash
command -v curl
command -v jq
command -v nuclei
```

### Shell scripts contain placeholders

Variables such as `$BS_URL`, `$BS_TOKEN`, `$BS_COOKIE`, and `<authorized-url>` must be replaced or exported first.

Example:

```bash
export BS_URL="https://yourtarget.com"
export BS_DOMAIN="yourtarget.com"
export BS_TOKEN="YOUR_TOKEN"
export BS_COOKIE="YOUR_COOKIE"
```

Then review and run individual commands rather than the entire script.

## 13. Missing System Tools

### Linux package example

```bash
sudo apt update
sudo apt install -y curl jq nmap
```

Only install specialized tools after checking the target's rules.

### Windows package example

Use Windows Package Manager only for tools that are allowed:

```powershell
winget install --id cURL.cURL
winget install --id Python.Python.3.12
```

## 14. Git and Secret Problems

### A real token was committed

1. Revoke or rotate the token immediately.
2. Remove the token from the file.
3. Replace it with `YOUR_TOKEN`.
4. Commit the sanitized version.
5. Remove the secret from Git history if it is published.

Do not assume editing the latest file removes the secret from previous commits.

### Ignore generated or sensitive files

Add entries such as:

```gitignore
.venv/
__pycache__/
*.pyc
Evidence/
evidence/
*.jsonl
*.har
*.png
*.jpg
.env
.env.*
!.env.example
cookies.txt
session.json
*token*
*secret*
*cookie*
```

Review with:

```bash
git status
```

before every commit.

## 15. Debugging a Script in 5 Steps

1. Read the top-level target and credential variables.
2. Run syntax checking.
3. Run one request with a timeout.
4. Print status code and selected response headers.
5. Compare with a known baseline.

Example:

```python
import httpx

URL = "https://api.yourtarget.com/v1/example"

try:
    response = httpx.get(URL, timeout=10)
    print(response.status_code)
    print(dict(response.headers))
    print(response.text[:500])
except httpx.HTTPError as exc:
    print(f"Request failed: {exc}")
```

This is a safe diagnostic pattern, but it still must run only against an authorized endpoint.

## 16. Getting a Useful Error Report

When asking for help, provide:

- The exact script name
- The Python version
- The operating system
- Whether `.venv` was active
- The full first error message
- The command used
- The target placeholder type, not a real hostname
- Whether Playwright or curl-cffi was involved
- Whether authorization or scope was confirmed

Remove real tokens, cookies, private IP addresses, customer data, and target hostnames before sharing logs.

## 17. Safety Reminder

A toolkit script is not automatically safe. Always assume that a request may create a side effect, trigger a workflow, or generate evidence.

Before running a script:

- Read the request method
- Review the endpoint
- Check whether it writes or deletes data
- Use low concurrency
- Use test accounts
- Avoid real customer records
- Stop after a single reproducible result
- Report, redact, and document the finding
