#!/bin/bash

# 1. Dọn dẹp
echo "[*] Cleaning up old smoke files..."
rm -f part_*.jsonl official_smoke.jsonl

# 2. CHẠY PARALLEL (Smoke 20k)
# P = 65537
echo "[*] Starting Smoke Execution (N=20,000)..."

parallel --bar -j 8 sage joc_pipeline_rich_log_v2.sage batch smoke {1} 2500 {#} ::: 0 2500 5000 7500 10000 12500 15000 17500

# 3. Gộp kết quả
echo "[*] Merging output files..."
cat part_*.jsonl > official_smoke.jsonl
rm part_*.jsonl

echo "[SUCCESS] Done! Data saved to 'official_smoke.jsonl'."
