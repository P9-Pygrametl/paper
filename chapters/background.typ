= Background

This section introduces `pygrametl`, outlines the challenges of parallelizing ETL workloads in Python, and describes how `pygrametl` currently supports parallel execution via `multiprocessing` in CPython and multithreading in Jython.

== Pygrametl 
`pygrametl` is an open-source Python framework for programmatic @ETL development @Pygrametl2011. Unlike GUI-based ETL tools such as @PDI @PentahoDataIntegration, `pygrametl` expresses workflows directly in Python, giving developers programmatic control and access to Python's ecosystem @Pygrametl2011. Rows are represented uniformly as Python `dict` objects mapping attribute names to values, avoiding rigid schema coupling between pipeline stages.

To structure ETL pipelines, `pygrametl` organizes its abstractions across three layers:
- *Database Connectivity:* A connection wrapper (`ConnectionWrapper`) encapsulates PEP 249 database connections behind a uniform RDBMS interface, translating `pyformat` SQL parameters into the target driver's native style and caching translated statements.
- *Data Extraction:* Stream extractors (such as `SQLSource` and `CSVSource`) act as standard Python iterables yielding row dictionaries, and can be chained with stream-transforming wrappers to filter, join, or transform rows on the fly.
- *Dimensional Loading:* Core table abstractions (`Dimension` and `FactTable`) model star and snowflake schemas by exposing `lookup`, `insert`, and `ensure`. To reduce database overhead and maintain history, `pygrametl` further provides in-memory key caching (`CachedDimension`), batch and file-based bulk loading (`BatchFactTable`, `BulkFactTable`), and automated Type 1 and Type 2 versioning for slowly changing dimensions (`SlowlyChangingDimension`).

== Parallelism in Python <parallelism>

ETL pipelines combine I/O-bound database and file operations with CPU-bound row transformations and cache lookups, requiring both task and data parallelism to utilize multi-core CPUs @Pygrametl2011. In standard CPython, however, achieving multi-threaded parallelism is constrained by the @GIL, as the @GIL permits only one thread to execute Python bytecode at a time @Python315GILDocs. While blocking OS I/O and certain C extensions release the @GIL, CPU-bound Python work is serialized within a single process.

== Multiprocessing <multiprocessing>

To bypass CPython's @GIL while keeping sequential ETL logic largely unchanged, `pygrametl` implements parallelism by using `multiprocessing` @Pygrametl2011. Worker processes are spawned using `fork`, restricting CPython parallelism in `pygrametl` to UNIX-like systems. 

However, isolating workers in separate OS processes removes shared heap memory and introduces three costs for ETL workflows. 
Firstly, database connections cannot be safely shared across processes without breaking single-transaction semantics. Secondly, row dictionaries and surrogate keys must be serialized (e.g., via `pickle`) and transferred across @IPC queues. And lastly, spawning processes can incur memory duplication, as even with `fork` copy-on-write, CPython reference-count updates duplicate shared memory pages on read.

To address these constraints and coordinate multi-process ETL execution, `pygrametl` provides four main abstractions @Pygrametl2011:
- *Shared Database Connectivity:* A connection proxy (`shareconnectionwrapper`) isolates a `ConnectionWrapper` in a dedicated server process so workers share a single transactionally safe database connection.
- *Asynchronous Data Extraction:* A background source wrapper (`ProcessSource`) reads and transforms source rows in a separate process over a bounded queue.
- *Decoupled Dimensional Loading:* Asynchronous table proxies (`DecoupledDimension` and `DecoupledFactTable`) run table operations in dedicated processes, buffering batched calls to amortize IPC overhead and returning placeholder objects (`FutureResult`) that consuming fact workers resolve before insertion.
- *Partitioned Table Execution:* Table partitioners (`DimensionPartitioner` and `FactTablePartitioner`) distribute bottleneck tables across multiple decoupled workers using hash partitioning and disjoint key ranges from a shared sequence factory (`getsharedsequencefactory`).

== Jython <jython>

`pygrametl` also supports multithreading through Jython, which runs on the JVM without a @GIL, allowing threads to share row dictionaries and dimension caches directly in memory @Pygrametl2011. To preserve a unified API across implementations, a threading compatibility layer (`jythonmultiprocessing`) maps `multiprocessing` primitives onto Python's `threading` module, while a JDBC adapter (`JDBCConnectionWrapper`) wraps JDBC drivers behind the `ConnectionWrapper` interface.

However, Jython is based on Python 2.7 (as Jython 3 was never released), whereas current `pygrametl` development targets Python 3 and is phasing out Python 2 support. Consequently, Jython cannot use modern Python 3 features or active CPython database drivers, and large batch sizes on the JVM risk promoting short-lived row objects into the tenured heap and triggering expensive garbage collection pauses.