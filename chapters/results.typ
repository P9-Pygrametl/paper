= Results

// At 100 pages, the sequential CPython baseline takes 113.5 s. Multiprocessing reduces this to 50.8 s, and with asynchronous extraction to 50.6 s. The corresponding free-threaded multiprocessing variants take 44.2 s and 43.8 s. These results show that asynchronous extraction alone does not shorten the sequential workflow materially; its improvement is modest when combined with multiprocessing. Free-threaded workers are faster still and, compared with multiprocessing on 3.15, use less memory (189 vs 311 MB) and slightly less total CPU time (81 vs 85 s).

// The largest gains come from reducing database round trips. Pipeline mode brings the sequential workflow to 36.8 s, and combining it with multiprocessing and free-threading reduces execution time to 22.8 s and 17.5 s, respectively. The next section examines these pipeline results in detail, including the reliability issue observed in the free-threaded variant.

// The results support the distinction between worker parallelism and database wait time. At 100 pages, pipelining reduces sequential execution time from 113.6 s to 36.8 s, about a 3.1x speedup, while total CPU time falls from 44.7 s to 31.9 s. This indicates that the sequential gain comes from doing less waiting, not from using more CPU. Adding multiprocessing reduces wall time to 22.8 s; using free-threaded workers reduces it to 17.5 s, about 6.5x faster than the sequential baseline. These parallel pipeline variants use about 1.6 and 1.5 times the baseline CPU time, respectively, in exchange for lower wall time.

// At 100 pages, pipelining reduces sequential execution time from 113.5 s to 36.0 s, a 3.2x speedup, while total CPU time falls from 44.6 s to 31.7 s. This indicates that the gain comes from less waiting, not from more CPU. Adding multiprocessing reduces wall time to 22.1 s, and free-threaded workers to 15.2 s, 7.5x faster than the baseline. These parallel variants use about 1.6 and 1.5 times the baseline CPU time in exchange for lower wall time.

#include "../figures/results-summary.typ"

@tab:summary compares all implementations against the sequential CPython baseline, which takes 113.5 s at 100 pages.

Without pipelining, parallel workers roughly halve the execution time. Multiprocessing reduces the baseline to 50.8 s (2.24x), at the cost of about three times the memory (311 MB peak PSS against 105 MB). Free-threaded workers are faster still at 44.2 s (2.57x), and use less memory than multiprocessing (189 MB), which is consistent with threads sharing memory instead of copying it. Free-threading only pays off with parallel workers: sequential code is about 10% slower on the free-threaded build (125.3 s). The parallel Jython implementation takes 49.8 s (2.28x), comparable to CPython multiprocessing, but it peaks at 3.8 GB of memory and 325% CPU utilisation, against 167% for CPython multiprocessing. Free-threaded CPython is faster than parallel Jython and uses 189 MB instead of 3.8 GB. Sequential Jython is also faster than sequential CPython (63.6 s, 1.79x).

Asynchronous extraction has little effect. On its own it shortens the sequential workflow by about 7% (105.6 s), less than the baseline's run-to-run standard deviation of 14.1 s, and it makes no measurable difference when combined with multiprocessing (50.6 s) or free-threading (43.8 s).

The largest gains come from reducing database round trips. Pipeline mode brings the sequential workflow to 36.0 s (3.16x), and combining it with multiprocessing and free-threading reduces execution time to 22.1 s (5.13x) and 15.2 s (7.45x). Every pipelined variant is faster than every non-pipelined one, and the pipelined variants are also far more stable, with standard deviations of at most 0.2 s against 14.1 s for the baseline.

Pipelining also keeps the CPU busy. For the sequential workflow, CPU utilisation rises from 40% to 88% because the client no longer idles while waiting for replies, and total CPU time falls from 44.6 s to 31.7 s. Adding parallel workers raises total CPU time to 69.9 s with multiprocessing and 65.7 s with free-threading, about 1.6 and 1.5 times the baseline. Since pipelined sequential execution uses less CPU time than the baseline, this increase comes from the workers and not from pipelining.

#include "../figures/results-chart.typ"

@fig:time shows how execution time and total CPU time develop with page size. Execution time grows roughly linearly for all variants, and the pipelined variants rank first, second and third at every page size, with speedups that stay roughly constant (3.0 to 3.2x, 4.8 to 5.1x and 6.7 to 7.5x). In the CPU time panel, pipelined sequential execution is the only variant with substantially lower CPU time than the baseline, while the parallel variants all use more.
