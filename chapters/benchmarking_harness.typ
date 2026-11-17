== Benchmark Harness

The benchmark harness is a small Python package called `run_all`. It runs every implementation as a subprocess, measures it and checks that the resulting warehouse is correct. It has five modules with one responsibility each. `config` lists the implementations. `measure` runs and measures a child process. `validation` inspects the warehouse. `results` stores the outcome. `main` ties them together. @fig:harness shows the steps of a benchmark run.

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
    node(-3.6, "state", [Query warehouse state], "validation")
    node(-4.8, "check", [Validate run], "validation")
    node(-6.0, "save", [Save result], "results")
    node(-7.5, "oracle", [Compare with oracle], "validation")

    for (a, b) in (
      ("gen", "reset"),
      ("reset", "run"),
      ("run", "state"),
      ("state", "check"),
      ("check", "save"),
    ) {
      line(a + ".south", b + ".north", mark: (end: ">", size: 0.15), stroke: 0.6pt)
    }
    line("save.south", "oracle.north", mark: (end: ">", size: 0.15), stroke: 0.6pt)

    // Loop over repeats and modes
    rect((-2.9, -6.45), (1.9, -0.75), stroke: (dash: "dashed", thickness: 0.5pt))
    content((-3.15, -3.6), angle: 90deg, text(size: 9pt)[for each repeat and mode])
  }),
  caption: [One benchmark run. Steps inside the dashed box repeat for every implementation and repetition. The oracle comparison runs once per page size.],
) <fig:harness>

=== Implementation registry

Each implementation is registered as a `Mode` entry in `config`. An entry gives the implementation name, a runtime label, the interpreter to use and the arguments to pass to it. The following entry registers the multiprocessing implementation on free-threaded CPython.

```python
Mode(
    "cpygrametl2_db",
    "cpython-3.15t",
    CPYTHON_NOGIL,
    ["-m", "shared.cpygrametl2_db"],
)
```

The command that is run is the interpreter followed by the arguments. A mode can also be flagged as an oracle, which marks it as a reference for validation. All 13 combinations of implementation and runtime are listed in one `MODES` list, so adding an implementation means adding one entry.

// === Measurements, reference to benchmark section

=== Subprocess execution

Every run is a fresh subprocess. This is the only way to compare CPython, free-threaded CPython and Jython in one invocation. It also means that no interpreter state or memory carries over from one run to the next. The warehouse is reset before each run by executing the schema file against the warehouse database.

=== Validation

After each run the warehouse is validated in two steps. The structural check requires exit code zero, a non-empty fact table and no fact rows that reference a missing dimension row. The deep check compares the warehouse content with that of an oracle. For each page size, the first run of an oracle mode is the oracle.

Surrogate keys depend on insertion order, so parallel runs cannot be compared row by row. Instead, the deep check hashes every dimension row without its surrogate key. Every fact row is joined to its dimensions and hashed on business keys. The hashes are summed into one fingerprint, which does not depend on row order. A run whose fingerprint differs from the oracle is marked invalid.

=== Result storage

Each run is saved as one row in a SQLite table and committed as soon as it finishes. An interrupted benchmark therefore keeps all completed runs. Invalid runs are stored too, with the reason they failed. The store adds new columns to an existing database automatically, and the table can be exported to CSV.
