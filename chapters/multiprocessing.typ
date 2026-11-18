== Multiprocessing
Standard CPython enforces a Global Interpreter Lock (GIL) @Python315GILDocs that serializes Python bytecode execution across threads. To bypass this, pygrametl relies on `multiprocessing` in CPython or with Jython @JythonProject, which runs on the Java Virtual Machine (JVM) without the GIL. However, Jython remains pinned to Python 2.7, whereas pygrametl targets Python 3 except for some Jython support.

Using `multiprocessing`, pygrametl spawns separate processes via `fork`, which utilizes copy-on-write semantics, though memory can still be duplicated later as processes modify their own state. 

To distribute work, dimensions and fact tables are wrapped in `Decoupled` objects, each running in its own process. Each `Decoupled` object sends batched method calls to its own process, by enqueuing them and immediately returning a `FutureResult` placeholder. When these placeholders are passed into a decoupled fact table, its process fetches the actual dimension keys from the dimension process before executing the insert.

Processes communicate by passing these batches over shared queues and synchronizing completion at the end. Because database connections cannot be shared directly across processes, `shareconnectionwrapper` routes all queries through a single database connection on the main process.

When running an ETL process with `multiprocessing`, a large portion of the time is spent inserting rows into the fact table because every batch of rows must be serialized and passed across queues.  The main process frequently has to wait when those queues fill up while the fact process resolves dimension keys and flushes bulk loads to the database. At the same time, significant overhead is spent looking up and updating the partitioned page dimensions, as well as unpacking incoming batches of extracted rows from a source process.
