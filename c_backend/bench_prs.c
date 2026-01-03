/*
 * PICS-ND Benchmark: Differential PRS Overhead (Micro-benchmarking)
 * Target: Genus 2 Hyperelliptic Curves over 256-bit fields
 * Environment: Google Cloud Compute Engine (or similar Linux VM)
 * Dependencies: FLINT (Fast Library for Number Theory), GMP
 *
 * Usage:
 * 1. Install deps: sudo apt-get install libflint-dev libgmp-dev gcc
 * 2. Compile:      gcc -O3 bench_prs.c -o bench_prs -lflint -lgmp -lm
 * 3. Run:          ./bench_prs
 */

#include <stdio.h>
#include <time.h>
#include <flint/fmpz.h>
#include <flint/fmpz_mod_poly.h>

// Configuration
#define P_BITS 256
#define GENUS 2
#define ITERATIONS 100000 // Loop 100k times for high precision on VM

int main() {
    // ---------------------------------------------------------
    // 1. SETUP PHASE (Initialization)
    // ---------------------------------------------------------
    fmpz_t p;
    fmpz_init(p);

    // Define field prime p = 2^255 - 19 (Standard Curve25519 prime)
    fmpz_set_ui(p, 1);
    fmpz_mul_2exp(p, p, 255);
    fmpz_sub_ui(p, p, 19);

    // Initialize FLINT context for F_p[x]
    fmpz_mod_ctx_t ctx;
    fmpz_mod_ctx_init(ctx, p);

    // Allocate polynomials
    fmpz_mod_poly_t f, Df, G, S, T;
    fmpz_mod_poly_init(f, ctx);
    fmpz_mod_poly_init(Df, ctx);
    fmpz_mod_poly_init(G, ctx); // Result GCD
    fmpz_mod_poly_init(S, ctx); // Coeff 1
    fmpz_mod_poly_init(T, ctx); // Coeff 2

    // Randomize 'f' (Degree 2g + 1 = 5 for Genus 2)
    flint_rand_t state;
    flint_randinit(state);
    fmpz_mod_poly_randtest(f, state, 2 * GENUS + 1 + 1, ctx);
    fmpz_mod_poly_set_coeff_ui(f, 2 * GENUS + 1, 1, ctx); // Make monic

    // Compute initial Derivative Df = f'(x)
    fmpz_mod_poly_derivative(Df, f, ctx);

    printf("==============================================================\n");
    printf("   PICS-ND CERTIFICATION MICRO-BENCHMARK (C/FLINT)            \n");
    printf("==============================================================\n");
    printf("[-] Platform:   Google Cloud VM / Linux x86_64\n");
    printf("[-] Parameter:  p ~ 2^%d, Genus %d\n", P_BITS, GENUS);
    printf("[-] Iterations: %d loops (to average out OS noise)\n", ITERATIONS);
    printf("[-] Operation:  XGCD(f, Df) -> Equivalent to Subres Chain\n");
    printf("--------------------------------------------------------------\n");
    printf("Running benchmark... please wait.\n");

    // ---------------------------------------------------------
    // 2. MEASUREMENT LOOP
    // ---------------------------------------------------------
    clock_t start_time = clock();

    for (int i = 0; i < ITERATIONS; i++) {
        // Perturbation: Slightly change constant term of f to prevent
        // compiler from optimizing away the loop or caching results.
        // Note: Df remains valid as derivative of constant is 0.
        fmpz_mod_poly_set_coeff_ui(f, 0, i, ctx);

        // CORE OPERATION: Extended Euclidean Algorithm
        // This computes the same degree sequence as Subresultants.
        // It is the computational heavy-lifting of the ND certificate.
        fmpz_mod_poly_xgcd(G, S, T, f, Df, ctx);
    }

    clock_t end_time = clock();

    // ---------------------------------------------------------
    // 3. REPORTING
    // ---------------------------------------------------------
    double total_cpu_time_sec = (double)(end_time - start_time) / CLOCKS_PER_SEC;
    double avg_time_us = (total_cpu_time_sec * 1000000.0) / ITERATIONS;

    printf("   [DONE] \n");
    printf("--------------------------------------------------------------\n");
    printf("Total CPU Time:      %.4f seconds\n", total_cpu_time_sec);
    printf("Average Time/Op:     %.4f microseconds (us)\n", avg_time_us);
    printf("--------------------------------------------------------------\n");
    printf("Conclusion: The algebraic certification overhead is ~%.2f us.\n", avg_time_us);
    printf("==============================================================\n");

    // Cleanup
    fmpz_mod_poly_clear(f, ctx);
    fmpz_mod_poly_clear(Df, ctx);
    fmpz_mod_poly_clear(G, ctx);
    fmpz_mod_poly_clear(S, ctx);
    fmpz_mod_poly_clear(T, ctx);
    fmpz_mod_ctx_clear(ctx);
    fmpz_clear(p);
    flint_randclear(state);

    return 0;
}
