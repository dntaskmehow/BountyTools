# I Built a Free 100+ Script Bug-Bounty Toolkit—Here Is the Complete Workflow

**Free, organized, beginner-friendly, and shaped by real bug-bounty work.**

Bug bounty hunting involves a surprising amount of repetition. Recon scripts discover routes. Browser scripts collect sessions. Authentication scripts test bearer tokens and cookies. CORS scripts check origins. Fuzzers mutate parameters. Direct-IP scripts validate routing behavior. Evidence scripts preserve the details needed for a report.

I used to keep these scripts scattered across folders and notes. Over time, I realized the scripts were only part of the process. The real value came from organizing the process.

This repository is a **free bug-bounty toolkit** containing approximately 100 Python and shell utilities. It grew out of authorized testing across multiple bounty programs and helped me earn **$8,000 in two weeks**. It is important to be honest: that result was possible in a specific period, on specific scopes, with specific timing. It is not a promise or an average. The tools are useful only when paired with careful scope review, judgment, patience, and manual verification.

## Why I Built It

I wanted to stop rebuilding the same utilities before every assessment.

The toolkit needed to:

- Separate reconnaissance from active validation
- Use consistent target placeholders
- Keep live credentials out of shared code
- Make scripts easier for beginners to inspect
- Support browser and HTTP workflows
- Encourage repeatable evidence collection
- Organize scripts so they match an actual assessment lifecycle

## The Four-Phase Workflow

| Phase | Folder | Main purpose |
|---|---|---|
| Recon | `Recon/` | Find assets, routes, sessions, forms, and endpoints |
| Scanning | `Scanning/` | Compare authentication, authorization, CORS, CSRF, headers, cookies, and endpoints |
| Fuzzing | `Fuzzers/` | Change parameters, hosts, methods, namespaces, and payload values |
| Exploit validation | `Exploits/` | Validate selected weaknesses through controlled routing and browser workflows |

The order matters. Recon gathers facts. Scanning identifies differences. Fuzzing explains boundaries. Exploit validation proves impact only after a hypothesis is already strong.

## The Workflow at a Glance

1. Review the bug-bounty scope.
2. Replace target placeholders with an authorized hostname.
3. Run recon scripts with low request volume.
4. Create a candidate endpoint list.
5. Run authenticated and unauthenticated baseline requests.
6. Compare account roles and object ownership.
7. Mutate one variable at a time.
8. Manually reproduce the most interesting behavior.
9. Capture and redact evidence.
10. Submit a clear report.

A useful mental model is:

- Recon: What exists?
- Scanning: What differs?
- Fuzzing: What changes the behavior?
- Exploit validation: What impact can be proven safely?

## Recon: Information Before Assumptions

The `Recon/` folder contains scripts for route discovery, API discovery, browser cookies, HTML forms, token pages, session harvesting, OAuth redirects, evidence inspection, and tenant context.

Representative scripts include:

- `discover_routes.py`
- `discover_api_upstream.py`
- `dump_all_cookies.py`
- `dump_all_forms_json.py`
- `extract_oauth_redirect.py`
- `harvest_session.py`
- `live_session_harvester.py`
- `map_controllers_to_actions.py`
- `verify_fresh_session.py`

Recon is most useful when it is limited to relevant details:

| Collect | Example |
|---|---|
| Hostnames | Authorized application and API domains |
| Routes | Login, account, order, upload, or search endpoints |
| HTTP methods | GET, POST, PUT, PATCH, DELETE, OPTIONS |
| Authentication state | Anonymous, user, administrator, or tenant |
| Objects | IDs, names, account numbers, and resource references |
| Redirect behavior | OAuth callbacks and login return URLs |
| Response differences | Status, headers, length, and body |

Do not collect every visible value. Collect the values needed to test one meaningful hypothesis.

## Scanning: Turning Observations Into Questions

The `Scanning/` folder contains scripts that compare request states.

The scripts include bearer-token tests, JWT tests, cookie tests, CORS checks, CSRF checks, BOLA tests, HMAC authentication tests, host injection tests, IP-spoof tests, method overrides, private form discovery, endpoint checks, and UTXO diagnostics.

The most important idea is the baseline comparison.

| Request state | Expected result |
|---|---|
| Anonymous request | Public data may be available; private data should be denied |
| User A request | User A should access User A resources |
| User B request | User B should not access User A resources |
| Administrator request | Administrative resources only within scope |
| Missing token | `401` or a defined authentication error |
| Valid token, denied action | `403` or a defined authorization error |

A `200` status is not proof of a vulnerability. It becomes evidence only after you know the expected and actual behavior.

## Fuzzing: Mutate One Variable

