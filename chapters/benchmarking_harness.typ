#import "@preview/cetz:0.3.4": canvas, draw
== Benchmark Harness
We considered pyperf @pyperf, pytest-benchmark @pytest-benchmark and perftester @perftester, but used our own harness. A run may be a single JVM process or a parent with several workers, so we need wall time, CPU time and peak PSS for the whole process tree. CPU time shows whether a speedup comes from using more cores or from doing less work, and PSS allocates shared pages proportionally so that the tree total does not double-count them. pytest-benchmark and perftester measure Python callables, and perftester documents that it does not support multiple threads or processes @perftester. pyperf's command mode times an external program and reports its maximum RSS @pyperf, but not PSS or tree-wide CPU time. None of the tools reset the warehouse or check that implementations produce the same output, so a wrapper would still leave the experiment-specific work as custom code. We therefore built our own harness.

Our harness, is a small Python package, `run_all`, that runs every implementation as a fresh subprocess. This lets CPython, free-threaded CPython and Jython be compared in one invocation, and no interpreter state carries over between runs. @fig:harness shows the procedure. Source data is generated once per page size, and the warehouse is reset before each run by re-applying the schema. For each run we record wall time, CPU time including all child processes, and peak PSS in SQLite. Peak PSS is the maximum over time of the PSS summed across the process tree, sampled every 50 ms. The PostgreSQL containers are not included.

#figure(
  canvas(length: 1cm, {
    import draw: *

    let node(y, name, body) = {
      rect((-2.6, y - 0.35), (1.6, y + 0.35), name: name, stroke: 0.6pt)
      content((-0.5, y), text(size: 9pt, body))
      content((2.7, y), "")
    }

    node(0, "gen", [Generate source data])
    node(-1.2, "reset", [Reset warehouse])
    node(-2.4, "run", [Run and measure subprocess])
    node(-3.6, "check", [Validate run])
    node(-4.8, "save", [Save result])
    node(-6.0, "oracle", [Compare with oracle])

    for (a, b) in (
      ("gen", "reset"),
      ("reset", "run"),
      ("run", "check"),
      ("check", "save"),
      ("save", "oracle"),
    ) {
      line(a + ".south", b + ".north", mark: (end: ">", size: 0.15), stroke: 0.6pt)
    }

    // Loop over repeats and modes
    rect((-2.9, -5.25), (1.9, -0.75), stroke: (dash: "dashed", thickness: 0.5pt))
    content((-3.15, -3.0), angle: 90deg, text(size: 9pt)[for each repeat and mode])
  }),
  caption: [Benchmark procedure for one page size. Steps inside the dashed box repeat for every implementation and repetition.],
) <fig:harness>

After each run the warehouse is validated. The structural check requires exit code zero, a non-empty fact table and no fact rows that reference a missing dimension row. The deep check compares a fingerprint of the warehouse with that of a reference run of the original sequential implementation, the oracle. Surrogate keys depend on insertion order, so parallel runs cannot be compared row by row. Instead, one SQL query returns the row count and the sum of 64-bit hashes of every dimension row without its surrogate key and of every fact row joined to its dimensions on business keys. Since a sum does not depend on row order, neither does the fingerprint. A run whose fingerprint differs from the oracle is marked invalid.

This validation exposed a bug in pygrametl's multiprocessing implementation, where a commit could overtake queued INSERT statements and leave fact rows without a matching page row. We fixed it before taking the reported measurements.

== Parameter Tuning
#figure(
  table(
    columns: (auto, auto),
    align: (left, left),
    table.header[*Parameter*][*Levels*],
    [`batchsize`], [250, 500, 1000, 2500],
    [`queuesize`], [10, 50, 100, 200],
    [`bulksize`], [50k, 100k, 250k, 500k],
    [`fetchsize`], [1k, 5k, 20k, 100k],
    [`JVM heap`], [4g, 6g, 8g],
  ),
  caption: [Tuning levels.],
) <tab:tuning>

The implementations expose four parameters that affect throughput. The batch and queue sizes control how many rows the decoupled dimension and fact tables and the `ProcessSource` keep in flight, the bulk size controls how many fact rows are accumulated before a `COPY`, and the fetch size controls how many source rows are retrieved per database round trip. The Jython implementations additionally take a JVM heap size.

These parameters depend on workload size. A bulk size larger than the fact table cannot be distinguished from a smaller one that still fits in a single load, and the queue and batch sizes determine how many rows remain in flight. We therefore tune at the largest workload, 100 pages (4.5M fact rows), where every level is observable, and keep the resulting profile for the smaller page sizes. This gives each implementation its best observed configuration at the largest scale, not a per-size optimum.

A full Cartesian product of all levels would require 2,432 configurations across all modes, or 7,296 timed runs at three repetitions. We use coordinate descent instead. Each pass visits the parameters in shuffled order. For one parameter, every level is run three times with the other parameters fixed, and the level with the lowest median wall time is selected. The current level is rerun in every comparison, so each level is judged against a contemporaneous reference. The search stops when a pass changes no parameter, or after three passes. The selected configuration is then rerun three times to obtain a median wall time. These runs do not alter the selection. Across all modes, the procedure requires at most 1,494 timed runs plus 39 for this final measurement.

Each trial follows the benchmark harness procedure: a fresh subprocess, a warehouse reset, and measurement of wall time, CPU time and peak PSS. Wall time is the selection objective, while CPU time and peak PSS are recorded for every trial. For Jython the heap is a trade-off, since a larger heap can reduce garbage-collection time but increases peak PSS, so both metrics are reported. The search is local: it finds a strong configuration along the coordinate directions but does not prove a global optimum, and the profile is not retuned for the smaller workloads.
