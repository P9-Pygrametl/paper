#show list: set par(justify: false)
#show list: set text(hyphenate: false)

= Background
This section introduces `pygrametl`, outlines the challenges of parallelizing ETL workloads in Python, and describes how `pygrametl` currently supports parallel execution via `multiprocessing` in CPython and multithreading in Jython.
== Pygrametl

`pygrametl` is an open-source Python framework for programmatic @ETL development @Pygrametl2011. Unlike GUI-based ETL tools such as @PDI @PentahoDataIntegration, `pygrametl` expresses workflows directly in Python, giving developers programmatic control and access to Python's ecosystem. Rows are represented uniformly as Python `dict` objects mapping attribute names to values, so pipeline stages are not coupled to a fixed schema.

`pygrametl` organizes its abstractions in three layers:

- *Database Connectivity:* `ConnectionWrapper` wraps PEP 249 database connections behind a uniform RDBMS interface, translating `pyformat` SQL parameters into the target driver's native style and caching translated statements.
- *Data Extraction:* Stream extractors such as `SQLSource` and `CSVSource` are standard Python iterables that yield row dictionaries and can be chained with wrappers that filter, join, or transform rows on the fly.
- *Dimensional Loading:* The core table abstractions `Dimension` and `FactTable` model star and snowflake schemas through `lookup`, `insert`, and `ensure`. To reduce database overhead and maintain history, `CachedDimension` keeps keys in memory, `BatchFactTable` and `BulkFactTable` support batch and file-based bulk loading, and `SlowlyChangingDimension` automates Type 1 and Type 2 versioning.

== Parallelism in Python <parallelism>

@ETL pipelines combine I/O-bound database and file operations with CPU-bound row transformations and cache lookups, requiring both task and data parallelism to use multi-core CPUs @Pygrametl2011. In standard CPython, the @GIL allows only one thread to execute Python bytecode at a time @Python315GILDocs. Blocking OS I/O and some C extensions release the @GIL, but CPU-bound Python work is serialized within a process.

== Multiprocessing <multiprocessing>

`pygrametl` uses `multiprocessing` to bypass the @GIL while keeping sequential @ETL logic largely unchanged @Pygrametl2011. Workers are spawned with `fork`, which restricts CPython parallelism in `pygrametl` to UNIX-like systems.

Running workers in separate processes removes shared memory and introduces three costs. Furthermore, database connections cannot be safely shared across processes without breaking single-transaction semantics. Also, row dictionaries and surrogate keys must be serialized and sent over @IPC queues. Spawning processes can also duplicate memory, even when using `fork` copy-on-write, CPython reference-count updates copy shared pages on read.

`pygrametl` provides four abstractions to coordinate multi-process @ETL execution @Pygrametl2011:

- *Shared Database Connectivity:* `shareconnectionwrapper` runs a `ConnectionWrapper` in a dedicated server process, so workers share one transactionally safe connection.
- *Asynchronous Data Extraction:* `ProcessSource` reads and transforms source rows in a separate process over a bounded queue.
- *Decoupled Dimensional Loading:* `DecoupledDimension` and `DecoupledFactTable` run table operations in dedicated processes, buffer batched calls to amortize @IPC overhead, and return `FutureResult` placeholders that consuming fact workers resolve before insertion.
- *Partitioned Table Execution:* `DimensionPartitioner` and `FactTablePartitioner` distribute bottleneck tables across multiple decoupled workers using hash partitioning and disjoint key ranges from a shared `getsharedsequencefactory`.

== Jython <jython>

`pygrametl` also supports multithreading through Jython, which runs on the @JVM without a @GIL, so threads share row dictionaries and dimension caches directly in memory @Pygrametl2011. A compatibility layer, `jythonmultiprocessing`, maps `multiprocessing` primitives onto Python's `threading` module, while `JDBCConnectionWrapper` wraps @JDBC drivers behind the `ConnectionWrapper` interface.

Jython is based on Python 2.7, and Jython 3 was never released, whereas current `pygrametl` development targets Python 3 and is phasing out Python 2 support. Jython therefore cannot use modern Python 3 features or active CPython database drivers, and large batch sizes on the @JVM risk promoting short-lived row objects into the tenured heap and triggering expensive garbage collection pauses.
