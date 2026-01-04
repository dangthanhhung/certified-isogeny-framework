import sys
import time
import csv
from multiprocessing import Pool, cpu_count
from sage.all import *

# --- CONFIGURATION ---
# Powers of 2 for plotting logarithms
TARGET_POWERS = [10, 11, 12, 13, 14, 15, 16, 17, 18]
PRIMES = [next_prime(2**k) for k in TARGET_POWERS]
SAMPLES = 100000 # 100k 

def check_nd_cert_criteria(args):
    p, seed, g = args
    F = GF(p); R = F['x']; x = R.gen()
    set_random_seed(seed)
    
    # Generate a random curve of order 2g+1
    deg = 2*g + 1
    coeffs = [F.random_element() for _ in range(deg)]
    f = x^deg + sum(c*x^i for i, c in enumerate(coeffs))
    
    # 1. Check Singular
    if f.discriminant() == 0: return "REJECT"
    
    # 2. Check Ordinary (Naive Oracle)
    try:
        # compute Hasse-Witt Matrix g x g
        # H_ij = coeff x^(i*p - j) in f^((p-1)/2)
        exponent = (p - 1) // 2
        h = f**exponent
        c = h.list()
        # Padding
        target_len = g * p + 1
        while len(c) <= target_len: c.append(0)
        
        # Function to get safety coefficient
        def val(k): return c[k] if 0 <= k < len(c) else 0
        
        # Construct the HW matrix
        H = Matrix(GF(p), g, g, lambda i, j: val((i+1)*p - (j+1)))
        
        if H.rank() < g: return "REJECT" # Non-Ordinary
        return "ACCEPT"
    except:
        return "ERROR"

def run_simulation_parallel():
    filename = "density_results_nd_cert.csv"
    print(f"--- DENSITY SIMULATION (Genus 2 & 3) ---")
    
    with open(filename, "w") as f:
        # Add genus column
        f.write("Genus,Prime,Log2P,Samples,RejectCount,Rate,Theoretical_1_P\n")
        
        pool = Pool(cpu_count())
        
        # Run for Genus 2 then move on to Genus 3
        for g in [2, 3]:
            print(f"\n[+] Simulating Genus {g}...")
            for p in PRIMES:
                t0 = time.time()
                
                # Task includes g parameter
                tasks = [(p, i, g) for i in range(SAMPLES)]
                results = pool.map(check_nd_cert_criteria, tasks)
                
                rejects = results.count("REJECT")                
                
                rate = float(rejects / SAMPLES)
                theory = float(1.0 / p)
                log2p = float(log(p, 2))
                
                line = f"{g},{p},{log2p:.2f},{SAMPLES},{rejects},{rate:.8f},{theory:.8f}"
                f.write(line + "\n")
                f.flush()
                
                print(f"  -> p={p:<6} | Rejects={rejects:<4} | Rate={rate:.6f} | Time={time.time()-t0:.1f}s")

if __name__ == "__main__":
    run_simulation_parallel()
