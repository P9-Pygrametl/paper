== Benchmark Harness

The benchmark harness is a small Python package called `run_all`. It runs every implementation as a fresh subprocess, so CPython, free-threaded CPython and Jython can be compared in one invocation and no state carries over between runs. It measures each run and checks that the resulting warehouse is correct. It has five modules with one responsibility each. `config` lists the implementations. `measure` runs and measures a child process. `validation` inspects the warehouse. `results` stores the outcome in SQLite. `main` ties them together. @fig:harness shows the steps of a benchmark run.

#import "@preview/cetz:0.3.4": canvas, draw

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
  caption: [One benchmark run. Steps inside the dashed box repeat for every implementation and repetition.],
) <fig:harness>

=== Implementation registry

Each implementation is registered as a `Mode` entry in `config` with a name, a runtime label, an interpreter and its arguments. The following entry registers the sequential baseline implementation, `cpygrametl1_db`, on CPython.

```python
Mode(
    "cpygrametl1_db",
    "cpython-3.15",
    CPYTHON,
    ["-m", "shared.cpygrametl1_db"],
    oracle=True,
)
```

A mode can be flagged as an oracle, which makes it the reference run that other runs are validated against. Adding an implementation means adding one entry to the `MODES` list.

// === Measurements, reference to benchmark section

=== Validation

After each run the warehouse is validated. The structural check requires exit code zero, a non-empty fact table and no fact rows that reference a missing dimension row. The deep check compares a fingerprint of the warehouse with that of the oracle. Surrogate keys depend on insertion order, so parallel runs cannot be compared row by row. Instead, one SQL query hashes every dimension row without its surrogate key and every fact row joined to its dimensions on business keys. The hashes are summed with the row count, so the fingerprint does not depend on row order. A run whose fingerprint differs from the oracle is marked invalid.

The validation led us to discover a bug in the forked implementation of multiprocessing in pygrametl, where a commit could overtake queued INSERT statements and leave fact rows without a matching page row. We fixed this before taking the reported measurements.
