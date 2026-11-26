import json
import warnings

warnings.filterwarnings("ignore")

def inspect_format_entries():
    print("[*] Inspecting the 37 format-related signature entries from extracted VAPIX data...\n")
    
    try:
        with open("extracted_vapix_methods.json", "r", encoding="utf-8") as f:
            methods = json.load(f)
            
        # Filter for format-related entries containing '%' or '#'
        format_entries = [m for m in methods if '%' in m or '#' in m]
        
        print(f"[+] Total format entries found: {len(format_entries)}\n")
        for idx, entry in enumerate(format_entries, 1):
            print(f"[{idx:02d}] {entry}")
            
        print("\n[*] Analysis complete. These entries define the active format tokens parsed by the device.")
        
    except Exception as e:
        print(f"[!] Error reading JSON: {e}")

if __name__ == "__main__":
    inspect_format_entries()
