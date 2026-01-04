#!/bin/bash

# 1. Install GNU Parallel (if you don't already have it).
if ! command -v parallel &> /dev/null; then
    echo "Installing GNU Parallel..."
    sudo apt-get update && sudo apt-get install -y parallel
fi

# 2. Clean up old junk files
echo "[*] Cleaning up old files..."
rm -f part_*.jsonl official_31bit.jsonl

# 3. RUNNING IN PARALLEL (MOST IMPORTANT)
# -j 6: Runs a maximum of 6 processes simultaneously (Saves RAM for the OS)
# --bar: Displays the progress bar
# 8 jobs: 0, 2500, 5000... (Each job processes 2500 curves -> Total 20,000)
# Each job takes approximately 10-15 minutes. Because it runs on 6 threads, the total time is approximately 1.5 hours.

echo "[*] Starting Parallel Execution (31-bit)..."

parallel --bar -j 6 sage joc_pipeline_rich_log_v2.sage batch 31bit {1} 2500 {#} ::: 0 2500 5000 7500 10000 12500 15000 17500

# 4. Merge results
echo "[*] Merging output files..."
cat part_*.jsonl > official_31bit.jsonl
rm part_*.jsonl

# 5. Generate CSV report (Call the report function)
echo "[*] Generating Statistics Report..."
sage joc_pipeline_rich_log_v2.sage report 31bit

echo "[SUCCESS] Done! Check 'official_31bit.jsonl' and 'summary_31bit.csv'."
