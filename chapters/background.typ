= Background

Developing high-throughput Extract-Transform-Load (ETL) pipelines requires balancing developer productivity with runtime efficiency on multi-core hardware. This section introduces the `pygrametl` framework, examines the concurrency constraints of the Python runtime, and details how `pygrametl` currently achieves parallel execution using `multiprocessing` in CPython and multi-threading in Jython.

== Pygrametl <pygrametl>

`pygrametl` is an open-source Python framework for programmatic ETL development @Thomsen2009pygrametl @Jensen2021pygrametl. Unlike dominant commercial and open-source ETL tools—such as SQL Server Integration Services (SSIS) or Pentaho Data Integration (PDI)—that rely on graphical user interfaces (GUIs) to compose data flows visually, `pygrametl` expresses ETL workflows directly as Python code. While graphical tools provide an accessible visual overview of simple pipelines, implementing complex custom transformations, intricate slowly changing dimension logic, or software engineering practices such as version control and automated unit testing is often cumbersome with visual components. By embedding ETL abstractions into a general-purpose programming language, `pygrametl` allows developers to express arbitrarily complex logic concisely while leveraging Python's standard library and third-party ecosystem @Thomsen2009pygrametl @Jensen2021pygrametl.

At the core of `pygrametl`'s data model, rows are represented uniformly as standard Python `dict` objects mapping attribute names to values. Representing rows as dictionaries avoids rigid schema coupling between pipeline stages, permits heterogeneous attributes across rows, and lets standard Python functions inspect or mutate rows in place without boilerplate marshaling.

To structure ETL pipelines around dimensional data warehouse schemas, `pygrametl` provides modular abstractions across three main layers:

