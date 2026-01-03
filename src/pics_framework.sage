import time, csv, json, sys, statistics
from multiprocessing import cpu_count
from sage.all import *
from sage.schemes.hyperelliptic_curves.hypellfrob import hypellfrob

# RAM an toàn cho 1 process (Khi chạy Parallel OS)
# 2GB là đủ cho N=1
PARI_STACK_PER_WORKER = 2 * 1024 * 1024 * 1024 

SCENARIOS = {
    # Nâng cấp Toy lên 20k
    "toy":   {"p": 1031, "N": 20000, "check_oracle": True, "desc": "Verification (High Coverage)"},
    
    # Nâng cấp Smoke lên 20k
    "smoke": {"p": 65537, "N": 20000, "check_oracle": True, "desc": "Stability Check"},
    
    # Giữ nguyên 31-bit
    "31bit": {"p": 2147483647, "N": 20000, "check_oracle": False, "desc": "Production Benchmark"},
    
    # Bỏ 40-bit (như đã chốt)
    "40bit": {"p": 1099511627791, "N": 20000, "check_oracle": False, "desc": "Production"}
}

def sage_to_python(obj):
    if hasattr(obj, "item"): return obj.item()
    if hasattr(obj, "is_integer") and obj.is_integer(): return int(obj)
    if isinstance(obj, (int, float, str, bool, type(None))): return obj
    return str(obj)

# --- BACKEND QUAN TRỌNG (N=1 CHO TỐC ĐỘ) ---
def get_rank_hypellfrob_detailed(f, p):
    try:
        R_Z = PolynomialRing(ZZ, 'x')
        f_z = R_Z(f.list())
        
        # --- CẤU HÌNH CHO 31-BIT ---
        # N=1: Nhanh nhất (1.7s/curve). Đủ chính xác cho rank.
        # N=5: Quá chậm (144s/curve). Không dùng cho 31bit.
        PRECISION = 5 
        
        M_padic = hypellfrob(p, PRECISION, f_z)
        M = Matrix(GF(p), 4, 4, [GF(p)(c) for r in M_padic for c in r])
        poly = M.charpoly()
        coeffs = poly.list()
        
        if coeffs[2] != 0: rank = 2
        elif coeffs[3] != 0: rank = 1
        else: rank = 0
        
        return {"rank": rank, "charpoly": str(poly), "method": f"hypellfrob_n{PRECISION}"}
    except Exception as e: return {"rank": -2, "error": str(e)}

def compute_prs_detailed(f):
    df = f.derivative()
    sres = f.subresultants(df)
    deg_map = {poly.degree(): poly for poly in sres if poly != 0}
    profile = sorted(deg_map.keys(), reverse=True)
    return {"min_deg": int(profile[-1]) if profile else -1, "deg_map": deg_map, "full_profile": [int(d) for d in profile]}

def run_step(seed, p, check_oracle):
    try: 
        from sage.libs.pari.all import pari
        pari.allocatemem(PARI_STACK_PER_WORKER)
    except: pass

    F = GF(p); R = F['x']; x = R.gen()
    set_random_seed(seed)
    coeffs = [F.random_element() for _ in range(5)]
    f = x^5 + coeffs[4]*x^4 + coeffs[3]*x^3 + coeffs[2]*x^2 + coeffs[1]*x + coeffs[0]

    entry = {"seed": int(seed), "p": int(p), "f_coeffs": [int(c) for c in coeffs], "status": "FAIL", "pics": {}}
    t0 = time.time()

    try:
        if f.discriminant() == 0:
            entry["status"] = "REJECT_G0"
        else:
            # 1. PRS
            prs_res = compute_prs_detailed(f)
            entry["pics"]["dprs"] = prs_res["full_profile"]
            
            # 2. HW
            hw_res = get_rank_hypellfrob_detailed(f, p)
            entry["pics"]["hw"] = hw_res
            rank = hw_res["rank"]
            
            # 3. Check
            defect = 2 - rank
            min_deg = prs_res["min_deg"]
            
            if min_deg != defect:
                entry["status"] = "REJECT_G2"
                entry["fail_reason"] = f"Mismatch Rank{rank}-PRS{min_deg}"
            elif defect in prs_res["deg_map"] and prs_res["deg_map"][defect].degree() == defect:
                entry["status"] = "SUCCESS"
                entry["pics"]["ok"] = True
                entry["pics"]["kernel_S"] = str(prs_res["deg_map"][defect])
            else:
                entry["status"] = "FAIL_KERNEL"
    except Exception as e:
        entry["status"] = "CRASH"; entry["error"] = str(e)

    entry["time_ms"] = (time.time() - t0) * 1000
    return entry

# --- BATCH RUNNER CHO GNU PARALLEL ---
def run_batch_mode(mode, start_seed, count, worker_id):
    conf = SCENARIOS[mode]
    p = conf["p"]
    filename = f"part_{worker_id}.jsonl"
    print(f"[Worker {worker_id}] Processing {count} curves...")
    
    with open(filename, "w") as f:
        for i in range(count):
            res = run_step(start_seed + i, p, conf["check_oracle"])
            f.write(json.dumps(sage_to_python(res)) + "\n")
            f.flush() # Quan trọng để không bị treo log
    print(f"[Worker {worker_id}] Done.")

def regenerate_report(mode):
    jsonl_file = f"official_{mode}.jsonl"
    csv_file = f"summary_{mode}.csv"
    data = []
    try:
        with open(jsonl_file, 'r') as f: data = [json.loads(l) for l in f]
    except: return
    
    n_succ = sum(1 for r in data if r.get("status") == "SUCCESS")
    times = [r.get("time_ms", 0) for r in data]
    t_med = statistics.median(times) if times else 0
    
    with open(csv_file, "w", newline='') as f:
        writer = csv.writer(f)
        writer.writerow(["Scenario", "Prime", "N", "Success_Rate", "Median_Time_ms"])
        writer.writerow([mode, SCENARIOS[mode]["p"], len(data), f"{n_succ/len(data)*100:.2f}", f"{t_med:.2f}"])
    print(f"Report: {csv_file}")

if __name__ == "__main__":
    args = sys.argv
    if len(args) >= 6 and args[1] == "batch":
        run_batch_mode(args[2], int(args[3]), int(args[4]), args[5])
    elif len(args) >= 3 and args[1] == "report":
        regenerate_report(args[2])
    else:
        print("Usage: sage script.sage batch [mode] [start] [count] [id]")
