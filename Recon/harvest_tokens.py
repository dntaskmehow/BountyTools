import os
import re
from pathlib import Path

evidence_dir = Path("04_evidence")
if not evidence_dir.exists():
    print("[-] 04_evidence directory not found!")
    exit(1)

print("[*] Professor Bug: Sweeping local evidence repository for tokens and identifiers...")

patterns = {
    "JWT Token": r'eyJ[A-Za-z0-9-_=]+\.[A-Za-z0-9-_=]+\.?[A-Za-z0-9-_.+/=]*',
    "API Key / Secret": r'(?:api[_-]?key|bearer|token|auth|secret)[ \t]*[:=][ \t]*["\']?([A-Za-z0-9_\-\.]{16,128})["\']?',
    "UUID / Location Hash": r'\b[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\b',
    "Numeric ID / Business Key": r'(?:business[_-]?id|location[_-]?id|store[_-]?id|user[_-]?id)[^\d]*(\d{2,10})'
}

findings = {k: set() for k in patterns}

for file_path in evidence_dir.rglob("*"):
    if file_path.is_file() and file_path.suffix in ['.csv', '.json', '.txt', '.js']:
        try:
            content = file_path.read_text(errors='ignore')
            for name, pattern in patterns.items():
                matches = re.findall(pattern, content, re.IGNORECASE)
                for m in matches:
                    val = m[0] if isinstance(m, tuple) else m
                    if len(val) > 4:  # filter noise
                        findings[name].add(val)
        except Exception as e:
            pass

output_file = evidence_dir / "reports" / "harvested_tokens_and_ids.txt"
output_file.parent.mkdir(parents=True, exist_ok=True)

with open(output_file, "w") as out:
    for name, matches in findings.items():
        out.write(f"=== {name} ({len(matches)}) ===\n")
        print(f"[+] Found {len(matches)} unique {name}(s)")
        for m in sorted(matches):
            out.write(f"  -> {m}\n")
        out.write("\n")

print(f"\n[+] Extraction complete! Results saved to {output_file}")
