== Multiprocessing
Standard CPython restricts true multi-threading via the Global Interpreter Lock (GIL) @Python315GILDocs. To execute tasks in parallel, pygrametl either runs on Jython @JythonProject (which lacks a GIL, though it is limited to Python 2.7) or uses `multiprocessing` in Python 3.

Using `multiprocessing`, pygrametl spawns separate processes via `fork`, allowing workers to inherit existing state without copying data upfront, though memory can still be duplicated later as processes modify their own state. 

To distribute work, dimensions and fact tables are wrapped in `Decoupled` objects, each running in its own process. Each `Decoupled` object sends batched method calls to its own process and immediately returning a `FutureResult` placeholder. When these placeholders are passed into a decoupled fact table, its process fetches the actual dimension keys from the dimension worker before executing the insert.

Processes communicate by passing these batches over shared queues and synchronizing completion at the end. Because database connections cannot be shared directly across processes, `shareconnectionwrapper` routes all queries through a single database, handling processes.