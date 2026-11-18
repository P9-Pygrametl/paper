#import "@preview/cetz:0.3.4": canvas, draw
== Benchmark Harness
We considered pyperf @pyperf, pytest-benchmark @pytest-benchmark and perftester @perftester, but used our own harness. A run may be a single JVM process or a parent with several workers, so we need wall time, CPU time and peak PSS for the whole process tree. CPU time shows whether a speedup comes from using more cores or from doing less work, and PSS apportions shared pages so that the tree total does not double-count them. pytest-benchmark and perftester measure Python callables, and perftester documents that it does not support multiple threads or processes @perftester. pyperf's command mode times an external program and reports its maximum RSS @pyperf, but not PSS or tree-wide CPU time. None of the tools reset the warehouse or check that implementations produce the same output, so a wrapper would still leave the experiment-specific work as custom code.

Our harness is a small Python package, `run_all`, that runs every implementation as a fresh subprocess. This lets CPython, free-threaded CPython and Jython be compared in one invocation, and no interpreter state carries over between runs. @fig:harness shows the procedure. Source data is generated once per page size, and the warehouse is reset before each run by re-applying the schema. For each run we record wall time, CPU time including all child processes, and peak PSS in SQLite. Peak PSS is the maximum over time of the PSS summed across the process tree, sampled every 50 ms. The PostgreSQL containers are not included.

#figure(
  canvas(length: 1cm, {
    import draw: *

    let node(y, name, body, module) = {
      rect((-2.6, y - 0.35), (1.6, y + 0.35), name: name, stroke: 0.6pt)
      content((-0.5, y), text(size: 9pt, body))
      content((2.7, y), text(size: 8pt, fill: gray.darken(50%), raw(module)))
    }

    node(0, "gen", [Generate source data], "main")
    node(-1.2, "reset", [Reset warehouse], "main")
    node(-2.4, "run", [Run and measure subprocess], "measure")
    node(-3.6, "check", [Validate run], "validation")
    node(-4.8, "save", [Save result], "results")
    node(-6.0, "oracle", [Compare with oracle], "validation")

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