- *Database Connectivity:* `ConnectionWrapper` encapsulates PEP 249 (DB-API 2.0) database connections in CPython, exposing a uniform interface across relational database management systems (RDBMSs). Internally, `pygrametl` writes queries using the `pyformat` parameter style (`%(name)s`) and automatically translates and caches SQL statements to match the target driver's native parameter style (`qmark`, `named`, `format`, or `numeric`).
- *Data Extraction and Stream Transformations (`datasources`):* Data sources are standard Python iterables yielding row dictionaries. Built-in extractors such as `SQLSource`, `CSVSource`, `TypedCSVSource`, and `PandasSource` read from relational databases, delimited files, and DataFrames. Stream-combining and transforming wrappers—including `TransformingSource`, `MappingSource`, `FilteringSource`, `HashJoiningSource`, `MergeJoiningSource`, `UnionSource`, and `RoundRobinSource`—chain together to form lazy, row-at-a-time processing pipelines.
- *Dimension and Fact Table Loaders (`tables`):* `pygrametl` models star and snowflake schemas through dedicated table classes. Basic `Dimension` objects issue direct SQL queries for key lookups and insertions, whereas `CachedDimension` maintains an in-memory cache (optionally prefilled at startup) to eliminate redundant database round-trips. For high-volume ingestion, `BulkDimension`, `CachedBulkDimension`, and `BulkFactTable` stage rows in temporary files and invoke DBMS-specific bulk-loading routines (such as PostgreSQL's `COPY`), while `BatchFactTable` groups insertions into batched `executemany` or multi-row `INSERT` statements. Specialized classes further automate `TypeOneSlowlyChangingDimension`, Type 2 and hybrid Type 1/2 `SlowlyChangingDimension` versioning, `SnowflakedDimension` hierarchies, and `AccumulatingSnapshotFactTable` updates.

All dimension classes expose a consistent interface centered on `lookup` (retrieving a surrogate key from business lookup attributes), `insert` (adding a new dimension member), `ensure` (performing a `lookup` followed by an `insert` if the member is absent), and `scdensure` (handling versioned lookups and updates for slowly changing dimensions). @lst-pygrametl-seq illustrates a typical sequential `pygrametl` pipeline loading a star schema.

```python
import psycopg2
import pygrametl
from pygrametl.datasources import CSVSource, TransformingSource
from pygrametl.tables import CachedDimension, FactTable

conn = pygrametl.ConnectionWrapper(psycopg2.connect("dbname=dw user=dwuser"))

datedim = CachedDimension(
    name="date", key="dateid", attributes=["day", "month", "year"], prefill=True
)
pagedim = CachedDimension(
    name="page", key="pageid", attributes=["url", "domain"], lookupatts=["url"]
)
facttbl = FactTable(
    name="testresults", keyrefs=["pageid", "dateid"], measures=["errors"]
)

def split_date(row):
    row["year"], row["month"], row["day"] = map(int, row["date"].split("-"))

source = TransformingSource(CSVSource(open("results.csv", "r")), split_date)

for row in source:
    row["dateid"] = datedim.ensure(row)
    row["pageid"] = pagedim.ensure(row)
    facttbl.insert(row)

conn.commit()
conn.close()
``` <lst-pygrametl-seq>

== Parallelism in Python <parallelism>

ETL workloads exhibit a mix of I/O-bound and CPU-bound execution phases. Extracting records from files or operational databases, querying dimension tables on cache misses, and flushing fact batches to the target data warehouse incur substantial disk and network latency. Simultaneously, parsing input formats, applying row-level transformations, hashing dictionary keys for dimension caches, and formatting SQL parameters consume CPU cycles. Achieving high throughput on modern multi-core processors requires both *task (pipeline) parallelism*—overlapping extraction, transformation, dimension resolution, and fact loading—and *data parallelism*—partitioning expensive table operations or transformations across multiple concurrent workers @Thomsen2011Parallel.

However, parallelizing Python programs in CPython—the reference and most widely deployed Python implementation—is fundamentally constrained by the Global Interpreter Lock (`@GIL`) @GIL @Python315GILDocs. Because CPython manages object lifetimes through non-atomic reference counting and relies on non-thread-safe internal data structures, the interpreter enforces a process-wide mutex that permits only a single thread to execute Python bytecode at any given moment. Although C extensions and blocking operating system I/O calls (such as socket reads and disk writes) release the `@GIL`, CPU-bound Python bytecode cannot scale across multiple cores within a single CPython process. In an ETL pipeline, threads contending for the `@GIL` serialize Python-level row transformations, cache lookups, and result processing, preventing true parallel speedup and introducing context-switching overhead.

To bypass the `@GIL` in standard CPython, parallel applications traditionally rely on OS-level processes via the `multiprocessing` module, isolating each worker in its own address space with an independent interpreter and `@GIL`. While effective for coarse-grained parallelism, process-based execution introduces significant architectural trade-offs for fine-grained, data-intensive ETL workflows:

- *Serialization and IPC Overhead:* Because processes do not share heap memory, transferring row dictionaries, method arguments, and surrogate keys between workers requires serializing Python objects (typically via `pickle`), copying byte streams across kernel inter-process communication (IPC) channels such as pipes or queues, and deserializing them into newly allocated objects in the receiving process. When individual ETL operations—such as an in-memory `CachedDimension` lookup—take only microseconds, per-row or per-batch serialization can dominate execution time.
- *Process Creation and Memory Duplication:* Spawning OS processes incurs substantially higher startup latency and memory overhead than creating threads. On POSIX systems, `fork` avoids immediate memory copying through OS copy-on-write (CoW) semantics. Yet CPython mutates an object's reference count header (`ob_refcnt`) whenever the object is accessed, causing workers reading shared prefilled caches or lookup tables to trigger CoW page faults and duplicate memory pages over time. Conversely, the `spawn` start method (default on Windows and macOS, and required when parent processes are multithreaded) initializes a fresh Python interpreter from scratch and pickles all state passed to the child.
- *Resource Isolation:* Operating system handles, including database connections and open file descriptors, cannot be safely used concurrently across process boundaries. Parallel workers must either open independent database connections—increasing DBMS resource consumption and forfeiting single-transaction atomicity—or route queries through a dedicated coordinator process.

These limitations have motivated ongoing architectural evolution in Python, including cooperative single-threaded concurrency (`asyncio`) for overlapping I/O without IPC serialization, isolated subinterpreters within a single process (PEP 734) @PEP734 to decouple `@GIL` contention without full OS process duplication, and experimental free-threaded CPython builds (PEP 703) @PEP703 that remove the `@GIL` to enable true shared-memory multi-threading.

== Multiprocessing <multiprocessing>

Standard CPython enforces a `@GIL` @GIL @Python315GILDocs that prevents multiple threads from executing Python bytecode in parallel. The existing parallel implementation of `pygrametl` (provided in `pygrametl.parallel`) therefore uses `multiprocessing` in CPython @Thomsen2011Parallel.

With `multiprocessing`, `pygrametl` starts separate processes using `fork`. Copy-on-write initially shares memory pages—such as preloaded dimension caches and function definitions—between the parent and child processes, though pages are duplicated as processes modify their state and object reference counts. Because Windows does not support `fork`, CPython-based parallel execution in `pygrametl` is restricted to Unix-like platforms (or compatibility layers such as WSL).

`pygrametl` exposes several high-level constructs to parallelize all three ETL phases with minimal modifications to sequential code @Thomsen2011Parallel:

- *Parallel Extraction (`ProcessSource`):* Wrapping any iterable data source (including chained `TransformingSource` pipelines) in a `ProcessSource` spawns a dedicated worker process that reads and transforms rows in the background, pushing row batches (defaulting to `batchsize=500`) onto a bounded queue (`queuesize=20`) for consumption by the parent process.
- *Decoupled Tables (`DecoupledDimension` and `DecoupledFactTable`):* To distribute table lookups and insertions, dimensions and fact tables are wrapped in `Decoupled` proxy objects, each running its underlying table instance in a dedicated worker process. When the parent process invokes a method such as `ensure` or `scdensure` on a `DecoupledDimension`, the proxy buffers batched method calls (`batchsize=500`) onto an input queue (`queuesize=200`) and immediately returns a `FutureResult` placeholder. When a `DecoupledFactTable` configured with `consumes` receives a row containing such placeholders, its worker process fetches the resolved surrogate keys from the producing dimension process's result queue before inserting the fact into the underlying table, allowing the main process to continue without blocking on foreign-key resolution @Thomsen2011Parallel.
- *Table Partitioning (`DimensionPartitioner` and `FactTablePartitioner`):* When a single dimension (such as a large slowly changing dimension) or fact table becomes a bottleneck, multiple `Decoupled` instances can operate in parallel behind a `DimensionPartitioner` or `FactTablePartitioner`. Rows are routed across parts using a hash function (defaulting to hashing `lookupatts` for dimensions or summing `keyrefs` for facts). To prevent surrogate key collisions across parallel dimension workers without per-row synchronization, `getsharedsequencefactory` dispenses disjoint ranges of integer IDs (defaulting to intervals of 5,000) to each worker's `idfinder` @Thomsen2011Parallel.
- *Parallel Functions (`@splitpoint` and `createflow`):* Compute-intensive user-defined transformations can also be parallelized using the `@splitpoint` decorator—which executes calls across one or more dedicated worker processes synchronized via `endsplits()`—or `createflow`, which links a sequence of functions into a multi-process pipeline passing batches of rows from stage to stage @Thomsen2011Parallel.
- *Shared Database Connections (`shareconnectionwrapper`):* Since PEP 249 database connections cannot be shared directly across processes—and opening separate connections per worker compromises transactional atomicity—`shareconnectionwrapper` spawns a dedicated server process holding the `ConnectionWrapper` and provides each worker with a `SharedConnectionWrapperClient` via `.copy()` @Thomsen2011Parallel. All SQL statements, fetches, commits, and registered user-defined bulk-loading functions (`userfuncs`) are queued and executed sequentially in the server process, preserving single-transaction ACID guarantees.

@lst-pygrametl-mp shows how the sequential pipeline from @lst-pygrametl-seq is parallelized using decoupled tables and a shared connection wrapper.

```python
import psycopg2
import pygrametl
from pygrametl.datasources import CSVSource, ProcessSource, TransformingSource
from pygrametl.parallel import shareconnectionwrapper
from pygrametl.tables import (
    CachedDimension,
    DecoupledDimension,
    DecoupledFactTable,
    FactTable,
)

shrdconn = shareconnectionwrapper(
    pygrametl.ConnectionWrapper(psycopg2.connect("dbname=dw user=dwuser"))
)

datedim = DecoupledDimension(
    CachedDimension(
        name="date", key="dateid", attributes=["day", "month", "year"],
        prefill=True, targetconnection=shrdconn.copy(),
    )
)
pagedim = DecoupledDimension(
    CachedDimension(
        name="page", key="pageid", attributes=["url", "domain"],
        lookupatts=["url"], targetconnection=shrdconn.copy(),
    )
)
facttbl = DecoupledFactTable(
    FactTable(
        name="testresults", keyrefs=["pageid", "dateid"],
        measures=["errors"], targetconnection=shrdconn.copy(),
    ),
    returnvalues=False,
    consumes=[datedim, pagedim],
)

source = ProcessSource(
    TransformingSource(CSVSource(open("results.csv", "r")), split_date)
)

for row in source:
    row["dateid"] = datedim.ensure(row)
    row["pageid"] = pagedim.ensure(row)
    facttbl.insert(row)

shrdconn.commit()
shrdconn.close()
``` <lst-pygrametl-mp>

This design enables both task and data parallelism, but it adds substantial coordination costs: batches of row dictionaries and surrogate keys must be serialized with `pickle` and transferred across IPC queues, and the main process or upstream workers can block when bounded queues fill while fact workers resolve `FutureResult` keys or flush rows to the database. The implementation also spends CPU time routing and updating partitioned page dimensions, packing and unpacking extracted-row batches, and serializing all database communication through a single connection server process. These costs motivate evaluating both alternatives to process-based workers and ways to reduce time spent waiting on the database.

== Jython <jython>

`pygrametl` also supports multithreading through Jython, an implementation of Python compiled to Java bytecode that executes on the Java Virtual Machine (JVM) @Thomsen2011Parallel. Unlike CPython, the JVM has no `@GIL` and schedules threads natively across multiple CPU cores while sharing a single heap address space. Consequently, parallel ETL workers in Jython can exchange row dictionaries, cached dimension entries, and surrogate keys directly by reference in shared memory without process-spawning overhead or `pickle` serialization.

To preserve a unified programming interface across CPython and Jython without requiring users to rewrite parallel ETL logic, `pygrametl` introduces two compatibility layers:

- *`jythonmultiprocessing`:* Because Jython lacks CPython's `multiprocessing` module, `pygrametl` bundles `jythonmultiprocessing`, which emulates the required subset of the `multiprocessing` API (`Process`, `Queue`, `JoinableQueue`, and `Value`) on top of Python's standard `threading` module (`Process` subclasses `threading.Thread`). When `pygrametl.parallel` is imported under Jython, it transparently binds to `jythonmultiprocessing`, turning `ProcessSource`, `DecoupledDimension`, `DecoupledFactTable`, `@splitpoint`, and `createflow` into multi-threaded abstractions @Thomsen2011Parallel.
- *`JDBCConnectionWrapper`:* Since Jython runs on the JVM and cannot load C-based PEP 249 database drivers such as `psycopg2`, `pygrametl` provides `JDBCConnectionWrapper` (alongside an experimental `BackgroundJDBCConnectionWrapper`) to wrap standard `java.sql.Connection` JDBC drivers. It exposes the same interface as `ConnectionWrapper`—including `pyformat` SQL translation and prepared-statement caching—and can be wrapped with `shareconnectionwrapper` so a dedicated database thread serializes access to a single JDBC connection across worker threads.

Despite avoiding `@GIL` contention and IPC serialization, running `pygrametl` on Jython entails notable operational and ecosystem limitations. On the runtime side, high-throughput JVM execution is sensitive to generational garbage collection: configuring large batch sizes (`Decoupled.batchsize`) or oversized caches can promote short-lived row dictionaries from the young generation into the tenured generation, triggering expensive garbage collection pauses, whereas overly small batches increase thread queue synchronization overhead. More fundamentally, Jython implements only Python 2.7, as a Python 3-compatible release (Jython 3) has never materialized. Because Python 2 reached end-of-life in 2020 and current `pygrametl` development targets Python 3—already dropping Jython support for newer modules such as `drawntabletesting` and phasing out Python 2 compatibility—Jython cannot leverage modern Python 3 syntax, active CPython database drivers (such as `psycopg` 3), or contemporary data-processing libraries.