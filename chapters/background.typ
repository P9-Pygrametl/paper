#show list: set par(justify: false)
#show list: set text(hyphenate: false)

= Background
This section introduces `pygrametl`, outlines the challenges of parallelizing @ETL workloads in Python, and describes how `pygrametl` currently supports parallel execution via `multiprocessing` in CPython and multithreading in Jython.
== Pygrametl

`pygrametl` is an open-source Python framework for programmatic @ETL development @Pygrametl2011. Unlike GUI-based @ETL tools such as @PDI @PentahoDataIntegration, `pygrametl` expresses workflows directly in Python, giving developers programmatic control and access to Python's ecosystem. Rows are represented uniformly as Python `dict` objects mapping attribute names to values, so pipeline stages are not coupled to a fixed schema.

`pygrametl` organizes its abstractions in three layers:

- *Database Connectivity:* `ConnectionWrapper` wraps PEP 249 database connections behind a uniform @RDBMS interface, translating `pyformat` SQL parameters into the target driver's native style and caching translated statements.
- *Data Extraction:* Stream extractors such as `SQLSource` and `CSVSource` are standard Python iterables that yield row dictionaries and can be chained with wrappers that filter, join, or transform rows on the fly.
- *Dimensional Loading:* The core table abstractions `Dimension` and `FactTable` model star and snowflake schemas through `lookup`, `insert`, and `ensure`. To reduce database overhead and maintain history, `CachedDimension` keeps keys in memory, `BatchFactTable` and `BulkFactTable` support batch and file-based bulk loading, and `SlowlyChangingDimension` automates Type 1 and Type 2 versioning.

== Parallelism in Python <parallelism>

@ETL pipelines combine I/O-bound database and file operations with CPU-bound row transformations and cache lookups, requiring both task and data parallelism to use multi-core CPUs @Pygrametl2011. GUI-based tools such as @PDI make this comparatively easy, as workflows are declared as a directed graph of discrete steps that exchange rows over channels, so the runtime can execute independent steps concurrently. In standard CPython, the @GIL allows only one thread to execute Python bytecode at a time @Python315GILDocs. Blocking OS I/O and some C extensions release the @GIL, but CPU-bound Python work is serialized within a process.

`pygrametl` provides these abstractions to coordinate a parallel @ETL execution @Pygrametl2011:

- *Shared Database Connectivity:* `shareconnectionwrapper` spawns a `ConnectionWrapper` in a dedicated worker, so workers share one transactionally safe connection.
- *Parallel Data Extraction:* `ProcessSource` reads and transforms source rows in a separate worker over a bounded queue.
- *Decoupled Dimensional Loading:* `DecoupledDimension` and `DecoupledFactTable` run table operations in dedicated workers, buffer batched calls to amortize @IPC overhead, and return `FutureResult` placeholders that consuming tables resolve before use.
- *Partitioned Table Execution:* `DimensionPartitioner` and `FactTablePartitioner` distribute bottleneck tables across multiple decoupled workers using hash partitioning and blocks of unique keys allocated by a shared `getsharedsequencefactory`.

=== Multiprocessing <multiprocessing>

`pygrametl` implements the abstractions above with `multiprocessing`, using processes to bypass the @GIL while keeping sequential @ETL logic largely unchanged @Pygrametl2011. It explicitly selects the `fork` the spawning method. A new process created as a copy of the caller, including its address space and open file descriptors, so workers inherit the table objects and caches, and memory pages are shared copy-on-write until either process writes to them. In practice, this sharing is limited because CPython updates reference counts whenever these inherited objects are accessed, which copies the affected pages, so memory use grows with the number of processes.

`fork` avoids re-importing modules in the new process, but it is unavailable on Windows, so `pygrametl` is restricted to UNIX-like systems. Because processes do not share memory, row dictionaries and surrogate keys must be serialized and sent over @IPC queues.

=== Jython <jython>

`pygrametl` also supports multithreading through Jython, which runs the same abstractions on the @JVM without a @GIL, so threads share row dictionaries and dimension caches directly in memory @Pygrametl2011. A compatibility layer, `jythonmultiprocessing`, implements `Process`, `Queue`, and `JoinableQueue` with threads and in-memory queues, so the same code runs unchanged. `JDBCConnectionWrapper` adapts @JDBC drivers to the `ConnectionWrapper` interface, disables auto-commit, caches prepared statements, and translates pyformat parameters to JDBC placeholders.

Even though threads share memory, stages still exchange rows through queues as in the multiprocessing backend, so Jython avoids serialization but still pays for queue traffic.

Jython is based on Python 2.7, and Jython 3 was never released, whereas current `pygrametl` development targets Python 3 and is phasing out Python 2 support. Jython therefore cannot use modern Python 3 features or active CPython database drivers, and large batch sizes on the @JVM risk promoting short-lived row objects into the tenured heap and triggering expensive garbage collection pauses.
