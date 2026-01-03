#!/bin/bash

# 1. Dọn dẹp rác cũ
echo "[*] Cleaning up old toy files..."
rm -f part_*.jsonl official_toy.jsonl

# 2. CHẠY PARALLEL (Toy)
# Tổng 20,000 mẫu. Chia 8 luồng. Mỗi luồng 2500.
# Toy chạy rất nhanh (có Oracle check)
echo "[*] Starting Toy Execution (N=20,000)..."

parallel --bar -j 8 sage joc_pipeline_rich_log_v2.sage batch toy {1} 2500 {#} ::: 0 2500 5000 7500 10000 12500 15000 17500

# 3. Gộp kết quả
echo "[*] Merging output files..."
cat part_*.jsonl > official_toy.jsonl
rm part_*.jsonl

echo "[SUCCESS] Done! Data saved to 'official_toy.jsonl'."