The `Fuzzers/` folder contains mutations for:

- URL and API paths
- OAuth parameters
- Host headers
- Forwarded-IP headers
- Direct-SNI routing
- Aura components and namespaces
- Remote actions
- Authenticated page requests
- CSRF gateways
- IPC broker messages

The safest fuzzing pattern starts with a small set:

| Step | Example |
|---|---|
| Baseline | Send one known-valid URL |
| Mutation 1 | Change one path segment |
| Mutation 2 | Change one query parameter |
| Mutation 3 | Change one host header |
| Mutation 4 | Change one method |
| Mutation 5 | Compare the response |

A useful fuzzer should report status codes, redirects, response lengths, and selected headers—not merely print that a request succeeded.

## Exploit Validation: Prove the Finding Carefully

The `Exploits/` folder contains scripts for direct-IP requests, Cloudflare bypass behavior, CloudFront routing, SNI testing, browser clearance, local forwarding, URL mutation, and targeted exploit workflows.

These scripts require more caution than recon or basic endpoint testing.

Before running anything from `Exploits/`:

- Confirm exploit validation is allowed by the program
- Confirm the target host and virtual host are in scope
- Use test accounts and test objects
- Avoid customer data and production writes
- Use the smallest request that proves impact
- Stop after obtaining repeatable evidence
- Do not delete or modify records
- Document unintended effects immediately

## Installation

### 1. Create a virtual environment

**Windows:**

```powershell
cd C:\path\to\Bountykit-github
python -m venv .venv
.\.venv\Scripts\Activate.ps1
```

**Linux or macOS:**

```bash
cd /path/to/Bountykit-github
python3 -m venv .venv
source .venv/bin/activate
```

### 2. Install dependencies

```bash
python -m pip install --upgrade pip
pip install -r requirements.txt
```

Workspace dependencies include:

- `requests`
- `httpx`
- `curl-cffi`
- `playwright`
- `beautifulsoup4`
- `aiohttp`
- `tqdm`

### 3. Install Chromium for browser scripts

```bash
python -m playwright install chromium
```

If Chromium dependencies are missing on Linux:

```bash
python -m playwright install --with-deps chromium
```

## Running the Scripts

Run from the repository root:

```bash
python Recon/discover_routes.py
python Recon/dump_all_cookies.py
python Scanning/test_cors.py
python Fuzzers/fuzz_host_headers.py
python Exploits/local_bridge_proxy.py
```

Shell scripts can be run with Git Bash or WSL:

```bash
bash Recon/download_sheets.sh
bash Recon/thuringer_sweep.sh
bash Exploits/dontaskmehow-special.sh
```

Review shell scripts before running them. They may invoke external tools and must be configured for an authorized scope.

## Replace the Placeholders

No live target or credential should be committed.

```python
BASE_URL = "https://yourtarget.com"
TARGET_URL = "https://api.yourtarget.com/v1/example"
TOKEN = "YOUR_TOKEN"
COOKIE = "YOUR_COOKIE"
API_KEY = "YOUR_API_KEY"
API_SECRET = "YOUR_API_SECRET"
```

```bash
export BS_URL="https://yourtarget.com"
export BS_DOMAIN="yourtarget.com"
export BS_TOKEN="YOUR_TOKEN"
export BS_COOKIE="YOUR_COOKIE"
```

Use a separate account or lab for high-impact testing whenever possible.

## Local Bridge

The repository includes a local HTTP bridge for controlled forwarding.

```bash
python Exploits/local_bridge_proxy.py
```

The default local address is:

```text
http://127.0.0.1:8888
```

A browser or script sends a local request, the bridge forwards it to the configured authorized target, and the response returns locally.

Never expose the bridge publicly. Bind it to localhost unless a written lab configuration requires a different setup.

## Example: CORS Testing

CORS testing is not finished when a script prints a header.

A complete check should establish:

1. The endpoint's normal response
2. The response with no Origin header
3. The response with an allowed test origin
4. The response with an unexpected origin
5. Whether credentials are included
6. Whether the browser could actually read and use the response

A permissive CORS header may indicate risk. Cross-origin resource access can demonstrate impact. The distinction is important.

## Example: Authorization Testing

The strongest authorization tests use two controlled accounts.

### BOLA / IDOR matrix

| Object | Account A | Account B | Anonymous |
|---|---|---|---|
| A-owned resource | Allowed | Denied | Denied |
| B-owned resource | Denied | Allowed | Denied |
| Public resource | Allowed | Allowed | Allowed |

A result is significant when:

- Account B reads Account A's private object
- Account B updates Account A's object
- Account B downloads Account A's evidence
- Account B changes Account A's account state

