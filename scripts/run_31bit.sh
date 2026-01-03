#!/bin/bash

# 1. Cài đặt GNU Parallel (nếu chưa có)
if ! command -v parallel &> /dev/null; then
    echo "Installing GNU Parallel..."
    sudo apt-get update && sudo apt-get install -y parallel
fi

# 2. Dọn dẹp file rác cũ
echo "[*] Cleaning up old files..."
rm -f part_*.jsonl official_31bit.jsonl

# 3. CHẠY PARALLEL (QUAN TRỌNG NHẤT)
# -j 6: Chạy tối đa 6 tiến trình cùng lúc (Tiết kiệm RAM cho OS)
# --bar: Hiển thị thanh tiến trình
# 8 jobs: 0, 2500, 5000... (Mỗi job xử lý 2500 curves -> Tổng 20,000)
# Mỗi job mất khoảng 10-15 phút. Vì chạy 6 luồng, tổng thời gian ~ 1.5h.

echo "[*] Starting Parallel Execution (31-bit)..."

parallel --bar -j 6 sage joc_pipeline_rich_log_v2.sage batch 31bit {1} 2500 {#} ::: 0 2500 5000 7500 10000 12500 15000 17500

# 4. Gộp kết quả
echo "[*] Merging output files..."
cat part_*.jsonl > official_31bit.jsonl
rm part_*.jsonl

# 5. Sinh báo cáo CSV (Gọi hàm report)
echo "[*] Generating Statistics Report..."
sage joc_pipeline_rich_log_v2.sage report 31bit

echo "[SUCCESS] Done! Check 'official_31bit.jsonl' and 'summary_31bit.csv'."
