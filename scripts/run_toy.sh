#!/bin/bash

# 1. Clean up old trash.
echo "[*] Cleaning up old toy files..."
rm -f part_*.jsonl official_toy.jsonl

# 2. RUN PARALLEL (Toy)
# Total 20,000 samples. Divided into 8 streams. Each stream has 2500 samples.
# Toy runs very fast (with Oracle check).
echo "[*] Starting Toy Execution (N=20,000)..."

parallel --bar -j 8 sage joc_pipeline_rich_log_v2.sage batch toy {1} 2500 {#} ::: 0 2500 5000 7500 10000 12500 15000 17500

# 3. Merge results
echo "[*] Merging output files..."
cat part_*.jsonl > official_toy.jsonl
rm part_*.jsonl

echo "[SUCCESS] Done! Data saved to 'official_toy.jsonl'."
