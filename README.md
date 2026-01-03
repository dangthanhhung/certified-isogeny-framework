# certified-isogeny-framework
Reference implementation for the paper 'A Certified Framework for Deterministic Navigation in Higher-Genus p-Isogeny Graphs'. Includes PICS algorithm, ND certificate, and C/FLINT benchmarks.

**Author:** Hung T. Dang  
**Submission to:** Journal of Cryptology (2025)

## Overview

This repository contains the reference implementation, benchmarking scripts, and experimental data supporting the paper *"A Certified Framework for Deterministic Navigation in Higher-Genus p-Isogeny Graphs"*.

The framework implements two core components:
1.  **PICS (Certified p-Isogeny Step):** A deterministic algorithm to extract the unique Frobenius-compatible kernel from Hasse-Witt invariants.
2.  **ND (Non-Decomposition Certificate):** An algebraic filter to reject decomposable Jacobians based on differential subresultant profiles.

## Repository Structure

```text
.
├── src/                    # Core SageMath implementation
│   ├── pics_framework.sage      # Library: Main implementation of PICS and ND algorithms
│   ├── reproduce_results.sage   # Script: Master script to reproduce key results
│   ├── density_experiment.sage  # Script: Simulation for Proposition 1 (Density analysis)
│   └── oracle_verification.sage # Script: Cross-verification logic against naive oracle
├── c_backend/              # High-performance micro-benchmarks (C/FLINT)
│   ├── bench_prs.c              # C program to benchmark differential PRS computation time
│   └── Makefile                 # Build configuration for the C benchmark
├── scripts/                # Shell scripts to execute end-to-end experiments
│   ├── run_toy.sh               # Run Tier-0 validation (p=1031)
│   ├── run_smoke.sh             # Run Tier-0 validation (p=65537)
│   └── run_31bit.sh             # Run Tier-1 stability test (p=2^31-1)
├── data/                   # Experimental logs and results
│   ├── test_vectors_toy.jsonl   # Generated test vectors for p=1031
│   ├── test_vectors_smoke.jsonl # Generated test vectors for p=65537
│   ├── test_vectors_31bit.jsonl # Generated test vectors for p=31bit
│   ├── summary_toy.csv          # Statistical summary for Toy regime
│   ├── summary_smoke.csv        # Statistical summary for Smoke regime
│   ├── summary_31bit.csv        # Statistical summary for 31-bit regime
│   └── density_results.csv      # Raw data for rejection density scaling
└── utils/                  # Helper utilities
    └── plot_density.py          # Python script to generate Figure 1 from CSV data
