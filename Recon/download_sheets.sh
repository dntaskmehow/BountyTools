#!/bin/bash
mkdir -p 04_evidence/sheets
cat << 'SHEETEOF' > sheets_to_download.txt
https://yourtarget.com/<placeholder-sheet-key>
https://yourtarget.com/<placeholder-sheet-key>
https://yourtarget.com/<placeholder-sheet-key>
https://yourtarget.com/<placeholder-sheet-key>
https://yourtarget.com/<placeholder-sheet-key>
https://yourtarget.com/<placeholder-sheet-key>
https://yourtarget.com/<placeholder-sheet-key>
https://yourtarget.com/<placeholder-sheet-key>
https://yourtarget.com/<placeholder-sheet-key>
SHEETEOF

echo "[*] Downloading harvested spreadsheets..."
while IFS= read -r url; do
    if [ -n "$url" ]; then
        key=$(echo "$url" | grep -oP 'key=\K[^&]+')
        echo "[+] Fetching spreadsheet key: $key"
        curl -s -L "$url" -o "04_evidence/sheets/sheet_${key}.xlsx"
    fi
done < sheets_to_download.txt
echo "[+] Done downloading sheets into 04_evidence/sheets/"