The script should save account labels in a way that does not expose real identities or customer information.

## Example: Host-Header Testing

Host-header testing may reveal routing or cache behavior.

Test one variable at a time:

- `Host`
- `X-Forwarded-Host`
- `X-Original-Host`
- `Origin`
- `Referer`
- TLS SNI where direct-IP testing is authorized

Record the request and response exactly. Stop if a third-party virtual host or unrelated customer could be affected.

## Evidence Collection

A report is stronger than a screenshot when it has context.

Save:

- Target and endpoint
- HTTP method
- Account type
- Request headers
- Request body
- Response status
- Redirect location
- Relevant response excerpt
- Timestamp
- Reproduction steps
- Expected behavior
- Actual behavior
- Security impact

A good evidence structure is:

```text
Evidence/
  requests/
  responses/
  screenshots/
  redirects/
  headers/
  reports/
```

Redact tokens and personal data before commit or report submission.

## Common Problems

| Problem | Fix |
|---|---|
| `ModuleNotFoundError` | Activate the virtual environment and install `requirements.txt` |
| `No module named curl_cffi` | Install `curl-cffi` |
| Browser executable missing | Run `python -m playwright install chromium` |
| `401 Unauthorized` | Check or refresh `YOUR_TOKEN` |
| `403 Forbidden` | Check role and object ownership |
| Connection refused | Check the local bridge or target availability |
| Timeout | Reduce concurrency and request volume |
| SSL or certificate error | Review proxy, clock, SNI, and target configuration |
| The script uses placeholders | Replace top-level target variables |
| `lib.core.enums` missing | The plugin-style script needs SQLMap's Python source environment |

The repository includes `Help.md` for detailed setup and troubleshooting.

## Git Safety Checklist

Before committing:

- Remove real bearer tokens
- Remove browser session cookies
- Remove private API keys
- Remove personal account data
- Remove real target hostnames
- Remove screenshots containing sensitive details
- Ignore `.venv/`
- Ignore evidence directories
- Ignore browser profiles
- Ignore `.env` and secret files

Useful `.gitignore` entries:

```gitignore
.venv/
__pycache__/
*.pyc
Evidence/
evidence/
.env
.env.*
!.env.example
cookies.txt
session.json
*.har
*token*
*secret*
*cookie*
```

## What I Learned

### 1. Tools create speed, not certainty

A script can send one thousand requests. It cannot decide whether a response is a vulnerability. That judgment still requires scope, comparison, and impact analysis.

### 2. Organization saves more time than automation

The folder structure is more useful than a random collection of scripts because it creates a repeatable process.

### 3. Baselines make findings credible

An authenticated request should be compared with an anonymous request, another account, or a known good resource.

### 4. Minimal proof is better than maximum damage

The smallest reproduction that proves impact is usually the safest and best report evidence.

### 5. Evidence should be reviewable

A reviewer should see the target, request, response, account context, expected behavior, actual behavior, and impact.

## Beginner Learning Plan

| Day | Task |
|---|---|
| 1 | Read scope rules and set up Python |
| 2 | Install dependencies and Playwright |
| 3 | Run recon against an authorized lab |
| 4 | Capture normal login and API traffic |
| 5 | Test CORS or endpoint authorization |
| 6 | Run a small fuzzer |
| 7 | Reproduce one result manually |
| 8 | Write a clean evidence report |

## Repository Contents

| File or Folder | Purpose |
|---|---|
| `README.md` | Full documentation and usage guide |
| `Help.md` | Setup and troubleshooting guide |
| `requirements.txt` | Workspace-wide Python dependencies |
| `Recon/` | Discovery and session collection |
| `Scanning/` | Authorization and configuration checks |
| `Fuzzers/` | Parameter and header mutation |
| `Exploits/` | Controlled exploit validation |

## Free for the Community

This repository is a practical thank-you to the people who treat bug bounty work seriously: the researchers reviewing auth flows, replaying strange redirects, reading JavaScript bundles, comparing account roles, capturing evidence, and writing reports.

It is also a reminder that nobody should have to start from an empty folder. Sharing a starter workflow can save another person time and encourage better testing habits.

The toolkit does not guarantee a bounty, a finding, or a $8,000 week. It is one organized way to move from an idea to evidence without losing track of the process.

## Final Safety Reminder

Use the toolkit only for systems you own or are explicitly authorized to test. Follow program scope, rate limits, and reporting rules. Replace every placeholder. Keep sessions and tokens private. Use the smallest impact needed for proof.

If this toolkit helps one security researcher write a clearer report or avoid rebuilding the same script, it has done its job.
