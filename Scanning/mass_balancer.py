import asyncio
import aiohttp
import json
import time
from tqdm import tqdm

# CONFIGURATION
ROUTES_FILE = "professor-bug/moonpay-seat1/endpoints/filtered_api_routes.txt" # If you want to reuse routes? No, use networks below.
OUTPUT_JSON = "recon/mass_balancer_results.json"
OUTPUT_CSV = "recon/mass_balancer_results.csv"

NETWORKS = ["sepolia", "arbitrum-sepolia", "base-sepolia", "avalanche-fuji-testnet"]
TOKEN = "link"

HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    "Accept": "application/json, text/plain, */*",
    "X-HackerOne-Research": "dontaskmehow"
}

async def fetch_balance(session, address, network):
    url = f"https://faucets.chain.link/api/faucet-balance?network={network}&token={TOKEN}"
    try:
        async with session.get(url, headers=HEADERS, timeout=aiohttp.ClientTimeout(total=10)) as response:
            if response.status == 200:
                data = await response.json()
                balance = data.get("balance", "0")
                return {
                    "address": address,
                    "network": network,
                    "balance": balance,
                    "funded": int(balance) > 0,
                    "status_code": response.status
                }
            else:
                return {"address": address, "network": network, "error": f"HTTP {response.status}", "status_code": response.status}
    except Exception as e:
        return {"address": address, "network": network, "error": str(e), "status_code": 0}

async def run_balancer(addresses):
    results = []
    semaphore = asyncio.Semaphore(20) # Limit concurrent requests to avoid IP bans

    async with aiohttp.ClientSession() as session:
        tasks = []
        for addr in addresses:
            for net in NETWORKS:
                async with semaphore:
                    tasks.append(fetch_balance(session, addr, net))
        
        # Use tqdm for progress bar
        print(f"[*] Starting mass balance check for {len(addresses)} addresses across {len(NETWORKS)} networks...")
        
        # Execute all tasks concurrently
        coroutines = [fetch_balance(session, addr, net) for addr in addresses for net in NETWORKS]
        
        # We need to track progress manually or use a wrapper since gather doesn't support tqdm directly easily
        # Let's just run them and update tqdm as they complete
        async def run_with_progress():
            loop = asyncio.get_event_loop()
            future = asyncio.gather(*coroutines)
            
            # Create a task that updates tqdm as futures complete
            pbar = tqdm(total=len(coroutines), desc="Progress", unit="req")
            
            done, pending = [], []
            while coroutines:
                done, pending = await asyncio.wait(pending or coroutines, return_when=asyncio.FIRST_COMPLETED)
                pbar.update(len(done))
                results.extend(done.result() if hasattr(done, 'result') else []) 
                # Note: asyncio.wait returns completed tasks. We need to extract results from the original list order if we want to preserve order, 
                # but for a balancer, order doesn't matter. We just need the data.
                
                # Actually, simpler approach: Just run gather and then process? No, we want progress.
                # Let's just run gather and assume it's fast enough with 20 semaphores.
                break 
            
            # Simpler robust approach for DAN:
            pass 

        # Robust Simple Concurrent Execution
        all_tasks = [session.get(url=f"https://faucets.chain.link/api/faucet-balance?network={net}&token={TOKEN}", headers=HEADERS, timeout=10) for addr in addresses for net in NETWORKS]
        
        # Better way:
        tasks = []
        for addr in addresses:
            for net in NETWORKS:
                tasks.append(asyncio.create_task(fetch_balance(session, addr, net)))
        
        for task in tqdm(asyncio.as_completed(tasks), total=len(tasks), desc="Balancing"):
            res = await task
            results.append(res)

    return results

def save_results(results):
    # Save JSON
    with open(OUTPUT_JSON, 'w', encoding='utf-8') as f:
        json.dump(results, f, indent=2)
    
    # Save CSV for easy sorting/filtering
    import csv
    with open(OUTPUT_CSV, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=["address", "network", "balance", "funded", "status_code", "error"])
        writer.writeheader()
        for r in results:
            row = {k: r[k] for k in ["address", "network", "balance", "funded", "status_code", "error"] if k in r}
            writer.writerow(row)
