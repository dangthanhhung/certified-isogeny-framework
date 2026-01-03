C/FLINT Micro-benchmark for Differential PRS
============================================

This directory contains the C implementation used to benchmark the performance
of the Differential Subresultant Profile (PRS) computation, which is the core
component of the certification logic (ND-Certificate).

Files
-----
- bench_prs.c : The main benchmarking source code.
- Makefile    : Build script (optional usage).

Requirements
------------
To compile and run this benchmark, you need:
1. GCC or Clang compiler.
2. GMP Library (GNU Multiple Precision Arithmetic Library).
   - Ubuntu/Debian: sudo apt-get install libgmp-dev
3. FLINT Library (Fast Library for Number Theory), version 2.9 or later.
   - Ubuntu/Debian: sudo apt-get install libflint-dev
   - Or build from source: https://flintlib.org/

Compilation
-----------
You can compile the benchmark using the following command:

    gcc bench_prs.c -o bench_prs -lflint -lgmp -O3

Alternatively, if you have 'make' installed:

    make

Running the Benchmark
---------------------
Execute the binary:

    ./bench_prs

The program will:
1. Generate random hyperelliptic curves of genus 2 over a 256-bit prime field.
2. Compute the differential subresultant profile for each curve.
3. Repeat the process 100,000 times.
4. Report the average CPU time per operation (in microseconds).

Expected Output
---------------
You should see output similar to:

    [INFO] Prime size: 256 bits
    [INFO] Iterations: 100000
    [INFO] Benchmarking Differential PRS...
    ---------------------------------------
    Average time: 19.67 us
    Total time:   1.967 s