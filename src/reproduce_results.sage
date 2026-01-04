import sys
from sage.all import *
from sage.schemes.hyperelliptic_curves.hypellfrob import hypellfrob

# =============================================================================
# REPRODUCER - FINAL VERSION
# =============================================================================
def reproduce_single_case(p, seed):
    print(f"\n{'='*70}")
    print(f"   JoC REPRODUCTION REPORT | p={p} | Seed={seed}")
    print(f"{'='*70}")

    # 1. SETUP & REGENERATE
    F = GF(p); R = F['x']; x = R.gen()
    set_random_seed(seed)
    coeffs = [F.random_element() for _ in range(5)]
    f = x^5 + coeffs[4]*x^4 + coeffs[3]*x^3 + coeffs[2]*x^2 + coeffs[1]*x + coeffs[0]
    
    print(f"\n[1] INPUT CURVE C: y^2 = f(x)")
    print(f"    f(x) = {f}")
    
    if f.discriminant() == 0:
        print("    STATUS: REJECT (Singular)")
        return

    # 2. HASSE-WITT RANK COMPUTATION
    print(f"\n[2] HASSE-WITT RANK COMPUTATION")
    rank_final = -1
    
    # --- A. Tactics for small P (Toy/Smoke): Use Naive Oracle ---
    if p < 100000:
        print("    Method: Oracle Naive Powering (Exact for small p)")
        exponent = (p - 1) // 2
        h = f**exponent
        c = h.list()
        while len(c) <= 2*p + 1: c.append(0)
        
        # Manin Matrix H_ij = h_{ip - j}
        h11, h12 = c[p-1], c[p-2]
        h21, h22 = c[2*p-1], c[2*p-2]
        H = Matrix(GF(p), 2, 2, [[h11, h12], [h21, h22]])
        rank_final = int(H.rank())
        
        print(f"    HW Matrix:\n{H.str()}")
        print(f"    -> RANK: {rank_final}")
        
    # --- B. Strategy for large P (31/40 bits): Use Hypellfrob ---
    else:
        print("    Method: Hypellfrob N=5 + CharPoly (High Performance)")
        try:
            R_Z = PolynomialRing(ZZ, 'x')
            f_z = R_Z(f.list())
            # N=5 để đảm bảo độ chính xác p-adic
            M_padic = hypellfrob(p, 5, f_z)
            M = Matrix(GF(p), 4, 4, [GF(p)(v) for row in M_padic for v in row])
            
            # Use CharPoly (Invariant)
            poly = M.charpoly()
            coeffs_cp = poly.list() # [a0, a1, a2, a3, a4]
            a2 = coeffs_cp[2]
            a1 = coeffs_cp[3]
            
            if a2 != 0: rank_final = 2
            elif a1 != 0: rank_final = 1
            else: rank_final = 0
            
            print(f"    CharPoly: {poly}")
            print(f"    -> RANK: {rank_final}")
        except Exception as e:
            print(f"    [ERROR] Backend crashed: {e}")
            return

    # 3. DIFFERENTIAL PRS
    print(f"\n[3] DIFFERENTIAL PRS PROFILE")
    df = f.derivative()
    sres = f.subresultants(df)
    deg_map = {poly.degree(): poly for poly in sres if poly != 0}
    profile = sorted(deg_map.keys(), reverse=True)
    min_deg = profile[-1] if profile else -1
    
    print(f"    Profile: {profile}")
    print(f"    Critical Index (MinDeg): {min_deg}")

    # 4. CONSISTENCY CHECK
    print(f"\n[4] VERIFICATION")
    defect = 2 - rank_final
    print(f"    Expected Defect (2 - Rank): {defect}")
    
    if min_deg == defect:
        print("    [PASS] Consistency Check: OK")
        
        # KERNEL EXTRACTION
        if defect in deg_map:
            S_x = deg_map[defect]
            print(f"\n[5] KERNEL POLYNOMIAL S(x)")
            print(f"    S(x) = {S_x}")
            
            # --- CONSTRUCT IMAGE C' ---
            print(f"\n[6] CONSTRUCTING IMAGE CURVE C'")
            if defect == 0: # Ordinary
                print("    Type: Frobenius Isogeny")
                # Tính f_new có hệ số là coeff^p
                coeffs_prime = [c**p for c in f.list()]
                f_prime = R(coeffs_prime)
                print(f"    Image Curve C': y^2 = {f_prime}")
                
                if f == f_prime:
                    print("    (Note: Over GF(p), C' is identical to C due to Fermat's Little Theorem)")
            else:
                print("    Type: Non-Ordinary Isogeny")
                print("    (Explicit equation for C' requires complicated quotient formulas, omitted here)")
            
            print(f"\n>>> FINAL STATUS: SUCCESS <<<")
        else:
            print("    [FAIL] Kernel S(x) Missing despite correct degree profile.")
    else:
        print(f"    [FAIL] Mismatch! Rank={rank_final} implies Defect={defect}, but PRS ends at {min_deg}.")
        print(f"\n>>> FINAL STATUS: REJECT <<<")
    print("="*70 + "\n")

if __name__ == "__main__":
    args = sys.argv
    if len(args) < 3:
        print("Usage: sage joc_repro_official.sage <p> <seed>")
        print("Example: sage joc_repro_official.sage 1031 12345")
    else:
        reproduce_single_case(int(args[1]), int(args[2]))
