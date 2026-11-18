== Multiprocessing
Standard CPython restricts true multi-threading via the Global Interpreter Lock (GIL) @Python315GILDocs. To execute tasks in parallel, pygrametl either runs on Jython @JythonProject (which lacks a GIL, though it is limited to Python 2.7) or uses `multiprocessing` in Python 3.

Using `multiprocessing`, pygrametl spawns separate processes via `fork`, allowing processes to inherit existing state without copying data upfront, though memory can still be duplicated later as processes modify their own state. 

To distribute work, dimensions and fact tables are wrapped in `Decoupled` objects, each running in its own process. Each `Decoupled` object sends batched method calls to its own process and immediately returning a `FutureResult` placeholder. When these placeholders are passed into a decoupled fact table, its process fetches the actual dimension keys from the dimension process before executing the insert.

Processes communicate by passing these batches over shared queues and synchronizing completion at the end. Because database connections cannot be shared directly across processes, `shareconnectionwrapper` routes all queries through a single database, handling processes.

When running an ETL process with `multiprocessing`, a large portion of the time is spent inserting rows into the fact table because every batch of rows must be serialized and passed across process queues, and the main process frequently has to wait when those queues fill up while the fact process resolves dimension keys and flushes bulk loads to the database. At the same time, significant overhead is spent looking up and updating the partitioned page dimension across processes, as well as unpacking incoming batches of extracted rows from a source process.

/*
  extraction_merge     | Wall:  14.61s | Parent CPU:  15.24s
  transformation       | Wall:   6.03s | Parent CPU:   6.50s
  page_dimension       | Wall:  20.85s | Parent CPU:  21.60s
  date_dimension       | Wall:  11.67s | Parent CPU:  12.27s
  test_dimension       | Wall:  10.11s | Parent CPU:  10.68s
  fact_insert          | Wall:  68.66s | Parent CPU:  40.97s
*/