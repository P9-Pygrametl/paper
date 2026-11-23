#import "@preview/cetz:0.3.4": canvas, draw
== Benchmark Harness
We considered pyperf @pyperf, pytest-benchmark @pytest-benchmark and perftester @perftester, but used our own harness. A run may be a single JVM process or a parent with several workers, so we need wall time, CPU time and peak PSS for the whole process tree. CPU time shows whether a speedup comes from using more cores or from doing less work, and PSS allocates shared pages proportionally so that the tree total does not double-count them. pytest-benchmark and perftester measure Python callables, and perftester documents that it does not support multiple threads or processes @perftester. pyperf's command mode times an external program and reports its maximum RSS @pyperf, but not PSS or tree-wide CPU time. None of the tools reset the warehouse or check that implementations produce the same output, so a wrapper would still leave the experiment-specific work as custom code. We therefore built our own harness.

Our harness, the small Python package `run_all`, runs each implementation as a fresh subprocess. This lets CPython, free-threaded CPython, and Jython be compared in one invocation without carrying interpreter state between runs. @fig:harness shows the procedure. Source data is generated once per page size, and the warehouse is reset before each run by dropping and recreating its schema. For each run, we record wall time, CPU time including all child processes, and peak PSS and store it in SQLite. Peak PSS is the maximum sampled sum of process-tree PSS, with samples taken every 50 ms. The PostgreSQL containers are not included.

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

These parameters depend on workload size. A bulk size larger than the fact table cannot be distinguished from a smaller one that fits in a single load, and the queue and batch sizes determine how many rows remain in flight. We tune at 100 pages (4.5 million fact rows), where every level is observable, and use the selected configuration for the smaller page sizes.

A full Cartesian product of all levels would require 2,432 configurations across all modes, or 4,864 timed runs at two repetitions. We use coordinate descent instead. Each pass visits the parameters in shuffled order. For one parameter, every level is run twice with the other parameters fixed, and the level with the lowest median wall time is selected. The search stops when a pass changes no parameter, or after three passes. We then select, from all configurations measured at least four times, the one with the lowest median wall time. The selected configuration is rerun twice to obtain a final median; these runs do not alter the selection. Across all modes, the procedure requires at most 996 timed runs for the search plus 26 for the final measurement.

Each trial follows the benchmark harness procedure, using a fresh subprocess and a reset warehouse. Wall time is the selection objective. Coordinate descent is a local search: it finds a strong configuration along the tested parameter directions but does not establish a global optimum.

Configuration choice is mode-dependent. Across the sequential and sequential async modes, the per-mode spread between the best and worst tested configuration ranges from 43% to 75%, with a median of 55%. The six decoupled CPython modes range from 10% to 27% (median 19%), the two Jython modes from 6% to 12% (median 9%), and pipeline sequential is 9%. These values are exploratory: each configuration was measured twice per sweep, not in a controlled paired experiment. The per-mode values are given in @tab:tuning-sensitivity.
