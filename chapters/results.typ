= Results

// At 100 pages, the sequential CPython baseline takes 113.5 s. Multiprocessing reduces this to 50.8 s, and with asynchronous extraction to 50.6 s. The corresponding free-threaded multiprocessing variants take 44.2 s and 43.8 s. These results show that asynchronous extraction alone does not shorten the sequential workflow materially; its improvement is modest when combined with multiprocessing. Free-threaded workers are faster still and, compared with multiprocessing on 3.15, use less memory (189 vs 311 MB) and slightly less total CPU time (81 vs 85 s).

// The largest gains come from reducing database round trips. Pipeline mode brings the sequential workflow to 36.8 s, and combining it with multiprocessing and free-threading reduces execution time to 22.8 s and 17.5 s, respectively. The next section examines these pipeline results in detail, including the reliability issue observed in the free-threaded variant.

// The results support the distinction between worker parallelism and database wait time. At 100 pages, pipelining reduces sequential execution time from 113.6 s to 36.8 s, about a 3.1x speedup, while total CPU time falls from 44.7 s to 31.9 s. This indicates that the sequential gain comes from doing less waiting, not from using more CPU. Adding multiprocessing reduces wall time to 22.8 s; using free-threaded workers reduces it to 17.5 s, about 6.5x faster than the sequential baseline. These parallel pipeline variants use about 1.6 and 1.5 times the baseline CPU time, respectively, in exchange for lower wall time.

// At 100 pages, pipelining reduces sequential execution time from 113.5 s to 36.0 s, a 3.2x speedup, while total CPU time falls from 44.6 s to 31.7 s. This indicates that the gain comes from less waiting, not from more CPU. Adding multiprocessing reduces wall time to 22.1 s, and free-threaded workers to 15.2 s, 7.5x faster than the baseline. These parallel variants use about 1.6 and 1.5 times the baseline CPU time in exchange for lower wall time.

#include "../figures/results-summary.typ"

@tab:summary shows the results at 100 pages, with the sequential CPython baseline at 113.5 s as reference.

Without pipelining, parallel execution roughly halves the execution time. Multiprocessing provides a speedup of 2.24x, at the cost of about three times the memory, 311~MB peak PSS against 105 MB. Free-threading is faster still with a 2.57x speedup, and uses 189~MB less memory than multiprocessing, which is consistent with threads sharing memory instead of copying it. Free-threading only pays off with parallel execution: sequential code is about 10% slower on the free-threaded build. The parallel Jython workflow provides a speedup of 2.28x, comparable to CPython multiprocessing, but peaks at 3.8~GB of memory and 325% CPU utilisation, against 167% for CPython multiprocessing, while sequential Jython achieves 1.79x.

Asynchronous extraction provides no meaningful gain over its synchronous counterparts. For sequential execution, the speedup shifts from 1.00x to 1.07x on standard CPython and from 0.91x to 0.98x on free-threaded CPython, which is small relative to the baseline's 14.1~s standard deviation. With multiprocessing and free-threading the speedups are virtually unchanged, from 2.24x and 2.57x to 2.24x and 2.59x, respectively.

The largest gains come from reducing database round trips. Pipeline mode speeds up the sequential workflow by 3.16x, and combining it with multiprocessing and free-threading speeds up execution by 5.13x and 7.45x, respectively. Every pipelined variant is faster than every non-pipelined one, and the pipelined variants are also far more stable, with standard deviations of at most 0.2~s against 14.1~s for the baseline.

Across all three execution modes, pipelining multiplies performance by roughly two- to threefold: it increases the speedup of sequential execution from 1.00x to 3.16x, multiprocessing from 2.24x to 5.13x, and free-threading from 2.57x to 7.45x. This gain is consistent with the CPU idling less on database replies, pushing CPU utilisation from 40% to 88% for sequential execution, from 167% to 316% for multiprocessing, and from 184% to 431% for free-threading.

#include "../figures/results-chart.typ"

The headline speedups of the parallel variants partly reflect higher multi-core utilisation rather than proportional per-core efficiency. @fig:time illustrates this trade-off across page sizes for both wall-clock execution time and total CPU time. While execution time grows roughly linearly and the pipelined variants maintain top speedups across all page sizes, 6.7 to 7.5x, 4.8 to 5.1x, and about 3.0 to 3.2x, the total CPU time panel shows that every parallel variant requires more aggregate CPU time than the sequential baseline. Pipelined sequential execution is the only variant that substantially lowers total CPU time, consistent with removing idle waiting without adding parallel coordination overhead.

#include "result_scaling.typ"
