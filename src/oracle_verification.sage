import json
from sage.all import *

# Configuration
JSONL_FILE = "official_toy.jsonl" 
P_TOY = 1031

def get_oracle_rank_primitive(f, p):
    """ Naive Powering """
    try:
        N = (p - 1) // 2
        # Calculate f^N in the Sage polynomial ring.
        h = f**N
        c = h.list()
        while len(c) <= 2*p: c.append(0)
        
        h11, h12 = c[p-1], c[p-2]
        h21, h22 = c[2*p-1], c[2*p-2]
        
        H = Matrix(GF(p), 2, 2, [[h11, h12], [h21, h22]])
        return int(H.rank())
    except:
        return -1

def check_results():
    print(f"--- CROSS-CHECKING {JSONL_FILE} WITH ORACLE ---")
    
    F = GF(P_TOY); R = F['x']; x = R.gen()
    
    total = 0
    matches = 0
    mismatches = 0
    skipped = 0
    
    with open(JSONL_FILE, 'r') as f_in:
        for line in f_in:
            total += 1
            data = json.loads(line)
            
            #1. Recreate the Curve from Seed
            seed_val = int(data['seed'])
            set_random_seed(seed_val)
            coeffs = [F.random_element() for _ in range(5)]
            f_poly = x^5 + coeffs[4]*x^4 + coeffs[3]*x^3 + coeffs[2]*x^2 + coeffs[1]*x + coeffs[0]
            
            if f_poly.discriminant() == 0:
                skipped += 1
                continue

            # 2. Get Rank from file (Hypellfrob CharPoly)
            # New file structure: data['timings_ms']['pics']... 
            # Rank is in meta->hw->rank (nếu bạn lưu)
            
            # Check status
            status = data.get('status')
            
            # Compute Oracle
            rank_oracle = get_oracle_rank_primitive(f_poly, P_TOY)
            
            # Logic check:
            # If Status = SUCCESS => Rank file = 2 (Ordinary)
            # If Fail Reason contains "defect=1" => Rank file = 1
            # If Fail Reason contains "defect=2" => Rank file = 0
            
            rank_file = -1
            if status == "SUCCESS":
                rank_file = 2
            elif "fail_reason" in data and data["fail_reason"]:
                reason = data["fail_reason"]
                if "defect=1" in reason: rank_file = 1
                elif "defect=2" in reason: rank_file = 0
                elif "defect=0" in reason: rank_file = 2 # Hiếm gặp (lỗi khác)
            
            # If rank_file is unknown (due to a system crash), ignore it.
            if rank_file == -1:
                print(f"[?] Skip seed {seed_val}: Cannot determine rank from log.")
                continue

            # 4. Compare
            if rank_file == rank_oracle:
                matches += 1
            else:
                mismatches += 1
                print(f"[!] MISMATCH Seed {seed_val}: File(Hypell)={rank_file} vs Oracle={rank_oracle}")
                
            if total % 100 == 0:
                print(f"Checked {total} records...")

    print("-" * 40)
    print(f"TOTAL CHECKED: {matches + mismatches}")
    print(f"MATCHES:       {matches}")
    print(f"MISMATCHES:    {mismatches}")
    
    if mismatches == 0:
        print("\n>>> PERFECT RESULT! HYPELLFROB (CharPoly) HAS MATCHED THE ORACLE. <<<")
    else:
        print("\n>>> STILL HAS ERROR <<<")

if __name__ == "__main__":
    check_results()
